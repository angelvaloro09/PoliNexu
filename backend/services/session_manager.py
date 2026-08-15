"""Pool de sesiones SAES activas, identificadas por un `session_token` (UUID)
que el cliente Flutter recibe y reenvía en cada request subsecuente.

Persiste en SQLite (`SaesSessionRecord`) para sobrevivir reinicios del backend
y para que el worker de keep-alive (`services/keepalive.py`) pueda mantener
viva la Session de ASP.NET del SAES aunque la app esté cerrada; el estado
"vivo" (objeto `requests.Session`) se reconstruye en memoria a partir de las
cookies serializadas.
"""

import json
import uuid
from dataclasses import dataclass
from datetime import timedelta

import requests

from core.config import settings
from database.db import SessionLocal
from database.models import SaesSessionRecord, utcnow
from services.saes_scraper import AspNetTokens, new_scraper_session


@dataclass
class SaesSessionState:
    session_token: str
    school_id: str
    http_session: requests.Session
    tokens: AspNetTokens
    authenticated: bool = False
    account_id: str | None = None


def _dump_cookies(jar: requests.cookies.RequestsCookieJar) -> str:
    """Serializa el cookiejar completo.

    `requests.utils.dict_from_cookiejar` sólo conserva nombre→valor: al
    restaurar, la cookie queda sin dominio y se manda a cualquier host (y se
    pierden `path`, `expires` y `secure`). El SAES marca `ASP.NET_SessionId`
    como `secure; path=/`, así que se guarda entero.
    """
    return json.dumps(
        [
            {
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
                "expires": cookie.expires,
                "secure": cookie.secure,
            }
            for cookie in jar
        ]
    )


def _load_cookies(session: requests.Session, cookies_json: str) -> None:
    data = json.loads(cookies_json or "[]")

    # Formato viejo (dict plano de `dict_from_cookiejar`), por si quedan filas
    # de una base creada antes de este cambio.
    if isinstance(data, dict):
        session.cookies.update(requests.utils.cookiejar_from_dict(data))
        return

    for item in data:
        session.cookies.set_cookie(
            requests.cookies.create_cookie(
                name=item["name"],
                value=item["value"],
                domain=item.get("domain", ""),
                path=item.get("path", "/"),
                expires=item.get("expires"),
                secure=item.get("secure", False),
            )
        )


class SessionManager:
    """Gestiona sesiones HTTP activas de SAES por token de sesión."""

    def __init__(self) -> None:
        self._sessions: dict[str, SaesSessionState] = {}

    def create_session(self, school_id: str) -> SaesSessionState:
        token = str(uuid.uuid4())
        state = SaesSessionState(
            session_token=token,
            school_id=school_id,
            http_session=new_scraper_session(),
            tokens=AspNetTokens("", "", "", "", {}),
        )
        self._sessions[token] = state
        return state

    def get_session(self, token: str) -> SaesSessionState | None:
        state = self._sessions.get(token)
        if state is not None:
            return state
        return self._restore_from_db(token)

    def update_tokens(self, token: str, tokens: AspNetTokens) -> None:
        # `get_session` y no `self._sessions`: una sesión que sólo vive en
        # SQLite (backend reiniciado) debe rehidratarse, no perderse en
        # silencio.
        state = self.get_session(token)
        if state:
            state.tokens = tokens
            self._persist(state)

    def mark_authenticated(self, token: str, account_id: str | None = None) -> None:
        state = self.get_session(token)
        if state:
            state.authenticated = True
            if account_id is not None:
                state.account_id = account_id
            self._persist(state)

    def bind_account(self, token: str, account_id: str) -> None:
        state = self.get_session(token)
        if state:
            state.account_id = account_id
            self._persist(state)

    def touch(self, token: str) -> None:
        """Marca la sesión como usada ahora (mueve la ventana de purga)."""
        with SessionLocal() as db:
            record = db.get(SaesSessionRecord, token)
            if record:
                record.last_used_at = utcnow()
                db.commit()

    def mark_keepalive(self, token: str) -> None:
        with SessionLocal() as db:
            record = db.get(SaesSessionRecord, token)
            if record:
                record.keepalive_at = utcnow()
                db.commit()

    def destroy_session(self, token: str) -> None:
        self._sessions.pop(token, None)
        with SessionLocal() as db:
            record = db.get(SaesSessionRecord, token)
            if record:
                db.delete(record)
                db.commit()

    def list_live_tokens(self) -> list[str]:
        """Tokens autenticados y usados dentro de la ventana de inactividad.

        Es lo que el worker de keep-alive mantiene vivo. Devuelve tokens (no
        estados) para no rehidratar en memoria sesiones que quizá ya murieron.
        """
        cutoff = utcnow() - timedelta(days=settings.session_max_idle_days)
        with SessionLocal() as db:
            rows = (
                db.query(SaesSessionRecord.session_token)
                .filter(
                    SaesSessionRecord.authenticated.is_(True),
                    SaesSessionRecord.last_used_at >= cutoff,
                )
                .all()
            )
        return [row[0] for row in rows]

    def purge_stale(self) -> int:
        """Borra sesiones fuera de la ventana de inactividad. Devuelve cuántas."""
        cutoff = utcnow() - timedelta(days=settings.session_max_idle_days)
        with SessionLocal() as db:
            stale = (
                db.query(SaesSessionRecord)
                .filter(SaesSessionRecord.last_used_at < cutoff)
                .all()
            )
            for record in stale:
                self._sessions.pop(record.session_token, None)
                db.delete(record)
            db.commit()
            return len(stale)

    def _persist(self, state: SaesSessionState) -> None:
        cookies_json = _dump_cookies(state.http_session.cookies)
        with SessionLocal() as db:
            record = db.get(SaesSessionRecord, state.session_token)
            if record is None:
                record = SaesSessionRecord(session_token=state.session_token)
            record.school_id = state.school_id
            record.view_state = state.tokens.view_state
            record.view_state_generator = state.tokens.view_state_generator
            record.event_validation = state.tokens.event_validation
            record.captcha_url = state.tokens.captcha_url
            record.captcha_fields_json = json.dumps(state.tokens.captcha_fields)
            record.cookies_json = cookies_json
            record.authenticated = state.authenticated
            record.account_id = state.account_id
            record.last_used_at = utcnow()
            db.merge(record)
            db.commit()

    def _restore_from_db(self, token: str) -> SaesSessionState | None:
        with SessionLocal() as db:
            record = db.get(SaesSessionRecord, token)
            if record is None:
                return None

            http_session = new_scraper_session()
            _load_cookies(http_session, record.cookies_json)

            state = SaesSessionState(
                session_token=record.session_token,
                school_id=record.school_id,
                http_session=http_session,
                tokens=AspNetTokens(
                    record.view_state,
                    record.view_state_generator,
                    record.event_validation,
                    record.captcha_url,
                    json.loads(record.captcha_fields_json),
                ),
                authenticated=record.authenticated,
                account_id=record.account_id,
            )
            self._sessions[token] = state
            return state


session_manager = SessionManager()  # Singleton

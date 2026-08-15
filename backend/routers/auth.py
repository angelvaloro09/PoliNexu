import base64
import logging

from fastapi import APIRouter, HTTPException

from core.schools import get_school
from models.schemas import (
    CaptchaResponse,
    KeepAliveRequest,
    LoginRequest,
    LoginResponse,
    LogoutRequest,
    ReauthRequest,
    ReauthSessionRequest,
    SessionRequest,
    SessionStatusResponse,
)
from services import credentials_store, saes_scraper
from services.keepalive import ping_session
from services.session_manager import SaesSessionState, session_manager

logger = logging.getLogger(__name__)

router = APIRouter()


def _school_or_404(school_id: str) -> dict:
    school = get_school(school_id)
    if school is None:
        raise HTTPException(status_code=404, detail=f"Escuela desconocida: {school_id}")
    return school


def _session_or_401(session_token: str) -> SaesSessionState:
    state = session_manager.get_session(session_token)
    if state is None:
        raise HTTPException(status_code=401, detail="Sesión no encontrada o expirada.")
    return state


def _remember(state: SaesSessionState, boleta: str, password: str) -> str | None:
    """Guarda credenciales y ata la cuenta a la sesión. `None` si no se pudo.

    No es un error para el usuario: sin `credentials_key` el login funciona
    igual, sólo que el próximo re-login pedirá boleta y contraseña de nuevo.
    """
    try:
        account_id = credentials_store.save_account(state.school_id, boleta, password)
    except credentials_store.CredentialsUnavailableError as exc:
        logger.warning("No se recordaron las credenciales: %s", exc)
        return None

    session_manager.bind_account(state.session_token, account_id)
    return account_id


@router.post("/session", response_model=CaptchaResponse)
def create_session(body: SessionRequest) -> CaptchaResponse:
    school = _school_or_404(body.school_code)
    state = session_manager.create_session(body.school_code)

    try:
        tokens = saes_scraper.get_login_page(state.http_session, school["login_url"])
        session_manager.update_tokens(state.session_token, tokens)
        captcha_bytes = saes_scraper.get_captcha_bytes(
            state.http_session, school["base_url"], tokens
        )
    except saes_scraper.SaesScraperError as exc:
        session_manager.destroy_session(state.session_token)
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return CaptchaResponse(
        session_token=state.session_token,
        captcha_base64=base64.b64encode(captcha_bytes).decode("ascii"),
    )


@router.post("/reauth/session", response_model=CaptchaResponse)
def create_reauth_session(body: ReauthSessionRequest) -> CaptchaResponse:
    """Como `/auth/session`, pero la escuela sale de la cuenta guardada.

    Así el cliente no necesita recordar en qué plantel se logueó: le basta el
    `account_id` para pedir el CAPTCHA del re-login.
    """
    account = credentials_store.get_account(body.account_id)
    if account is None:
        raise HTTPException(
            status_code=404,
            detail="No hay credenciales guardadas para esta cuenta.",
        )
    return create_session(SessionRequest(school_code=account.school_id))


@router.get("/captcha", response_model=CaptchaResponse)
def reload_captcha(session_token: str) -> CaptchaResponse:
    state = _session_or_401(session_token)
    school = _school_or_404(state.school_id)

    try:
        # El par (c, t) del CAPTCHA es de un solo uso por carga de página:
        # hay que re-obtener la página de login completa para refrescarlo
        # (esto también renueva __VIEWSTATE / __EVENTVALIDATION, requeridos igual).
        tokens = saes_scraper.get_login_page(state.http_session, school["login_url"])
        session_manager.update_tokens(session_token, tokens)
        captcha_bytes = saes_scraper.get_captcha_bytes(
            state.http_session, school["base_url"], tokens
        )
    except saes_scraper.SaesScraperError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return CaptchaResponse(
        session_token=session_token,
        captcha_base64=base64.b64encode(captcha_bytes).decode("ascii"),
    )


@router.post("/login", response_model=LoginResponse)
def login(body: LoginRequest) -> LoginResponse:
    state = _session_or_401(body.session_token)
    school = _school_or_404(state.school_id)

    success, error_message = saes_scraper.login(
        state.http_session,
        school["login_url"],
        state.tokens,
        boleta=body.boleta,
        password=body.password,
        captcha=body.captcha_text,
    )

    if not success:
        return LoginResponse(success=False, message=error_message)

    account_id = _remember(state, body.boleta, body.password) if body.remember else None
    session_manager.mark_authenticated(body.session_token, account_id)
    return LoginResponse(success=True, account_id=account_id)


@router.post("/reauth", response_model=LoginResponse)
def reauth(body: ReauthRequest) -> LoginResponse:
    """Re-login usando las credenciales guardadas: el usuario sólo teclea el CAPTCHA."""
    state = _session_or_401(body.session_token)

    account = credentials_store.get_account(body.account_id)
    if account is None:
        raise HTTPException(
            status_code=404,
            detail="No hay credenciales guardadas para esta cuenta.",
        )

    school = _school_or_404(account.school_id)

    try:
        password = credentials_store.decrypt_password(account)
    except credentials_store.CredentialsUnavailableError as exc:
        # La cuenta quedó inservible (cambió la clave): que el cliente caiga al
        # login completo en vez de reintentar en bucle.
        credentials_store.delete_account(body.account_id)
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    success, error_message = saes_scraper.login(
        state.http_session,
        school["login_url"],
        state.tokens,
        boleta=account.boleta,
        password=password,
        captcha=body.captcha_text,
    )

    if not success:
        return LoginResponse(success=False, message=error_message, account_id=body.account_id)

    credentials_store.touch_account(body.account_id)
    session_manager.mark_authenticated(body.session_token, body.account_id)
    return LoginResponse(success=True, account_id=body.account_id)


@router.get("/status", response_model=SessionStatusResponse)
def session_status(session_token: str) -> SessionStatusResponse:
    """Comprueba contra el SAES si la sesión guardada sigue sirviendo.

    Es lo que la app llama al arrancar para decidir entre entrar directo,
    pedir sólo el CAPTCHA, o mandar al login completo. Nunca devuelve 401:
    el estado *es* la respuesta.
    """
    state = session_manager.get_session(session_token)
    if state is None:
        return SessionStatusResponse(valid=False, authenticated=False)

    if not state.authenticated:
        return SessionStatusResponse(valid=True, authenticated=False, account_id=state.account_id)

    try:
        alive = ping_session(state)
    except Exception as exc:  # noqa: BLE001 - red caída no es sesión inválida
        logger.warning("status: ping falló para %s: %s", session_token[:8], exc)
        raise HTTPException(status_code=502, detail="No se pudo contactar al SAES.") from exc

    if not alive:
        account_id = state.account_id
        session_manager.destroy_session(session_token)
        return SessionStatusResponse(valid=False, authenticated=False, account_id=account_id)

    session_manager.touch(session_token)
    return SessionStatusResponse(valid=True, authenticated=True, account_id=state.account_id)


@router.post("/keepalive", response_model=SessionStatusResponse)
def keep_alive(body: KeepAliveRequest) -> SessionStatusResponse:
    """Ping on-demand (la app lo llama al volver a primer plano)."""
    return session_status(body.session_token)


@router.post("/logout")
def logout(body: LogoutRequest) -> dict[str, bool]:
    session_manager.destroy_session(body.session_token)
    if body.account_id:
        credentials_store.delete_account(body.account_id)
    return {"success": True}

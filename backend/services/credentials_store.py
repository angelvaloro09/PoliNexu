"""Credenciales del SAES cifradas con Fernet (AES-128-CBC + HMAC).

Existen sólo para poder re-autenticar cuando el SAES mata la Session del lado
del servidor, sin que el usuario reescriba boleta y contraseña. El CAPTCHA
sigue siendo obligatorio en cada re-login (BotDetect guarda el texto en la
Session de ASP.NET; no hay forma de obtenerlo desde el cliente).

La clave vive en `settings.credentials_key` (archivo `.env`, fuera del repo).
Si está vacía, la función "recordar" queda deshabilitada de forma limpia: el
login normal sigue funcionando.
"""

import uuid

from cryptography.fernet import Fernet, InvalidToken

from core.config import settings
from database.db import SessionLocal
from database.models import SaesAccountRecord, utcnow


class CredentialsUnavailableError(RuntimeError):
    """No hay `credentials_key` configurada, o el dato guardado no se puede descifrar."""


def is_enabled() -> bool:
    return bool(settings.credentials_key)


def _fernet() -> Fernet:
    if not settings.credentials_key:
        raise CredentialsUnavailableError(
            "No hay credentials_key configurada; define una en .env para recordar credenciales."
        )
    try:
        return Fernet(settings.credentials_key.encode())
    except (ValueError, TypeError) as exc:
        raise CredentialsUnavailableError(f"credentials_key inválida: {exc}") from exc


def save_account(school_id: str, boleta: str, password: str) -> str:
    """Guarda (o actualiza) las credenciales y devuelve el `account_id`.

    Upsert por `school_id + boleta`: reloguearse con la misma cuenta reutiliza
    el `account_id` en vez de acumular filas.
    """
    token = _fernet().encrypt(password.encode()).decode()

    with SessionLocal() as db:
        record = (
            db.query(SaesAccountRecord)
            .filter(
                SaesAccountRecord.school_id == school_id,
                SaesAccountRecord.boleta == boleta,
            )
            .one_or_none()
        )
        if record is None:
            record = SaesAccountRecord(
                account_id=str(uuid.uuid4()),
                school_id=school_id,
                boleta=boleta,
            )
            db.add(record)
        record.password_enc = token
        record.last_login_at = utcnow()
        db.commit()
        return record.account_id


def get_account(account_id: str) -> SaesAccountRecord | None:
    with SessionLocal() as db:
        record = db.get(SaesAccountRecord, account_id)
        if record is None:
            return None
        db.expunge(record)
        return record


def decrypt_password(record: SaesAccountRecord) -> str:
    try:
        return _fernet().decrypt(record.password_enc.encode()).decode()
    except InvalidToken as exc:
        # Pasa si cambió la `credentials_key`: los datos viejos ya no se pueden
        # leer y la cuenta hay que rehacerla con un login normal.
        raise CredentialsUnavailableError(
            "No se pudieron descifrar las credenciales guardadas (¿cambió credentials_key?)."
        ) from exc


def touch_account(account_id: str) -> None:
    with SessionLocal() as db:
        record = db.get(SaesAccountRecord, account_id)
        if record:
            record.last_login_at = utcnow()
            db.commit()


def delete_account(account_id: str) -> None:
    with SessionLocal() as db:
        record = db.get(SaesAccountRecord, account_id)
        if record:
            db.delete(record)
            db.commit()

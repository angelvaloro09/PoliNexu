from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def utcnow() -> datetime:
    """UTC *naive*.

    SQLite no guarda offset: un `datetime` aware escrito con `DateTime` vuelve
    naive al leerlo, y comparar aware contra naive revienta con TypeError.
    Todo el backend usa naive-UTC para que las comparaciones sean homogéneas.
    """
    return datetime.now(timezone.utc).replace(tzinfo=None)


class SaesSessionRecord(Base):
    """Persiste una sesión SAES (tokens ASP.NET + cookies serializadas) para
    sobrevivir reinicios del backend (p.ej. `uvicorn --reload` durante desarrollo)
    y para que el worker de keep-alive pueda mantenerla viva.
    """

    __tablename__ = "saes_sessions"

    session_token: Mapped[str] = mapped_column(String(36), primary_key=True)
    school_id: Mapped[str] = mapped_column(String(32))
    view_state: Mapped[str] = mapped_column(Text)
    view_state_generator: Mapped[str] = mapped_column(Text)
    event_validation: Mapped[str] = mapped_column(Text)
    captcha_url: Mapped[str] = mapped_column(Text, default="")
    captcha_fields_json: Mapped[str] = mapped_column(Text, default="{}")
    cookies_json: Mapped[str] = mapped_column(Text, default="{}")
    authenticated: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    # Cuenta (credenciales cifradas) a la que pertenece esta sesión, si el
    # usuario pidió recordarla. Permite `/auth/reauth` sin reescribir password.
    account_id: Mapped[str | None] = mapped_column(String(36), nullable=True, default=None)
    # Último uso real desde la app; base de la ventana de purga/keep-alive.
    last_used_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    # Último ping exitoso del worker.
    keepalive_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True, default=None)


class SaesAccountRecord(Base):
    """Credenciales del SAES cifradas (Fernet) para poder re-autenticar cuando
    el SAES mata la sesión del lado del servidor.

    El cliente sólo guarda `account_id` (opaco); la contraseña nunca vuelve a
    salir del backend. El CAPTCHA sigue siendo obligatorio en cada re-login.
    """

    __tablename__ = "saes_accounts"

    account_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    school_id: Mapped[str] = mapped_column(String(32))
    boleta: Mapped[str] = mapped_column(String(32))
    password_enc: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    last_login_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

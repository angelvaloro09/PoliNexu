from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        # Sin esto, cualquier variable extra en el .env hace que pydantic lance
        # un ValidationError que **imprime el valor** en el traceback — es decir,
        # filtra secretos a los logs. Ignorarlas es lo correcto: el .env no es
        # exclusivo de este modelo.
        extra="ignore",
    )

    host: str = "0.0.0.0"
    port: int = 8000
    database_url: str = "sqlite:///./polinexu_backend.db"
    cors_origins: list[str] = ["*"]

    # Clave Fernet para cifrar las credenciales del SAES en `saes_accounts`.
    # Vacía = la función "recordar credenciales" queda deshabilitada (el login
    # sigue funcionando, sólo no se puede re-autenticar sin reescribir la
    # contraseña). Generar con:
    #   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
    credentials_key: str = ""

    # Cada cuánto el worker hace ping a las sesiones vivas para resetear el
    # sliding timeout de la Session de ASP.NET (default IIS: 20 min).
    keepalive_interval_seconds: int = 480

    # Sesiones sin uso por más de esto se purgan de la base y dejan de recibir
    # keep-alive.
    session_max_idle_days: int = 7


settings = Settings()

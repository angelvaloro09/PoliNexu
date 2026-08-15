from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from core.config import settings

database_url = settings.database_url
# Render's DATABASE_URL usa postgres:// o postgresql:// sin driver explícito;
# SQLAlchemy por defecto intenta psycopg2 (no instalado, usamos psycopg v3).
if database_url.startswith("postgres://"):
    database_url = database_url.replace("postgres://", "postgresql+psycopg://", 1)
elif database_url.startswith("postgresql://"):
    database_url = database_url.replace("postgresql://", "postgresql+psycopg://", 1)

connect_args = {}
if database_url.startswith("sqlite"):
    connect_args["check_same_thread"] = False

engine = create_engine(
    database_url,
    connect_args=connect_args,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


# Columnas agregadas después de la v0.1 del esquema. `create_all` sólo crea
# tablas nuevas — nunca altera una existente — y el proyecto no usa Alembic,
# así que las añadimos a mano sobre bases de datos ya creadas.
_ADDED_COLUMNS: dict[str, dict[str, str]] = {
    "saes_sessions": {
        "account_id": "VARCHAR(36)",
        "last_used_at": "DATETIME",
        "keepalive_at": "DATETIME",
    },
}


def ensure_schema() -> None:
    """Migración aditiva mínima: agrega columnas faltantes a tablas existentes.

    Idempotente. No borra ni renombra nada; para cambios destructivos hay que
    borrar `polinexu_backend.db` (es una base de desarrollo, se regenera sola).
    """
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    with engine.begin() as connection:
        for table, columns in _ADDED_COLUMNS.items():
            if table not in existing_tables:
                continue  # `create_all` ya la creó con el esquema completo
            present = {col["name"] for col in inspector.get_columns(table)}
            for name, sql_type in columns.items():
                if name not in present:
                    connection.execute(text(f"ALTER TABLE {table} ADD COLUMN {name} {sql_type}"))

        # Filas anteriores a la columna: sin esto quedan con `last_used_at`
        # NULL, y en SQL toda comparación con NULL es falsa — no entrarían
        # nunca ni al keep-alive ni a la purga, quedándose para siempre.
        if "saes_sessions" in existing_tables:
            connection.execute(
                text(
                    "UPDATE saes_sessions SET last_used_at = created_at "
                    "WHERE last_used_at IS NULL"
                )
            )

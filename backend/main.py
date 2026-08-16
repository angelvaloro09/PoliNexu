import asyncio
import logging
from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import settings
from core.schools import SCHOOLS
from database.db import Base, engine, ensure_schema
from models.schemas import SchoolOut
from routers import auth, calendar, saes
from services.keepalive import keepalive_worker

logging.basicConfig(level=logging.INFO)

Base.metadata.create_all(bind=engine)
ensure_schema()


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    worker = asyncio.create_task(keepalive_worker())
    try:
        yield
    finally:
        worker.cancel()
        try:
            await worker
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title="PoliNexu Backend",
    description="SAES scraper API para la app PoliNexu",
    version="0.2.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    # El token viaja en el body/query, nunca en cookies: no hacen falta
    # credenciales cross-origin (y `allow_credentials=True` con
    # `allow_origins=["*"]` es una combinación que el navegador rechaza).
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(saes.router, prefix="/saes", tags=["SAES"])
app.include_router(calendar.router, prefix="/calendar", tags=["Calendar"])


@app.get("/schools", response_model=list[SchoolOut], tags=["Schools"])
def list_schools() -> list[SchoolOut]:
    return [
        SchoolOut(id=s["id"], display_name=s["display_name"], full_name=s["full_name"])
        for s in SCHOOLS.values()
    ]


@app.get("/health", tags=["Health"])
def health() -> dict[str, str]:
    return {"status": "ok"}

"""Mantiene vivas las sesiones del SAES.

El SAES autentica con la Session de ASP.NET (`ASP.NET_SessionId`) y *sliding
timeout* — no hay cookie de forms-auth persistente ni checkbox "Recordarme"
(verificado contra el login real). Si nadie la toca, muere sola en ~20 min.
Un GET periódico a cualquier página autenticada resetea ese contador.

Esto no es infalible: un reciclado del app pool de IIS tira las Sessions InProc
sin importar la actividad. Para eso está `/auth/reauth` (credenciales cifradas
+ CAPTCHA).
"""

import asyncio
import logging

import requests

from core.config import settings
from core.saes_pages import KEEPALIVE_PATH
from core.schools import get_school
from services.saes_scraper import decode_html
from services.session_manager import SaesSessionState, session_manager

logger = logging.getLogger(__name__)


def ping_session(state: SaesSessionState) -> bool:
    """Golpea una página autenticada. `True` si la sesión sigue viva.

    Sin seguir redirects: el SAES contesta 302 hacia `Default.aspx?ReturnUrl=`
    cuando la sesión ya expiró, lo cual es una señal más barata y menos
    ambigua que dejar que el redirect se resuelva y olfatear el HTML del login.
    """
    school = get_school(state.school_id)
    if school is None:
        return False

    response = state.http_session.get(
        f"{school['base_url']}{KEEPALIVE_PATH}",
        timeout=15,
        allow_redirects=False,
    )

    if response.status_code in (301, 302, 303, 307, 308):
        return False
    if response.status_code >= 400:
        # Un 5xx del SAES no significa que la sesión murió; no la matamos por
        # eso, sólo reportamos el ping como fallido.
        return False

    # Cinturón y tirantes: algunos planteles re-renderizan el login con 200 en
    # vez de redirigir.
    return "CaptchaCodeTextBox" not in decode_html(response)


def sweep_once() -> tuple[int, int]:
    """Un barrido completo: purga lo viejo y hace ping a lo vivo.

    Devuelve `(pings_ok, sesiones_muertas)`.
    """
    purged = session_manager.purge_stale()
    if purged:
        logger.info("keepalive: %d sesiones purgadas por inactividad", purged)

    alive = 0
    dead = 0

    for token in session_manager.list_live_tokens():
        state = session_manager.get_session(token)
        if state is None:
            continue
        try:
            if ping_session(state):
                session_manager.mark_keepalive(token)
                alive += 1
            else:
                logger.info("keepalive: sesión %s expiró en el SAES, se destruye", token[:8])
                session_manager.destroy_session(token)
                dead += 1
        except requests.RequestException as exc:
            # Red caída / SAES en mantenimiento: se reintenta al siguiente
            # barrido. Nunca dejar que un fallo tumbe el worker entero.
            logger.warning("keepalive: ping falló para %s: %s", token[:8], exc)

    return alive, dead


async def keepalive_worker() -> None:
    """Bucle de fondo; se arranca desde el `lifespan` de FastAPI."""
    interval = settings.keepalive_interval_seconds
    logger.info("keepalive: worker iniciado (cada %ds)", interval)

    while True:
        try:
            # `requests` es síncrono: fuera del event loop para no bloquearlo.
            alive, dead = await asyncio.to_thread(sweep_once)
            if alive or dead:
                logger.info("keepalive: %d vivas, %d expiradas", alive, dead)
        except asyncio.CancelledError:
            logger.info("keepalive: worker detenido")
            raise
        except Exception:  # noqa: BLE001 - el worker no debe morir nunca
            logger.exception("keepalive: barrido falló")

        await asyncio.sleep(interval)

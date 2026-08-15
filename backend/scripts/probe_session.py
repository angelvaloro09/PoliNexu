"""Sonda manual del SAES: mide cuánto vive realmente una sesión y confirma
qué ruta sirve de ping barato para el keep-alive.

No forma parte del servidor. Correr una vez para calibrar
`keepalive_interval_seconds` y `KEEPALIVE_PATH`.

Credenciales desde `backend/.env.probe` (NO commitear), nunca por línea de
comandos. Archivo aparte del `.env` del servidor a propósito: el `.env` lo lee
`core.config.Settings`, y una variable que ese modelo no conoce puede acabar
impresa en un traceback de pydantic.

    PROBE_SCHOOL=upiicsa
    PROBE_BOLETA=2023xxxxxx
    PROBE_PASSWORD=...

Uso (desde `backend/`, con el venv activo):

    python scripts/probe_session.py                    # interactivo
    python scripts/probe_session.py --watch            # + mide el timeout real

Para entornos sin terminal interactiva, en dos pasos (la sesión HTTP se
serializa entre ambos: cookies y tokens ASP.NET deben ser los mismos, y la
imagen del CAPTCHA sólo se puede pedir UNA vez por carga de página):

    python scripts/probe_session.py start              # guarda captcha.png
    python scripts/probe_session.py finish --captcha ABC123 [--watch]
"""

import argparse
import os
import pickle
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv  # noqa: E402

from core.saes_pages import GRADES_PATH, KEEPALIVE_PATH, SCHEDULE_PATH  # noqa: E402
from core.schools import get_school  # noqa: E402
from services import saes_scraper  # noqa: E402

PROBE_ENV_FILE = Path(__file__).resolve().parent.parent / ".env.probe"

CAPTCHA_FILE = Path(__file__).parent / "captcha.png"
STATE_FILE = Path(__file__).parent / "probe_state.pickle"
AUTH_STATE_FILE = Path(__file__).parent / "probe_state_auth.pickle"


def _load_school():
    if not PROBE_ENV_FILE.exists():
        print(f"Falta {PROBE_ENV_FILE} (ver .env.probe.example).")
        return None
    load_dotenv(PROBE_ENV_FILE)
    school_code = os.getenv("PROBE_SCHOOL", "")
    school = get_school(school_code)
    if school is None:
        print(f"Escuela desconocida o vacía: {school_code!r}")
        return None
    return school


def _fetch_login_page(school: dict):
    """Página de login + CAPTCHA. Devuelve `(session, tokens)`."""
    session = saes_scraper.new_scraper_session()
    tokens = saes_scraper.get_login_page(session, school["login_url"])

    # Ojo: la imagen se pide UNA sola vez por carga de página. Dos GET al mismo
    # `?get=image&c=..&t=..` devuelven códigos distintos, así que re-pedirla
    # invalidaría el que se esté tecleando.
    CAPTCHA_FILE.write_bytes(
        saes_scraper.get_captcha_bytes(session, school["base_url"], tokens)
    )
    return session, tokens


def _do_login(session, tokens, school: dict, captcha: str):
    boleta = os.getenv("PROBE_BOLETA", "")
    password = os.getenv("PROBE_PASSWORD", "")
    if not (boleta and password):
        print("Faltan PROBE_BOLETA / PROBE_PASSWORD en .env")
        return False

    success, error = saes_scraper.login(
        session,
        school["login_url"],
        tokens,
        boleta=boleta,
        password=password,
        captcha=captcha,
    )
    if not success:
        print(f"Login falló: {error}")
        return False
    print("Login OK.")
    return True


def _report_cookies(session) -> None:
    print("\n--- Cookies post-login ---")
    for cookie in session.cookies:
        flags = []
        if cookie.secure:
            flags.append("secure")
        if cookie.expires:
            flags.append(f"expires={cookie.expires}")
        print(f"  {cookie.name:32} domain={cookie.domain} path={cookie.path} {' '.join(flags)}")
    names = {c.name for c in session.cookies}
    # Si apareciera una cookie de forms-auth persistente, el keep-alive sobra.
    forms_auth = {n for n in names if "ASPXAUTH" in n.upper() or "FORMSAUTH" in n.upper()}
    print(f"  -> forms-auth persistente: {forms_auth or 'NO (auth por Session, hace falta keep-alive)'}")


def _report_paths(session, school: dict) -> None:
    print("\n--- Costo de cada ruta como ping ---")
    for path in (KEEPALIVE_PATH, SCHEDULE_PATH, GRADES_PATH):
        started = time.monotonic()
        try:
            response = session.get(
                f"{school['base_url']}{path}", timeout=15, allow_redirects=False
            )
        except Exception as exc:  # noqa: BLE001
            print(f"  {path:60} ERROR {exc}")
            continue
        elapsed = (time.monotonic() - started) * 1000
        print(
            f"  {path:60} HTTP {response.status_code} "
            f"{len(response.content):7d}b {elapsed:6.0f}ms"
        )


def _watch(session, school: dict, step_minutes: int, limit_minutes: int) -> None:
    """Deja la sesión quieta y golpea cada `step_minutes` hasta que muera."""
    from services.keepalive import ping_session
    from services.saes_scraper import AspNetTokens
    from services.session_manager import SaesSessionState

    state = SaesSessionState("probe", school["id"], session, AspNetTokens("", "", "", "", {}), True)

    print(f"\n--- Midiendo timeout (ping cada {step_minutes} min, máx {limit_minutes} min) ---")
    print("Sin keep-alive intermedio: el primer FALLO marca la ventana real.")
    elapsed = 0
    while elapsed < limit_minutes:
        time.sleep(step_minutes * 60)
        elapsed += step_minutes
        alive = ping_session(state)
        print(f"  t+{elapsed:3d} min: {'viva' if alive else 'MUERTA'}", flush=True)
        if not alive:
            print(f"  -> la sesión murió entre t+{elapsed - step_minutes} y t+{elapsed} min")
            return
    print(f"  -> seguía viva a los {limit_minutes} min")


def _report(session, school: dict, args) -> int:
    # Se guarda la sesión ya autenticada para poder seguir midiendo en
    # invocaciones posteriores (p. ej. el `--watch` largo en segundo plano)
    # sin gastar otro CAPTCHA.
    AUTH_STATE_FILE.write_bytes(pickle.dumps(session))
    _report_cookies(session)
    _report_paths(session, school)
    if args.watch:
        _watch(session, school, args.step, args.limit)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "mode",
        nargs="?",
        default="all",
        choices=["all", "start", "finish", "watch", "paths"],
        help="'all' = interactivo; 'start'/'finish' = dos pasos sin terminal interactiva",
    )
    parser.add_argument("--captcha", help="código del CAPTCHA (modo finish)")
    parser.add_argument("--watch", action="store_true", help="medir el timeout real")
    parser.add_argument("--step", type=int, default=5, help="minutos entre pings (--watch)")
    parser.add_argument("--limit", type=int, default=60, help="minutos máximos (--watch)")
    parser.add_argument("--paths", nargs="*", help="rutas a medir (modo paths)")
    args = parser.parse_args()

    school = _load_school()
    if school is None:
        return 1

    if args.mode in ("watch", "paths"):
        if not AUTH_STATE_FILE.exists():
            print(f"No hay sesión autenticada guardada ({AUTH_STATE_FILE}).")
            return 1
        session = pickle.loads(AUTH_STATE_FILE.read_bytes())
        if args.mode == "watch":
            _watch(session, school, args.step, args.limit)
        else:
            for path in args.paths or []:
                started = time.monotonic()
                response = session.get(
                    f"{school['base_url']}{path}", timeout=15, allow_redirects=False
                )
                elapsed = (time.monotonic() - started) * 1000
                print(
                    f"  {path:60} HTTP {response.status_code} "
                    f"{len(response.content):7d}b {elapsed:6.0f}ms"
                )
        return 0

    if args.mode == "finish":
        if not args.captcha:
            print("Falta --captcha")
            return 1
        if not STATE_FILE.exists():
            print(f"No hay estado guardado ({STATE_FILE}); corre primero el modo 'start'.")
            return 1
        session, tokens = pickle.loads(STATE_FILE.read_bytes())
        STATE_FILE.unlink()
        if not _do_login(session, tokens, school, args.captcha):
            return 1
        return _report(session, school, args)

    session, tokens = _fetch_login_page(school)

    if args.mode == "start":
        STATE_FILE.write_bytes(pickle.dumps((session, tokens)))
        print(f"CAPTCHA en {CAPTCHA_FILE}")
        print(f"Ahora: python scripts/probe_session.py finish --captcha <CODIGO>")
        return 0

    print(f"CAPTCHA guardado en {CAPTCHA_FILE} — ábrelo y teclea el código.")
    captcha = input("CAPTCHA: ").strip()
    if not _do_login(session, tokens, school, captcha):
        return 1
    return _report(session, school, args)


if __name__ == "__main__":
    raise SystemExit(main())

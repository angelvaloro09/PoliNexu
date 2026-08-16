import requests
from fastapi import APIRouter, HTTPException

from core.saes_pages import (
    ACADEMIC_STATUS_PATH,
    GRADES_PATH,
    KARDEX_PATH,
    REINSCRIPTION_PATH,
    SCHEDULE_PATH,
)
from core.schools import get_school
from models.schemas import (
    AcademicStatusResponse,
    GradesResponse,
    KardexResponse,
    ReinscriptionResponse,
    ScheduleResponse,
)
from services.parsers.academic_status_parser import parse_academic_status
from services.parsers.grades_parser import parse_grades
from services.parsers.horario_parser import parse_schedule
from services.parsers.kardex_parser import parse_kardex
from services.parsers.reinscription_parser import parse_reinscription
from services.saes_scraper import decode_html
from services.session_manager import SaesSessionState, session_manager

router = APIRouter()


def _authenticated_state(session_token: str) -> tuple[SaesSessionState, dict]:
    state = session_manager.get_session(session_token)
    if state is None:
        raise HTTPException(status_code=401, detail="Sesión no encontrada o expirada.")
    if not state.authenticated:
        raise HTTPException(status_code=401, detail="Sesión no autenticada. Inicia sesión primero.")

    school = get_school(state.school_id)
    if school is None:
        raise HTTPException(status_code=404, detail=f"Escuela desconocida: {state.school_id}")

    # Mueve la ventana de inactividad: mientras la app se use, el worker de
    # keep-alive sigue manteniendo esta sesión viva.
    session_manager.touch(session_token)

    return state, school


def _fetch_authenticated_page(state: SaesSessionState, school: dict, path: str, session_token: str) -> str:
    try:
        response = state.http_session.get(f"{school['base_url']}{path}", timeout=15)
        response.raise_for_status()
    except requests.RequestException as exc:
        # Fallo de red o error del SAES: es un problema del upstream, no del
        # backend — 502, no el 500 crudo que salía antes.
        raise HTTPException(status_code=502, detail=f"El SAES no respondió: {exc}") from exc

    html = decode_html(response)

    # Si el SAES redirige a login (sesión expirada del lado del servidor), la
    # página trae de vuelta el formulario de login en vez del contenido pedido.
    if "CaptchaCodeTextBox" in html:
        session_manager.destroy_session(session_token)
        raise HTTPException(
            status_code=401,
            detail="La sesión expiró en el SAES. Inicia sesión de nuevo.",
        )

    return html


@router.get("/schedule", response_model=ScheduleResponse)
def get_schedule(session_token: str) -> ScheduleResponse:
    state, school = _authenticated_state(session_token)
    html = _fetch_authenticated_page(state, school, SCHEDULE_PATH, session_token)
    return ScheduleResponse(entries=parse_schedule(html))


@router.get("/grades", response_model=GradesResponse)
def get_grades(session_token: str) -> GradesResponse:
    state, school = _authenticated_state(session_token)
    html = _fetch_authenticated_page(state, school, GRADES_PATH, session_token)
    return GradesResponse(entries=parse_grades(html))


@router.get("/kardex", response_model=KardexResponse)
def get_kardex(session_token: str) -> KardexResponse:
    state, school = _authenticated_state(session_token)
    html = _fetch_authenticated_page(state, school, KARDEX_PATH, session_token)
    return KardexResponse(**parse_kardex(html))


@router.get("/academic-status", response_model=AcademicStatusResponse)
def get_academic_status(session_token: str) -> AcademicStatusResponse:
    state, school = _authenticated_state(session_token)
    html = _fetch_authenticated_page(state, school, ACADEMIC_STATUS_PATH, session_token)
    return AcademicStatusResponse(**parse_academic_status(html))


@router.get("/reinscription", response_model=ReinscriptionResponse)
def get_reinscription(session_token: str) -> ReinscriptionResponse:
    state, school = _authenticated_state(session_token)
    html = _fetch_authenticated_page(state, school, REINSCRIPTION_PATH, session_token)
    return ReinscriptionResponse(**parse_reinscription(html))

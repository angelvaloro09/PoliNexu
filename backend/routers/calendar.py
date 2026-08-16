from fastapi import APIRouter

from core.academic_calendar import ACADEMIC_CALENDAR_EVENTS
from models.schemas import AcademicCalendarResponse

router = APIRouter()


@router.get("/ipn", response_model=AcademicCalendarResponse)
def get_ipn_calendar() -> AcademicCalendarResponse:
    """Calendario académico institucional del IPN. Dato público, sin sesión."""
    return AcademicCalendarResponse(events=ACADEMIC_CALENDAR_EVENTS)

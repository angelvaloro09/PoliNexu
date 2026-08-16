"""Calendario académico IPN, modalidad escolarizada, ciclo 2026-2027.

Fuente: https://www.ipn.mx/assets/files/website/docs/inicio/calendarioipn-escolarizada.pdf
Transcrito a mano el 2026-08-15 (el PDF es un calendario visual de celdas
coloreadas, sin tabla de texto estructurada — no hay forma confiable de
parsearlo automáticamente, ver CLAUDE.md). Verificado contra el PDF oficial:
inicio/fin de semestre, vacaciones de invierno y Semana Santa, Día del
Politécnico.

Sólo se incluyen categorías relevantes para alumnos de nivel superior
(se excluyen inducción/nivelación NMS y fechas específicas de posgrado).

**Actualizar cada ciclo escolar** cuando el IPN publique el nuevo calendario.
"""

from datetime import date

from models.schemas import AcademicCalendarEvent

ACADEMIC_CALENDAR_EVENTS: list[AcademicCalendarEvent] = [
    # --- Semestre 2026-2027/1 (agosto-diciembre 2026) ---
    AcademicCalendarEvent(
        id="2026-08-inscripcion-1",
        title="Inscripción y reinscripción",
        category="inscripcion_reinscripcion",
        start_date=date(2026, 8, 17),
        end_date=date(2026, 8, 21),
    ),
    AcademicCalendarEvent(
        id="2026-08-inicio-periodo",
        title="Inicio del periodo escolar",
        category="inicio_periodo",
        start_date=date(2026, 8, 24),
        end_date=date(2026, 8, 24),
    ),
    AcademicCalendarEvent(
        id="2026-09-descanso-independencia",
        title="Día de descanso obligatorio",
        category="descanso_obligatorio",
        start_date=date(2026, 9, 16),
        end_date=date(2026, 9, 16),
    ),
    AcademicCalendarEvent(
        id="2026-09-evaluacion-ordinaria-1",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2026, 9, 28),
        end_date=date(2026, 9, 30),
    ),
    AcademicCalendarEvent(
        id="2026-11-evaluacion-ordinaria-2",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2026, 11, 5),
        end_date=date(2026, 11, 6),
    ),
    AcademicCalendarEvent(
        id="2026-11-evaluacion-ordinaria-3",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2026, 11, 9),
        end_date=date(2026, 11, 9),
    ),
    AcademicCalendarEvent(
        id="2026-11-descanso-revolucion",
        title="Día de descanso obligatorio",
        category="descanso_obligatorio",
        start_date=date(2026, 11, 16),
        end_date=date(2026, 11, 16),
    ),
    AcademicCalendarEvent(
        id="2026-12-evaluacion-ordinaria-4",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2026, 12, 11),
        end_date=date(2026, 12, 11),
    ),
    AcademicCalendarEvent(
        id="2026-12-evaluacion-ordinaria-5",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2026, 12, 14),
        end_date=date(2026, 12, 15),
    ),
    AcademicCalendarEvent(
        id="2026-12-evaluacion-extraordinaria-1",
        title="Registro de evaluación extraordinaria",
        category="evaluacion_extraordinaria",
        start_date=date(2026, 12, 16),
        end_date=date(2026, 12, 17),
    ),
    AcademicCalendarEvent(
        id="2026-12-fin-periodo",
        title="Fin del periodo escolar",
        category="fin_periodo",
        start_date=date(2026, 12, 18),
        end_date=date(2026, 12, 18),
    ),
    AcademicCalendarEvent(
        id="2026-12-descanso-navidad",
        title="Día de descanso obligatorio",
        category="descanso_obligatorio",
        start_date=date(2026, 12, 25),
        end_date=date(2026, 12, 25),
    ),
    AcademicCalendarEvent(
        id="2026-2027-vacaciones-invierno",
        title="Vacaciones de invierno",
        category="vacaciones",
        start_date=date(2026, 12, 27),
        end_date=date(2027, 1, 2),
    ),
    # --- Semestre 2026-2027/2 (enero-junio 2027) ---
    AcademicCalendarEvent(
        id="2027-01-descanso-anio-nuevo",
        title="Día de descanso obligatorio",
        category="descanso_obligatorio",
        start_date=date(2027, 1, 1),
        end_date=date(2027, 1, 1),
    ),
    AcademicCalendarEvent(
        id="2027-01-inscripcion-2",
        title="Inscripción y reinscripción",
        category="inscripcion_reinscripcion",
        start_date=date(2027, 1, 18),
        end_date=date(2027, 1, 21),
    ),
    AcademicCalendarEvent(
        id="2027-01-inicio-periodo",
        title="Inicio del periodo escolar",
        category="inicio_periodo",
        start_date=date(2027, 1, 25),
        end_date=date(2027, 1, 25),
    ),
    AcademicCalendarEvent(
        id="2027-02-descanso-constitucion",
        title="Día de descanso obligatorio",
        category="descanso_obligatorio",
        start_date=date(2027, 2, 1),
        end_date=date(2027, 2, 1),
    ),
    AcademicCalendarEvent(
        id="2027-03-evaluacion-ordinaria-6",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2027, 3, 4),
        end_date=date(2027, 3, 4),
    ),
    AcademicCalendarEvent(
        id="2027-03-dia-politecnico",
        title="Celebración del Día del Politécnico",
        category="dia_politecnico",
        start_date=date(2027, 3, 5),
        end_date=date(2027, 3, 5),
    ),
    AcademicCalendarEvent(
        id="2027-03-evaluacion-ordinaria-7",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2027, 3, 8),
        end_date=date(2027, 3, 8),
    ),
    AcademicCalendarEvent(
        id="2027-03-descanso-juarez",
        title="Día de descanso obligatorio",
        category="descanso_obligatorio",
        start_date=date(2027, 3, 15),
        end_date=date(2027, 3, 15),
    ),
    AcademicCalendarEvent(
        id="2027-vacaciones-semana-santa",
        title="Vacaciones de Semana Santa",
        category="vacaciones",
        start_date=date(2027, 3, 21),
        end_date=date(2027, 4, 2),
    ),
    AcademicCalendarEvent(
        id="2027-04-evaluacion-ordinaria-8",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2027, 4, 30),
        end_date=date(2027, 4, 30),
    ),
    AcademicCalendarEvent(
        id="2027-05-descanso-trabajo",
        title="Día de descanso obligatorio",
        category="descanso_obligatorio",
        start_date=date(2027, 5, 1),
        end_date=date(2027, 5, 1),
    ),
    AcademicCalendarEvent(
        id="2027-05-evaluacion-ordinaria-9",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2027, 5, 2),
        end_date=date(2027, 5, 3),
    ),
    AcademicCalendarEvent(
        id="2027-06-evaluacion-ordinaria-10",
        title="Registro de evaluación ordinaria",
        category="evaluacion_ordinaria",
        start_date=date(2027, 6, 15),
        end_date=date(2027, 6, 17),
    ),
    AcademicCalendarEvent(
        id="2027-06-evaluacion-extraordinaria-2",
        title="Registro de evaluación extraordinaria",
        category="evaluacion_extraordinaria",
        start_date=date(2027, 6, 18),
        end_date=date(2027, 6, 18),
    ),
    # --- Vacaciones intersemestrales y arranque del ciclo 2027-2028 ---
    AcademicCalendarEvent(
        id="2027-vacaciones-verano",
        title="Vacaciones intersemestrales",
        category="vacaciones",
        start_date=date(2027, 7, 25),
        end_date=date(2027, 8, 8),
    ),
    AcademicCalendarEvent(
        id="2027-08-inscripcion-1",
        title="Inscripción y reinscripción",
        category="inscripcion_reinscripcion",
        start_date=date(2027, 8, 9),
        end_date=date(2027, 8, 13),
    ),
    AcademicCalendarEvent(
        id="2027-08-inicio-periodo",
        title="Inicio del periodo escolar",
        category="inicio_periodo",
        start_date=date(2027, 8, 16),
        end_date=date(2027, 8, 16),
    ),
]

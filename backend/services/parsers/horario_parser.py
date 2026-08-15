"""Parser de la página de Horario
(`/Alumnos/Informacion_semestral/Horario_Alumno.aspx`).

Tabla GridView `ctl00_mainCopy_GV_Horario`: fila de encabezado + una fila por
materia inscrita, con columnas Grupo/Materia/Profesores/Lunes..Viernes. Cada
celda de día contiene, cuando hay clase, dos líneas de texto separadas por
`<br>`: "HH:MM - HH:MM" y "Edif: X - Salón: Y" (vacía si no hay clase ese día).
"""

from bs4 import BeautifulSoup

_DAYS = ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes"]
_DAY_LABELS = {
    "Lunes": "Lunes",
    "Martes": "Martes",
    "Miercoles": "Miércoles",
    "Jueves": "Jueves",
    "Viernes": "Viernes",
}


def _parse_day_cell(cell) -> dict | None:
    parts = list(cell.stripped_strings)
    if not parts:
        return None

    start_time, _, end_time = parts[0].partition(" - ")

    building = None
    classroom = None
    if len(parts) > 1:
        loc_building, _, loc_classroom = parts[1].partition(" - ")
        building = loc_building.replace("Edif:", "").strip() or None
        classroom = loc_classroom.replace("Salón:", "").strip() or None

    return {
        "start_time": start_time.strip(),
        "end_time": end_time.strip(),
        "building": building,
        "classroom": classroom,
    }


def parse_schedule(html: str) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    table = soup.find("table", id="ctl00_mainCopy_GV_Horario")
    if table is None:
        return []

    entries = []
    for row in table.find_all("tr")[1:]:  # la primera fila es el encabezado
        cells = row.find_all("td")
        if len(cells) < 8:
            continue

        sessions = []
        for day, cell in zip(_DAYS, cells[3:8]):
            parsed = _parse_day_cell(cell)
            if parsed is not None:
                sessions.append({"day": _DAY_LABELS[day], **parsed})

        entries.append(
            {
                "group": cells[0].get_text(strip=True),
                "subject": cells[1].get_text(strip=True),
                "teachers": cells[2].get_text(strip=True),
                "sessions": sessions,
            }
        )

    return entries

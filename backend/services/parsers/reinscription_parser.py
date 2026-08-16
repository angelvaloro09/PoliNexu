"""Parser de la página de Cita de Reinscripción
(`/Alumnos/Reinscripciones/fichas_reinscripcion.aspx`).

Cuatro tablas sueltas sin `id` de GridView: la de la cita (identificada por su
propio encabezado de columna, no hay texto libre antes), dos bajo un
encabezado de texto ("INFORMACION SOBRE TU CARRERA",
"INFORMACION SOBRE TU TRAYECTORIA ESCOLAR EN CREDITOS"), y la de créditos de
reprobadas al final (identificada por su encabezado "Descripción"/"creditos").
Confirmar contra HTML real al desplegar, como el resto de parsers de páginas
sin id.
"""

import re
from datetime import datetime

from bs4 import BeautifulSoup

# "12/08/2026 09:20:00 a. m." / "03:20:00 p. m." — sin depender del locale del
# sistema para %p, que en Windows/es-MX no siempre reconoce "a. m."/"p. m.".
_DATETIME_RE = re.compile(
    r"(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s*([ap])\.?\s*\.?\s*m\.?",
    re.IGNORECASE,
)


def _parse_saes_datetime(text: str) -> datetime | None:
    match = _DATETIME_RE.search(text)
    if match is None:
        return None
    day, month, year, hour, minute, second, meridiem = match.groups()
    hour_value = int(hour) % 12
    if meridiem.lower() == "p":
        hour_value += 12
    return datetime(int(year), int(month), int(day), hour_value, int(minute), int(second))


def _table_with_header(soup: BeautifulSoup, header_text: str):
    for table in soup.find_all("table"):
        first_row = table.find("tr")
        if first_row and header_text.lower() in first_row.get_text(" ", strip=True).lower():
            return table
    return None


def _table_after_heading(soup: BeautifulSoup, heading: str):
    marker = soup.find(string=re.compile(heading, re.IGNORECASE))
    if marker is None:
        return None
    return marker.find_next("table")


def _breakdown_table(soup: BeautifulSoup):
    """La tabla final de créditos de reprobadas: dos columnas,
    "Descripción"/"creditos" — a diferencia de las tablas de arriba (que
    también mencionan "creditos" en su encabezado pero tienen más columnas).
    """
    for table in soup.find_all("table"):
        first_row = table.find("tr")
        if first_row is None:
            continue
        headers = first_row.find_all(["td", "th"])
        if len(headers) != 2:
            continue
        first_text = headers[0].get_text(strip=True).lower()
        second_text = headers[1].get_text(strip=True).lower()
        if "descrip" in first_text and "credito" in second_text:
            return table
    return None


def _first_data_row(table) -> list[str]:
    if table is None:
        return []
    rows = table.find_all("tr")
    if len(rows) < 2:
        return []
    return [cell.get_text(strip=True) for cell in rows[1].find_all("td")]


def parse_reinscription(html: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")

    appointment_row = _first_data_row(_table_with_header(soup, "Fecha de Caducidad"))
    average = appointment_row[0] if len(appointment_row) > 0 else ""
    failed_subjects_count = appointment_row[1] if len(appointment_row) > 1 else "0"
    appointment_start = _parse_saes_datetime(appointment_row[2]) if len(appointment_row) > 2 else None
    appointment_end = _parse_saes_datetime(appointment_row[3]) if len(appointment_row) > 3 else None

    career_row = _first_data_row(_table_after_heading(soup, "INFORMACION SOBRE TU CARRERA"))

    trajectory_row = _first_data_row(
        _table_after_heading(soup, "INFORMACION SOBRE TU TRAYECTORIA ESCOLAR EN CREDITOS")
    )

    breakdown = []
    breakdown_table = _breakdown_table(soup)
    if breakdown_table is not None:
        for row in breakdown_table.find_all("tr")[1:]:
            cells = row.find_all("td")
            if len(cells) < 2:
                continue
            breakdown.append(
                {
                    "description": cells[0].get_text(strip=True),
                    "credits": cells[1].get_text(strip=True),
                }
            )

    def _at(row: list[str], index: int) -> str:
        return row[index] if index < len(row) else ""

    return {
        "average": average,
        "failed_subjects_count": failed_subjects_count,
        "appointment_start": appointment_start,
        "appointment_end": appointment_end,
        "total_credits": _at(career_row, 1),
        "max_load": _at(career_row, 2),
        "avg_load": _at(career_row, 3),
        "min_load": _at(career_row, 4),
        "min_periods": _at(career_row, 5),
        "max_periods": _at(career_row, 6),
        "credits_earned": _at(trajectory_row, 1),
        "credits_missing": _at(trajectory_row, 2),
        "periods_taken": _at(trajectory_row, 3),
        "periods_available": _at(trajectory_row, 4),
        "authorized_load": _at(trajectory_row, 5),
        "failed_credits_breakdown": breakdown,
    }

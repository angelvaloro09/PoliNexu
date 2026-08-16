"""Parser de la página de Estado del Alumno
(`/Alumnos/boleta/Estado_Alumno.aspx`).

Sin GridViews con `id` (igual que Kárdex, ver `kardex_parser.py`): son tablas
sueltas bajo un encabezado de texto ("MATERIAS REPROBADAS", "MATERIAS NO
CURSADAS", "MATERIAS DESFASADAS"). Se localizan por ese encabezado en vez de
por posición — confirmar contra HTML real al desplegar, como el resto de
parsers de páginas sin id.
"""

import re

from bs4 import BeautifulSoup

from .text_normalize import extract_subject_code, normalize_subject


def _find_table(soup: BeautifulSoup, heading: str):
    marker = soup.find(string=re.compile(heading, re.IGNORECASE))
    if marker is None:
        return None
    return marker.find_next("table")


def _parse_subject_table(table) -> list[dict]:
    if table is None:
        return []

    rows = table.find_all("tr")[1:]  # la primera fila es el encabezado
    entries = []
    for row in rows:
        cells = row.find_all("td")
        if len(cells) < 4:
            continue

        code_cell = cells[0].get_text(strip=True)
        raw_subject = cells[1].get_text(strip=True)
        # Fila espuria: encabezado real + primera fila de datos pegados en una
        # sola celda sin separadores (ver docstring del módulo). Se distingue
        # de una fila real porque el "código" queda absurdamente largo o el
        # "nombre de materia" es sólo un número (el semestre, no un título).
        if len(code_cell) > 20 or raw_subject.isdigit():
            continue

        entries.append(
            {
                "code": extract_subject_code(raw_subject) or code_cell,
                "subject": normalize_subject(raw_subject),
                "period": cells[2].get_text(strip=True),
                "times": cells[3].get_text(strip=True),
            }
        )
    return entries


def parse_academic_status(html: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")

    return {
        "failed": _parse_subject_table(_find_table(soup, "MATERIAS REPROBADAS")),
        "not_taken": _parse_subject_table(_find_table(soup, "MATERIAS NO CURSADAS")),
        "out_of_sequence": _parse_subject_table(_find_table(soup, "MATERIAS DESFASADAS")),
    }

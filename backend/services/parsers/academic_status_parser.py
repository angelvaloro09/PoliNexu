"""Parser de la página de Estado del Alumno
(`/Alumnos/boleta/Estado_Alumno.aspx`).

A diferencia de Kárdex, aquí sí hay GridViews con `id` estable — confirmado
contra HTML real: `ctl00_mainCopy_GV_Reprobadas`, `ctl00_mainCopy_GV_Adeudadas`
(pese al nombre del id, es la sección "MATERIAS NO CURSADAS" en pantalla) y
`ctl00_mainCopy_GV_Desfasadas`. Cada tabla trae su propio `<th>` de encabezado
("Materia" = código, p. ej. "N103"; "Descripcion" = nombre de la materia,
columnas separadas — no van pegadas como "N103 - FISICA..."), así que se
localizan columnas por texto de encabezado en vez de por posición fija: las
tres tablas no comparten exactamente las mismas columnas (p. ej. Reprobadas
trae "Semestre/Nivel", Adeudadas trae "No_Periodo").

Cuando alguna tabla no tiene filas de datos, el SAES la renderiza como un
`<div>` vacío (sin `<table id="...">` en absoluto) en vez de una tabla con
"0 resultados" — por eso `_find_table_by_id` devolviendo `None` es un caso
esperado, no un error de parseo.
"""

from bs4 import BeautifulSoup

from .text_normalize import extract_subject_code, normalize_subject, normalize_title

_TABLE_IDS = {
    "failed": "ctl00_mainCopy_GV_Reprobadas",
    "not_taken": "ctl00_mainCopy_GV_Adeudadas",
    "out_of_sequence": "ctl00_mainCopy_GV_Desfasadas",
}


def _header_index(header_cells: list, *names: str) -> int | None:
    # Coincidencia exacta (o de prefijo de palabra completa) sobre el texto
    # normalizado, no "in" simple: "No_Periodo" contiene la subcadena
    # "periodo" y confundiría la columna de "Periodo_escolar" si se buscara
    # por substring.
    for index, cell in enumerate(header_cells):
        text = cell.get_text(strip=True).lower().replace("_", " ")
        for name in names:
            if text == name or text.startswith(f"{name} "):
                return index
    return None


def _parse_subject_table(table) -> list[dict]:
    if table is None:
        return []

    rows = table.find_all("tr")
    if len(rows) < 2:
        return []

    header_cells = rows[0].find_all(["th", "td"])
    code_index = _header_index(header_cells, "materia")
    name_index = _header_index(header_cells, "descripcion")
    period_index = _header_index(header_cells, "periodo escolar", "periodo")
    times_index = _header_index(header_cells, "veces")

    if code_index is None or name_index is None:
        return []

    entries = []
    for row in rows[1:]:
        cells = row.find_all("td")
        if len(cells) <= max(code_index, name_index):
            continue

        raw_code = cells[code_index].get_text(strip=True)
        raw_name = cells[name_index].get_text(strip=True)
        if not raw_name:
            continue

        entries.append(
            {
                "code": extract_subject_code(raw_name) or normalize_title(raw_code),
                "subject": normalize_subject(raw_name),
                "period": cells[period_index].get_text(strip=True) if period_index is not None
                and len(cells) > period_index
                else "",
                "times": cells[times_index].get_text(strip=True) if times_index is not None
                and len(cells) > times_index
                else "",
            }
        )
    return entries


def parse_academic_status(html: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")

    return {
        key: _parse_subject_table(soup.find("table", id=table_id))
        for key, table_id in _TABLE_IDS.items()
    }

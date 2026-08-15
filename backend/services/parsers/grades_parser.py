"""Parser de la página de Calificaciones
(`/Alumnos/Informacion_semestral/calificaciones_sem.aspx`).

Tabla GridView `ctl00_mainCopy_GV_Calif`: fila de encabezado + una fila por
materia, columnas Gpo/Materia/1er Parcial/2o Parcial/3er Parcial/Ext/Final.
Las celdas sin calificación capturada muestran "-" tal cual las devuelve el
SAES — no se normalizan aquí, se dejan como texto para que la UI decida.
"""

from bs4 import BeautifulSoup


def parse_grades(html: str) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    table = soup.find("table", id="ctl00_mainCopy_GV_Calif")
    if table is None:
        return []

    entries = []
    for row in table.find_all("tr")[1:]:  # la primera fila es el encabezado
        cells = row.find_all("td")
        if len(cells) < 7:
            continue

        entries.append(
            {
                "group": cells[0].get_text(strip=True),
                "subject": cells[1].get_text(strip=True),
                "partial_1": cells[2].get_text(strip=True),
                "partial_2": cells[3].get_text(strip=True),
                "partial_3": cells[4].get_text(strip=True),
                "extraordinary": cells[5].get_text(strip=True),
                "final": cells[6].get_text(strip=True),
            }
        )

    return entries

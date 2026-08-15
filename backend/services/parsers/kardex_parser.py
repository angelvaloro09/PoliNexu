"""Parser de la página de Kárdex (`/Alumnos/boleta/kardex.aspx`).

A diferencia de Horario/Calificaciones (GridViews con `id` estable), el
Kárdex se genera como HTML crudo concatenado del lado del servidor dentro de
un único `<span id="ctl00_mainCopy_Lbl_Kardex">`: una `<table class="bottomBorder">`
por semestre, cuya primera fila (`colspan=6`) es la etiqueta del semestre
("PRIMER SEMESTRE", ...), la segunda es el encabezado de columnas
(Clave/Materia/Fecha/Periodo/Forma Eval./Calificación), y el resto son las
materias cursadas ese semestre.
"""

from bs4 import BeautifulSoup


def _label_text(soup: BeautifulSoup, element_id: str) -> str:
    tag = soup.find(id=element_id)
    return tag.get_text(strip=True) if tag else ""


def parse_kardex(html: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")

    semesters = []
    kardex_container = soup.find(id="ctl00_mainCopy_Lbl_Kardex")
    if kardex_container is not None:
        for table in kardex_container.find_all("table", class_="bottomBorder"):
            rows = table.find_all("tr")
            if len(rows) < 2:
                continue

            label = rows[0].get_text(strip=True)
            subjects = []
            for row in rows[2:]:  # fila 0 = etiqueta de semestre, fila 1 = encabezado
                cells = row.find_all("td")
                if len(cells) < 6:
                    continue
                subjects.append(
                    {
                        "key": cells[0].get_text(strip=True),
                        "subject": cells[1].get_text(strip=True),
                        "date": cells[2].get_text(strip=True),
                        "period": cells[3].get_text(strip=True),
                        "exam_type": cells[4].get_text(strip=True),
                        "grade": cells[5].get_text(strip=True),
                    }
                )

            semesters.append({"label": label, "subjects": subjects})

    return {
        "career": _label_text(soup, "ctl00_mainCopy_Lbl_Carrera"),
        "study_plan": _label_text(soup, "ctl00_mainCopy_Lbl_Plan"),
        "average": _label_text(soup, "ctl00_mainCopy_Lbl_Promedio"),
        "semesters": semesters,
    }

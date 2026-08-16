"""Parser de la página de Datos Personales
(`/Alumnos/info_alumnos/Datos_Alumno.aspx`).

Página sin GridViews: un `<span id="...">` por dato, repartido en 5 tabs del
lado del SAES (Generales/Nacimiento/Dirección/Escolaridad/Padre-Tutor). Sólo
interesan Boleta/Nombre/Plantel — los tres viven en el tab "Generales"
(`ctl00_mainCopy_TabContainer1_Tab_Generales_Lbl_<Campo>`), confirmado contra
HTML real.
"""

from bs4 import BeautifulSoup

from .text_normalize import normalize_title

_PREFIX = "ctl00_mainCopy_TabContainer1_Tab_Generales_Lbl_"


def _label_text(soup: BeautifulSoup, element_id: str) -> str:
    tag = soup.find(id=element_id)
    return tag.get_text(strip=True) if tag else ""


def parse_profile(html: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")

    return {
        "boleta": _label_text(soup, f"{_PREFIX}Boleta"),
        # El SAES lo manda en mayúsculas fijas ("VALENCIA OROPEZA ANGEL YAHIR").
        "nombre": normalize_title(_label_text(soup, f"{_PREFIX}Nombre")),
        # Acrónimo del plantel (p. ej. "UPIICSA") — no normalizar, Title Case
        # lo dejaría peor ("Upiicsa").
        "plantel": _label_text(soup, f"{_PREFIX}Plantel"),
    }

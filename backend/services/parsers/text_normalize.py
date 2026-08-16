"""Normaliza texto en mayúsculas fijas que devuelve el SAES (materias,
profesores) a Title Case legible: "ALGORITMOS COMPUTACIONALES" ->
"Algoritmos Computacionales", "JUAN PEREZ CRUZ" -> "Juan Perez Cruz".
"""

import re

_LOWERCASE_CONNECTORS = {"de", "del", "la", "las", "los", "y", "el"}

# El SAES antepone el código de la materia al nombre, p. ej.
# "ACF0904 - CALCULO DIFERENCIAL" -> sólo interesa "CALCULO DIFERENCIAL".
_SUBJECT_CODE_PREFIX = re.compile(r"^\s*[A-Za-zÀ-ÿ0-9]{2,10}\s*-\s*")


def strip_subject_code(text: str) -> str:
    stripped = _SUBJECT_CODE_PREFIX.sub("", text, count=1)
    return stripped if stripped.strip() else text


def extract_subject_code(text: str) -> str | None:
    """El código antepuesto al nombre (p. ej. "ACF0904"), o `None` si el texto
    no trae uno. Se usa para comparar materias entre páginas del SAES (Estado
    del Alumno vs. Horario) sin depender del texto ya normalizado a Title Case.
    """
    match = _SUBJECT_CODE_PREFIX.match(text)
    if match is None:
        return None
    return match.group(0).rsplit("-", 1)[0].strip()


def normalize_subject(text: str) -> str:
    return normalize_title(strip_subject_code(text))


def normalize_title(text: str) -> str:
    words = text.strip().split()
    if not words:
        return text

    normalized = []
    for index, word in enumerate(words):
        lower = word.lower()
        if index > 0 and lower in _LOWERCASE_CONNECTORS:
            normalized.append(lower)
        else:
            normalized.append(lower[:1].upper() + lower[1:])

    return " ".join(normalized)

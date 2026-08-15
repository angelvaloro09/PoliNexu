"""Catálogo de escuelas IPN para el SAES.

Debe mantenerse en paridad manual con el enum `IpnSchool` en
`app/poliplayer/lib/core/constants/saes_schools.dart` (mismos ids y base_url).
No existe una fuente única de verdad entre Dart y Python — si agregas o
modificas una escuela aquí, replica el cambio también en el archivo Dart.
"""

from typing import TypedDict


class SchoolInfo(TypedDict):
    id: str
    display_name: str
    full_name: str
    base_url: str
    login_url: str
    captcha_url: str


def _school(school_id: str, display_name: str, full_name: str, base_url: str) -> SchoolInfo:
    return {
        "id": school_id,
        "display_name": display_name,
        "full_name": full_name,
        "base_url": base_url,
        "login_url": f"{base_url}/default.aspx",
        "captcha_url": f"{base_url}/c_default_CaptchaImage.aspx",
    }


SCHOOLS: dict[str, SchoolInfo] = {
    school["id"]: school
    for school in [
        _school(
            "upiicsa",
            "UPIICSA",
            "Unidad Profesional Interdisciplinaria de Ingeniería y Ciencias Sociales y "
            "Administrativas",
            "https://www.saes.upiicsa.ipn.mx",
        ),
        _school(
            "escom",
            "ESCOM",
            "Escuela Superior de Cómputo",
            "https://www.saes.escom.ipn.mx",
        ),
        _school(
            "upiita",
            "UPIITA",
            "Unidad Profesional Interdisciplinaria en Ingeniería y Tecnologías Avanzadas",
            "https://www.saes.upiita.ipn.mx",
        ),
        _school(
            "esime_zac",
            "ESIME Zacatenco",
            "Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Zacatenco",
            "https://www.saes.esimez.ipn.mx",
        ),
        _school(
            "esime_cul",
            "ESIME Culhuacán",
            "Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Culhuacán",
            "https://www.saes.esimecu.ipn.mx",
        ),
        _school(
            "esime_tic",
            "ESIME Ticomán",
            "Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Ticomán",
            "https://www.saes.esimetic.ipn.mx",
        ),
        _school(
            "esime_azc",
            "ESIME Azcapotzalco",
            "Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Azcapotzalco",
            "https://www.saes.esimeazc.ipn.mx",
        ),
        _school(
            "esca_sto",
            "ESCA Santo Tomás",
            "Escuela Superior de Comercio y Administración Unidad Santo Tomás",
            "https://www.saes.escasto.ipn.mx",
        ),
        _school(
            "esca_tep",
            "ESCA Tepepan",
            "Escuela Superior de Comercio y Administración Unidad Tepepan",
            "https://www.saes.escatep.ipn.mx",
        ),
        _school(
            "ese",
            "ESE",
            "Escuela Superior de Economía",
            "https://www.saes.ese.ipn.mx",
        ),
        _school(
            "esm",
            "ESM",
            "Escuela Superior de Medicina",
            "https://www.saes.esm.ipn.mx",
        ),
        _school(
            "est",
            "EST",
            "Escuela Superior de Turismo",
            "https://www.saes.est.ipn.mx",
        ),
        _school(
            "esfm",
            "ESFM",
            "Escuela Superior de Física y Matemáticas",
            "https://www.saes.esfm.ipn.mx",
        ),
        _school(
            "esiqie",
            "ESIQIE",
            "Escuela Superior de Ingeniería Química e Industrias Extractivas",
            "https://www.saes.esiqie.ipn.mx",
        ),
        _school(
            "esmia",
            "ESIA Ticomán",
            "Escuela Superior de Ingeniería y Arquitectura Unidad Ticomán",
            "https://www.saes.esiatic.ipn.mx",
        ),
        _school(
            "esiaz",
            "ESIA Zacatenco",
            "Escuela Superior de Ingeniería y Arquitectura Unidad Zacatenco",
            "https://www.saes.esiaz.ipn.mx",
        ),
        _school(
            "encb",
            "ENCB",
            "Escuela Nacional de Ciencias Biológicas",
            "https://www.saes.encb.ipn.mx",
        ),
        _school(
            "upibi",
            "UPIBI",
            "Unidad Profesional Interdisciplinaria de Biotecnología",
            "https://www.saes.upibi.ipn.mx",
        ),
        _school(
            "upig",
            "UPIIG",
            "Unidad Profesional Interdisciplinaria de Ingeniería Campus Guanajuato",
            "https://www.saes.upiig.ipn.mx",
        ),
        _school(
            "upiz",
            "UPIIZ",
            "Unidad Profesional Interdisciplinaria de Ingeniería Campus Zacatecas",
            "https://www.saes.upiiz.ipn.mx",
        ),
    ]
}


def get_school(school_id: str) -> SchoolInfo | None:
    return SCHOOLS.get(school_id)

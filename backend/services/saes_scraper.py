"""Scraping del SAES (ASP.NET WebForms).

Réplica en Python del flujo ya validado en `SaesClient`
(`app/poliplayer/lib/data/saes/saes_client.dart`): mismos nombres de campo de
formulario y mismo criterio de éxito/fallo (302 = éxito, 200 = credenciales o
CAPTCHA incorrectos).

El CAPTCHA usa el componente comercial **BotDetect** (`/BotDetectCaptcha.ashx`),
no una URL estática — cada carga de la página de login genera un par `c`
(id del captcha) / `t` (token) nuevo embebido en el `<img class="LBD_CaptchaImage">`.
Por eso `captcha_url` se extrae del HTML en cada `get_login_page`, en vez de
construirse a partir de un sufijo fijo (a diferencia del `captchaUrl` estático
que aún usa `IpnSchool` en Dart — desactualizado, se retira en la migración a
este backend).

BotDetect también exige que el POST de login incluya sus campos ocultos
`LBD_VCID_<captchaId>` (liga el texto ingresado con la instancia de CAPTCHA
generada) y `LBD_BackWorkaround_<captchaId>` — sin ellos el servidor rechaza
el CAPTCHA como incorrecto sin importar que el texto sea el correcto. Se
extraen dinámicamente (nombre variable por escuela) en `extract_aspnet_tokens`
y se reenvían tal cual en `login`.
"""

from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
)


class AspNetTokens:
    __slots__ = ("view_state", "view_state_generator", "event_validation", "captcha_url", "captcha_fields")

    def __init__(
        self,
        view_state: str,
        view_state_generator: str,
        event_validation: str,
        captcha_url: str = "",
        captcha_fields: dict[str, str] | None = None,
    ):
        self.view_state = view_state
        self.view_state_generator = view_state_generator
        self.event_validation = event_validation
        self.captcha_url = captcha_url
        self.captcha_fields = captcha_fields or {}

    @property
    def is_valid(self) -> bool:
        return bool(self.view_state) and bool(self.event_validation) and bool(self.captcha_url)


class SaesScraperError(Exception):
    pass


def decode_html(response: requests.Response) -> str:
    """`requests` decide el encoding a partir del header `Content-Type`; las
    páginas del SAES no siempre declaran `charset` ahí, y sin esa pista
    `requests` cae a ISO-8859-1 por defecto (RFC 2616) aunque el contenido
    real sea UTF-8 — corrompe acentos/ñ. Usamos la detección real del
    contenido (`apparent_encoding`) en su lugar."""
    response.encoding = response.apparent_encoding
    return response.text


def new_scraper_session() -> requests.Session:
    session = requests.Session()
    session.headers.update(
        {
            "User-Agent": USER_AGENT,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,"
            "image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "es-MX,es;q=0.9,en-US;q=0.8,en;q=0.7",
        }
    )
    return session


def extract_aspnet_tokens(html: str) -> AspNetTokens:
    soup = BeautifulSoup(html, "html.parser")

    def _value(field_id: str) -> str:
        tag = soup.find("input", {"id": field_id})
        return tag["value"] if tag and tag.has_attr("value") else ""

    captcha_img = soup.find("img", class_="LBD_CaptchaImage")
    captcha_url = captcha_img["src"] if captcha_img and captcha_img.has_attr("src") else ""

    # Campos ocultos de BotDetect (LBD_VCID_*, LBD_BackWorkaround_*) — nombre
    # variable según el id de control del captcha, por eso se buscan por prefijo.
    captcha_fields = {
        tag["name"]: tag.get("value", "")
        for tag in soup.find_all("input", {"name": lambda n: n and n.startswith("LBD_")})
    }

    return AspNetTokens(
        view_state=_value("__VIEWSTATE"),
        view_state_generator=_value("__VIEWSTATEGENERATOR"),
        event_validation=_value("__EVENTVALIDATION"),
        captcha_url=captcha_url,
        captcha_fields=captcha_fields,
    )


def get_login_page(session: requests.Session, login_url: str) -> AspNetTokens:
    try:
        response = session.get(login_url, timeout=15)
        response.raise_for_status()
    except requests.RequestException as exc:
        raise SaesScraperError(f"Error al conectar con el SAES: {exc}") from exc

    tokens = extract_aspnet_tokens(decode_html(response))
    if not tokens.is_valid:
        raise SaesScraperError(
            "No se pudieron obtener los tokens de seguridad ASP.NET o la URL del "
            "CAPTCHA. La página del SAES podría haber cambiado o estar inactiva."
        )
    return tokens


def get_captcha_bytes(session: requests.Session, base_url: str, tokens: AspNetTokens) -> bytes:
    """Descarga la imagen del CAPTCHA usando la URL dinámica extraída de la
    página de login (`tokens.captcha_url`), resuelta contra `base_url`."""
    try:
        absolute_url = urljoin(base_url, tokens.captcha_url)
        response = session.get(absolute_url, timeout=15)
        response.raise_for_status()
        return response.content
    except requests.RequestException as exc:
        raise SaesScraperError(f"Error al descargar el CAPTCHA: {exc}") from exc


def login(
    session: requests.Session,
    login_url: str,
    tokens: AspNetTokens,
    boleta: str,
    password: str,
    captcha: str,
) -> tuple[bool, str | None]:
    """Realiza el POST de login. Retorna (success, error_message)."""
    payload = {
        "__VIEWSTATE": tokens.view_state,
        "__VIEWSTATEGENERATOR": tokens.view_state_generator,
        "__EVENTVALIDATION": tokens.event_validation,
        "ctl00$leftColumn$LoginUser$UserName": boleta,
        "ctl00$leftColumn$LoginUser$Password": password,
        "ctl00$leftColumn$LoginUser$CaptchaCodeTextBox": captcha,
        "ctl00$leftColumn$LoginUser$LoginButton": "Iniciar",
        **tokens.captcha_fields,
    }

    try:
        response = session.post(
            login_url,
            data=payload,
            allow_redirects=False,
            timeout=15,
        )
    except requests.RequestException as exc:
        return False, f"Error de conexión durante el login: {exc}"

    if response.status_code == 302:
        return True, None

    if response.status_code == 200:
        soup = BeautifulSoup(decode_html(response), "html.parser")
        error_span = soup.find(id="ctl00_leftColumn_LoginUser_ValidationSummary1")
        captcha_error = soup.find(id="ctl00_leftColumn_LoginUser_CaptchaCodeValidator")
        failure_notification = soup.find(class_="failureNotification")

        if error_span and error_span.get_text(strip=True):
            return False, error_span.get_text(strip=True)
        if failure_notification and failure_notification.get_text(strip=True):
            return False, failure_notification.get_text(strip=True)
        if captcha_error and captcha_error.get_text(strip=True):
            return False, "El código CAPTCHA es incorrecto."
        return False, "Credenciales o CAPTCHA incorrectos."

    return False, f"Error de servidor: HTTP {response.status_code}"

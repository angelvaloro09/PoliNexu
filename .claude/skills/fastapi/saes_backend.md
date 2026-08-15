# Skill: FastAPI Backend — SAES Scraper

## Estructura del Backend

```
backend/
  main.py                   ← entrada: instancia FastAPI, incluye routers
  requirements.txt
  venv/
  routers/
    auth.py                 ← POST /auth/login, GET /auth/captcha, POST /auth/logout
    saes.py                 ← GET /saes/grades, GET /saes/schedule, GET /saes/kardex
  services/
    saes_scraper.py         ← lógica de scraping con requests + BeautifulSoup
    session_manager.py      ← manejo del pool de sesiones activas
  models/
    schemas.py              ← Pydantic v2: request/response schemas
  database/
    db.py                   ← SQLAlchemy engine + session factory
    models.py               ← modelos ORM (SaesSession table)
  core/
    config.py               ← settings con pydantic-settings
    schools.py              ← catálogo de escuelas IPN (URLs por plantel)
```

---

## main.py Base

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, saes

app = FastAPI(
    title="PoliNexu Backend",
    description="SAES scraper API para la app PoliNexu",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, limitar al origen de la app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(saes.router, prefix="/saes", tags=["SAES"])
```

---

## Session Manager — Patrón

El backend mantiene un pool de sesiones activas por usuario. Cada sesión encapsula
la instancia de `requests.Session` con las cookies ASP.NET_SessionId ya autenticadas.

```python
# services/session_manager.py
import uuid
from typing import Dict
import requests

class SessionManager:
    """Gestiona sesiones HTTP activas de SAES por token de sesión."""
    
    _sessions: Dict[str, requests.Session] = {}

    def create_session(self) -> tuple[str, requests.Session]:
        token = str(uuid.uuid4())
        session = requests.Session()
        session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...",
        })
        self._sessions[token] = session
        return token, session

    def get_session(self, token: str) -> requests.Session | None:
        return self._sessions.get(token)

    def destroy_session(self, token: str) -> None:
        self._sessions.pop(token, None)

session_manager = SessionManager()  # Singleton
```

---

## Scraper — ASP.NET WebForms

### Flujo de Login

```python
# services/saes_scraper.py
from bs4 import BeautifulSoup
import requests

def extract_aspnet_tokens(html: str) -> dict:
    """Extrae __VIEWSTATE, __VIEWSTATEGENERATOR, __EVENTVALIDATION del HTML."""
    soup = BeautifulSoup(html, "html.parser")
    return {
        "__VIEWSTATE": soup.find("input", {"id": "__VIEWSTATE"})["value"],
        "__VIEWSTATEGENERATOR": soup.find("input", {"id": "__VIEWSTATEGENERATOR"})["value"],
        "__EVENTVALIDATION": soup.find("input", {"id": "__EVENTVALIDATION"})["value"],
    }

def get_login_page(session: requests.Session, login_url: str) -> dict:
    """Obtiene la página de login y extrae los tokens ASP.NET."""
    response = session.get(login_url, verify=True)
    response.raise_for_status()
    return extract_aspnet_tokens(response.text)

def get_captcha_bytes(session: requests.Session, captcha_url: str) -> bytes:
    """Descarga la imagen del CAPTCHA usando la misma sesión."""
    response = session.get(captcha_url)
    response.raise_for_status()
    return response.content

def login(
    session: requests.Session,
    login_url: str,
    tokens: dict,
    boleta: str,
    password: str,
    captcha: str,
) -> bool:
    """Realiza el POST de login. Retorna True si exitoso (302 redirect)."""
    payload = {
        "__VIEWSTATE": tokens["__VIEWSTATE"],
        "__VIEWSTATEGENERATOR": tokens["__VIEWSTATEGENERATOR"],
        "__EVENTVALIDATION": tokens["__EVENTVALIDATION"],
        "ctl00$leftColumn$LoginUser$UserName": boleta,
        "ctl00$leftColumn$LoginUser$Password": password,
        "ctl00$leftColumn$LoginUser$CaptchaCodeTextBox": captcha,
        "ctl00$leftColumn$LoginUser$LoginButton": "Iniciar Sesión",
    }
    response = session.post(
        login_url,
        data=payload,
        allow_redirects=False,
    )
    # 302 = redirect a home = login exitoso
    return response.status_code == 302
```

---

## Schemas Pydantic v2

```python
# models/schemas.py
from pydantic import BaseModel

class CaptchaResponse(BaseModel):
    session_token: str
    captcha_base64: str  # imagen en base64 para enviar al cliente Flutter

class LoginRequest(BaseModel):
    session_token: str
    school_code: str    # ej: "upiicsa"
    boleta: str
    password: str
    captcha_text: str

class LoginResponse(BaseModel):
    success: bool
    session_token: str
    message: str

class GradesResponse(BaseModel):
    session_token: str
    grades: list[dict]  # estructurado según parser

class ScheduleEntry(BaseModel):
    subject: str
    group: str
    day: str
    start_time: str
    end_time: str
    classroom: str
    teacher: str
```

---

## Catálogo de Escuelas

```python
# core/schools.py
SCHOOLS: dict[str, dict] = {
    "upiicsa": {
        "name": "UPIICSA",
        "base_url": "https://www.saes.upiicsa.ipn.mx",
        "login_url": "https://www.saes.upiicsa.ipn.mx/default.aspx",
        "captcha_url": "https://www.saes.upiicsa.ipn.mx/Imagenes/CaptchaImage.ashx",
    },
    "escom": {
        "name": "ESCOM",
        "base_url": "https://www.saes.escom.ipn.mx",
        "login_url": "https://www.saes.escom.ipn.mx/default.aspx",
        "captcha_url": "https://www.saes.escom.ipn.mx/Imagenes/CaptchaImage.ashx",
    },
    # Agregar más escuelas conforme se validen...
}
```

---

## Reglas del Backend

1. **Nunca almacenes contraseñas** — el backend solo actúa como proxy de scraping.
2. **Sesiones identificadas por UUID** — el cliente Flutter recibe el token y lo envía en
   cada request siguiente. El backend lo usa para recuperar la `requests.Session` correcta.
3. **Tiempo de vida de sesión**: si el SAES retorna 401/redirect a login en una petición
   autenticada, destruye la sesión y notifica al cliente con HTTP 401 para que re-autentique.
4. **Parsers aislados**: cada tipo de página del SAES tiene su propio parser en
   `services/parsers/<feature>_parser.py`. No mezcles parsers en el router.
5. **CORS**: en desarrollo permite todos los orígenes. En producción, limitar al origen
   de la app (o IP local donde corra el backend en el teléfono/PC del usuario).

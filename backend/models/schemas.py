from pydantic import BaseModel


class SchoolOut(BaseModel):
    id: str
    display_name: str
    full_name: str


class SessionRequest(BaseModel):
    school_code: str


class CaptchaResponse(BaseModel):
    session_token: str
    captcha_base64: str


class LoginRequest(BaseModel):
    session_token: str
    boleta: str
    password: str
    captcha_text: str
    # Guardar las credenciales cifradas en el backend para poder re-autenticar
    # con sólo el CAPTCHA cuando el SAES mate la sesión.
    remember: bool = True


class ReauthSessionRequest(BaseModel):
    """Pide sesión + CAPTCHA para re-loguear; la escuela sale de la cuenta."""

    account_id: str


class ReauthRequest(BaseModel):
    """Re-login con credenciales ya guardadas: sólo falta el CAPTCHA.

    El cliente pide antes un `session_token` + CAPTCHA nuevos con
    `POST /auth/session` (el par (c, t) de BotDetect es de un solo uso).
    """

    session_token: str
    account_id: str
    captcha_text: str


class LoginResponse(BaseModel):
    success: bool
    message: str | None = None
    # Presente sólo si las credenciales se guardaron; el cliente lo persiste.
    account_id: str | None = None


class SessionStatusResponse(BaseModel):
    valid: bool
    authenticated: bool
    account_id: str | None = None


class KeepAliveRequest(BaseModel):
    session_token: str


class LogoutRequest(BaseModel):
    session_token: str
    # Si viene, además borra las credenciales guardadas ("cerrar sesión" de verdad).
    account_id: str | None = None


class ScheduleSession(BaseModel):
    day: str
    start_time: str
    end_time: str
    building: str | None = None
    classroom: str | None = None


class ScheduleEntry(BaseModel):
    group: str
    subject: str
    teachers: str
    sessions: list[ScheduleSession]


class ScheduleResponse(BaseModel):
    entries: list[ScheduleEntry]


class GradeEntry(BaseModel):
    group: str
    subject: str
    partial_1: str
    partial_2: str
    partial_3: str
    extraordinary: str
    final: str


class GradesResponse(BaseModel):
    entries: list[GradeEntry]


class KardexSubject(BaseModel):
    key: str
    subject: str
    date: str
    period: str
    exam_type: str
    grade: str


class KardexSemester(BaseModel):
    label: str
    subjects: list[KardexSubject]


class KardexResponse(BaseModel):
    career: str
    study_plan: str
    average: str
    semesters: list[KardexSemester]

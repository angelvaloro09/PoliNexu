import 'package:dio/dio.dart';
import '../../core/constants/api_config.dart';

/// Error de comunicación con el backend PoliNexu (red o respuesta de error).
class BackendException implements Exception {
  final String message;
  BackendException(this.message);

  @override
  String toString() => message;
}

/// La sesión SAES ya no sirve (HTTP 401 del backend): expiró del lado del
/// servidor o nunca se autenticó. Se distingue de [BackendException] porque la
/// UI reacciona distinto — dispara el re-login sólo-CAPTCHA en vez de mostrar
/// un error genérico.
class SessionExpiredException extends BackendException {
  SessionExpiredException(super.message);
}

class CaptchaResponseDto {
  final String sessionToken;
  final String captchaBase64;

  CaptchaResponseDto({required this.sessionToken, required this.captchaBase64});

  factory CaptchaResponseDto.fromJson(Map<String, dynamic> json) => CaptchaResponseDto(
        sessionToken: json['session_token'] as String,
        captchaBase64: json['captcha_base64'] as String,
      );
}

class LoginResponseDto {
  final bool success;
  final String? message;

  /// Presente si el backend guardó las credenciales cifradas; el cliente lo
  /// persiste para poder re-autenticar con sólo el CAPTCHA.
  final String? accountId;

  LoginResponseDto({required this.success, this.message, this.accountId});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) => LoginResponseDto(
        success: json['success'] as bool,
        message: json['message'] as String?,
        accountId: json['account_id'] as String?,
      );
}

/// Estado de una sesión guardada, verificado contra el SAES.
class SessionStatusDto {
  final bool valid;
  final bool authenticated;
  final String? accountId;

  SessionStatusDto({required this.valid, required this.authenticated, this.accountId});

  factory SessionStatusDto.fromJson(Map<String, dynamic> json) => SessionStatusDto(
        valid: json['valid'] as bool,
        authenticated: json['authenticated'] as bool,
        accountId: json['account_id'] as String?,
      );
}

class ScheduleSessionDto {
  final String day;
  final String startTime;
  final String endTime;
  final String? building;
  final String? classroom;

  ScheduleSessionDto({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.building,
    this.classroom,
  });

  factory ScheduleSessionDto.fromJson(Map<String, dynamic> json) => ScheduleSessionDto(
        day: json['day'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        building: json['building'] as String?,
        classroom: json['classroom'] as String?,
      );
}

extension ScheduleSessionDtoJson on ScheduleSessionDto {
  Map<String, dynamic> toJson() => {
        'day': day,
        'start_time': startTime,
        'end_time': endTime,
        'building': building,
        'classroom': classroom,
      };
}

class ScheduleEntryDto {
  final String group;
  final String subject;
  final String teachers;
  final List<ScheduleSessionDto> sessions;

  ScheduleEntryDto({
    required this.group,
    required this.subject,
    required this.teachers,
    required this.sessions,
  });

  factory ScheduleEntryDto.fromJson(Map<String, dynamic> json) => ScheduleEntryDto(
        group: json['group'] as String,
        subject: json['subject'] as String,
        teachers: json['teachers'] as String,
        sessions: (json['sessions'] as List)
            .map((s) => ScheduleSessionDto.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

extension ScheduleEntryDtoJson on ScheduleEntryDto {
  Map<String, dynamic> toJson() => {
        'group': group,
        'subject': subject,
        'teachers': teachers,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
}

class GradeEntryDto {
  final String group;
  final String subject;
  final String partial1;
  final String partial2;
  final String partial3;
  final String extraordinary;
  final String finalGrade;

  GradeEntryDto({
    required this.group,
    required this.subject,
    required this.partial1,
    required this.partial2,
    required this.partial3,
    required this.extraordinary,
    required this.finalGrade,
  });

  factory GradeEntryDto.fromJson(Map<String, dynamic> json) => GradeEntryDto(
        group: json['group'] as String,
        subject: json['subject'] as String,
        partial1: json['partial_1'] as String,
        partial2: json['partial_2'] as String,
        partial3: json['partial_3'] as String,
        extraordinary: json['extraordinary'] as String,
        finalGrade: json['final'] as String,
      );
}

extension GradeEntryDtoJson on GradeEntryDto {
  Map<String, dynamic> toJson() => {
        'group': group,
        'subject': subject,
        'partial_1': partial1,
        'partial_2': partial2,
        'partial_3': partial3,
        'extraordinary': extraordinary,
        'final': finalGrade,
      };
}

class KardexSubjectDto {
  final String key;
  final String subject;
  final String date;
  final String period;
  final String examType;
  final String grade;

  KardexSubjectDto({
    required this.key,
    required this.subject,
    required this.date,
    required this.period,
    required this.examType,
    required this.grade,
  });

  factory KardexSubjectDto.fromJson(Map<String, dynamic> json) => KardexSubjectDto(
        key: json['key'] as String,
        subject: json['subject'] as String,
        date: json['date'] as String,
        period: json['period'] as String,
        examType: json['exam_type'] as String,
        grade: json['grade'] as String,
      );
}

extension KardexSubjectDtoJson on KardexSubjectDto {
  Map<String, dynamic> toJson() => {
        'key': key,
        'subject': subject,
        'date': date,
        'period': period,
        'exam_type': examType,
        'grade': grade,
      };
}

class KardexSemesterDto {
  final String label;
  final List<KardexSubjectDto> subjects;

  KardexSemesterDto({required this.label, required this.subjects});

  factory KardexSemesterDto.fromJson(Map<String, dynamic> json) => KardexSemesterDto(
        label: json['label'] as String,
        subjects: (json['subjects'] as List)
            .map((s) => KardexSubjectDto.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

extension KardexSemesterDtoJson on KardexSemesterDto {
  Map<String, dynamic> toJson() => {
        'label': label,
        'subjects': subjects.map((s) => s.toJson()).toList(),
      };
}

class KardexDto {
  final String career;
  final String studyPlan;
  final String average;
  final List<KardexSemesterDto> semesters;

  KardexDto({
    required this.career,
    required this.studyPlan,
    required this.average,
    required this.semesters,
  });

  factory KardexDto.fromJson(Map<String, dynamic> json) => KardexDto(
        career: json['career'] as String,
        studyPlan: json['study_plan'] as String,
        average: json['average'] as String,
        semesters: (json['semesters'] as List)
            .map((s) => KardexSemesterDto.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

extension KardexDtoJson on KardexDto {
  Map<String, dynamic> toJson() => {
        'career': career,
        'study_plan': studyPlan,
        'average': average,
        'semesters': semesters.map((s) => s.toJson()).toList(),
      };
}

class AcademicCalendarEventDto {
  final String id;
  final String title;
  final String category;
  final String startDate;
  final String endDate;

  AcademicCalendarEventDto({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    required this.endDate,
  });

  factory AcademicCalendarEventDto.fromJson(Map<String, dynamic> json) => AcademicCalendarEventDto(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
      );
}

extension AcademicCalendarEventDtoJson on AcademicCalendarEventDto {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'start_date': startDate,
        'end_date': endDate,
      };
}

/// Cliente HTTP del backend FastAPI (`backend/routers/auth.py`, `saes.py`).
/// Todo el scraping del SAES vive en el backend — el cliente Flutter nunca
/// habla directo con el SAES.
class BackendClient {
  final Dio _dio;

  BackendClient()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<CaptchaResponseDto> createSession(String schoolCode) async {
    try {
      final response = await _dio.post(
        '/auth/session',
        data: {'school_code': schoolCode},
      );
      return CaptchaResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Sesión + CAPTCHA para el re-login de una cuenta recordada. La escuela la
  /// resuelve el backend desde el `accountId`, así que el cliente no necesita
  /// recordarla.
  Future<CaptchaResponseDto> createReauthSession(String accountId) async {
    try {
      final response = await _dio.post(
        '/auth/reauth/session',
        data: {'account_id': accountId},
      );
      return CaptchaResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<CaptchaResponseDto> reloadCaptcha(String sessionToken) async {
    try {
      final response = await _dio.get(
        '/auth/captcha',
        queryParameters: {'session_token': sessionToken},
      );
      return CaptchaResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<LoginResponseDto> login({
    required String sessionToken,
    required String boleta,
    required String password,
    required String captchaText,
    bool remember = true,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'session_token': sessionToken,
          'boleta': boleta,
          'password': password,
          'captcha_text': captchaText,
          'remember': remember,
        },
      );
      return LoginResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Re-login con las credenciales que el backend tiene cifradas: el usuario
  /// sólo teclea el CAPTCHA. [sessionToken] debe venir de un `createSession`
  /// reciente (el par (c, t) de BotDetect es de un solo uso).
  Future<LoginResponseDto> reauth({
    required String sessionToken,
    required String accountId,
    required String captchaText,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reauth',
        data: {
          'session_token': sessionToken,
          'account_id': accountId,
          'captcha_text': captchaText,
        },
      );
      return LoginResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Verifica contra el SAES si la sesión guardada sigue sirviendo.
  Future<SessionStatusDto> getAuthStatus(String sessionToken) async {
    try {
      final response = await _dio.get(
        '/auth/status',
        queryParameters: {'session_token': sessionToken},
      );
      return SessionStatusDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Ping que resetea el sliding timeout de la sesión del SAES.
  Future<SessionStatusDto> keepAlive(String sessionToken) async {
    try {
      final response = await _dio.post(
        '/auth/keepalive',
        data: {'session_token': sessionToken},
      );
      return SessionStatusDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Cierra la sesión. Con [accountId] además borra las credenciales
  /// guardadas en el backend (cierre de sesión real).
  Future<void> logout({required String sessionToken, String? accountId}) async {
    try {
      await _dio.post(
        '/auth/logout',
        data: {
          'session_token': sessionToken,
          'account_id': ?accountId,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<ScheduleEntryDto>> getSchedule(String sessionToken) async {
    try {
      final response = await _dio.get(
        '/saes/schedule',
        queryParameters: {'session_token': sessionToken},
      );
      final entries = (response.data as Map<String, dynamic>)['entries'] as List;
      return entries.map((e) => ScheduleEntryDto.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<GradeEntryDto>> getGrades(String sessionToken) async {
    try {
      final response = await _dio.get(
        '/saes/grades',
        queryParameters: {'session_token': sessionToken},
      );
      final entries = (response.data as Map<String, dynamic>)['entries'] as List;
      return entries.map((e) => GradeEntryDto.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<KardexDto> getKardex(String sessionToken) async {
    try {
      final response = await _dio.get(
        '/saes/kardex',
        queryParameters: {'session_token': sessionToken},
      );
      return KardexDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Calendario académico institucional del IPN. Dato público, sin sesión.
  Future<List<AcademicCalendarEventDto>> getAcademicCalendar() async {
    try {
      final response = await _dio.get('/calendar/ipn');
      final events = (response.data as Map<String, dynamic>)['events'] as List;
      return events
          .map((e) => AcademicCalendarEventDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// El 401 del backend siempre significa "sesión inservible" (ver
  /// `routers/saes.py::_authenticated_state`), así que se tipa aparte para que
  /// la UI pueda ofrecer el re-login sólo-CAPTCHA.
  BackendException _mapError(DioException e) {
    final message = _extractError(e);
    if (e.response?.statusCode == 401) {
      return SessionExpiredException(message);
    }
    return BackendException(message);
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return e.message ?? 'Error de conexión con el backend.';
  }
}

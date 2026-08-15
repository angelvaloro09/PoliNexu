import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:poliplayer/app.dart';
import 'package:poliplayer/core/constants/saes_schools.dart';
import 'package:poliplayer/core/di/injection.dart';
import 'package:poliplayer/domain/models/auth_login_result.dart';
import 'package:poliplayer/domain/models/grade_entry.dart';
import 'package:poliplayer/domain/models/kardex.dart';
import 'package:poliplayer/domain/models/remote_data.dart';
import 'package:poliplayer/domain/models/schedule_entry.dart';
import 'package:poliplayer/domain/models/session_restore_result.dart';
import 'package:poliplayer/domain/models/task_item.dart';
import 'package:poliplayer/domain/repositories/app_preferences.dart';
import 'package:poliplayer/domain/repositories/auth_repository.dart';
import 'package:poliplayer/domain/repositories/grades_repository.dart';
import 'package:poliplayer/domain/repositories/kardex_repository.dart';
import 'package:poliplayer/domain/repositories/notification_service.dart';
import 'package:poliplayer/domain/repositories/schedule_repository.dart';
import 'package:poliplayer/domain/repositories/session_store.dart';
import 'package:poliplayer/domain/repositories/task_repository.dart';
import 'package:poliplayer/presentation/router/app_router.dart';

/// Repositorio falso: evita llamadas HTTP reales (el backend no corre en tests).
class _FakeAuthRepository implements AuthRepository {
  final SessionRestoreResult restoreResult;

  _FakeAuthRepository({this.restoreResult = SessionRestoreResult.loginRequired});

  @override
  String? get currentSessionToken => null;

  @override
  String? get currentAccountId => null;

  @override
  Future<SessionRestoreResult> restoreSession() async => restoreResult;

  @override
  Future<Uint8List> requestCaptcha(IpnSchool school) async => Uint8List(0);

  @override
  Future<Uint8List> requestReauthCaptcha() async => Uint8List(0);

  @override
  Future<Uint8List> reloadCaptcha() async => Uint8List(0);

  @override
  Future<AuthLoginResult> login({
    required String boleta,
    required String password,
    required String captchaText,
  }) async =>
      const AuthLoginResult(success: false, errorMessage: 'n/a');

  @override
  Future<AuthLoginResult> reauth({required String captchaText}) async =>
      const AuthLoginResult(success: false, errorMessage: 'n/a');

  @override
  Future<bool> keepAlive() async => true;

  @override
  Future<void> logout({bool forgetAccount = false}) async {}
}

/// Preferencias falsas: evita abrir Drift. Por defecto el onboarding ya se
/// vio, para que los tests entren directo al flujo de sesión.
class _FakeAppPreferences implements AppPreferences {
  bool seen;

  _FakeAppPreferences({this.seen = true});

  @override
  Future<bool> hasSeenOnboarding() async => seen;

  @override
  Future<void> markOnboardingSeen() async => seen = true;
}

/// Almacén falso: `flutter_secure_storage` no tiene implementación de
/// plataforma en `flutter test` (mismo criterio que el resto de fakes).
class _FakeSessionStore implements SessionStore {
  @override
  Future<String?> readSessionToken() async => null;

  @override
  Future<void> writeSessionToken(String token) async {}

  @override
  Future<void> clearSessionToken() async {}

  @override
  Future<String?> readAccountId() async => null;

  @override
  Future<void> writeAccountId(String accountId) async {}

  @override
  Future<void> clear() async {}
}

/// Repositorio falso: evita abrir una base de datos SQLite real (sin
/// binding nativo disponible en el entorno de `flutter test`).
class _FakeTaskRepository implements TaskRepository {
  @override
  Stream<List<TaskItem>> watchTasks() => Stream.value(const []);

  @override
  Future<TaskItem> addTask(TaskItem task) async => task;

  @override
  Future<void> updateTask(TaskItem task) async {}

  @override
  Future<void> deleteTask(int id) async {}
}

/// Los repositorios reales de SAES ahora tocan Drift para la caché offline,
/// así que también hay que sustituirlos o el test se cuelga abriendo SQLite.
class _FakeScheduleRepository implements ScheduleRepository {
  @override
  Future<RemoteData<List<ScheduleEntry>>> getSchedule() async =>
      RemoteData.fresh(const <ScheduleEntry>[]);
}

class _FakeGradesRepository implements GradesRepository {
  @override
  Future<RemoteData<List<GradeEntry>>> getGrades() async =>
      RemoteData.fresh(const <GradeEntry>[]);

  @override
  Future<Map<String, String>> loadCachedGrades() async => const {};

  @override
  Future<void> saveCachedGrades(Map<String, String> grades) async {}
}

class _FakeKardexRepository implements KardexRepository {
  @override
  Future<RemoteData<Kardex>> getKardex() async => RemoteData.fresh(
        const Kardex(career: '', studyPlan: '', average: '', semesters: []),
      );
}

/// Servicio falso: evita invocar el plugin nativo de notificaciones (sin
/// implementación de plataforma en el entorno de `flutter test`).
class _FakeNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> scheduleTaskReminder(TaskItem task) async {}

  @override
  Future<void> cancelTaskReminder(int taskId) async {}

  @override
  Future<void> scheduleClassAlarms(List<ScheduleEntry> entries) async {}

  @override
  Future<void> notifyNewGrade({required String subject, required String grade}) async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  /// `pumpAndSettle` no sirve en las pantallas que muestran `NexusHero`: su
  /// animación es infinita y el settle nunca llega. Se bombea a mano lo
  /// suficiente para cubrir la animación de entrada del splash
  /// (`AppMotion.intro`, que la navegación espera) más la transición de ruta.
  Future<void> pumpUntilRouted(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  void registerFakes({
    SessionRestoreResult restoreResult = SessionRestoreResult.loginRequired,
    bool onboardingSeen = true,
  }) {
    configureDependencies();
    getIt.unregister<AppPreferences>();
    getIt.registerLazySingleton<AppPreferences>(
      () => _FakeAppPreferences(seen: onboardingSeen),
    );
    getIt.unregister<AuthRepository>();
    getIt.registerLazySingleton<AuthRepository>(
      () => _FakeAuthRepository(restoreResult: restoreResult),
    );
    getIt.unregister<SessionStore>();
    getIt.registerLazySingleton<SessionStore>(() => _FakeSessionStore());
    getIt.unregister<TaskRepository>();
    getIt.registerLazySingleton<TaskRepository>(() => _FakeTaskRepository());
    getIt.unregister<ScheduleRepository>();
    getIt.registerLazySingleton<ScheduleRepository>(() => _FakeScheduleRepository());
    getIt.unregister<GradesRepository>();
    getIt.registerLazySingleton<GradesRepository>(() => _FakeGradesRepository());
    getIt.unregister<KardexRepository>();
    getIt.registerLazySingleton<KardexRepository>(() => _FakeKardexRepository());
    getIt.unregister<NotificationService>();
    getIt.registerLazySingleton<NotificationService>(() => _FakeNotificationService());
  }

  tearDown(() => getIt.reset());

  testWidgets('Sin sesión guardada, el splash lleva al login', (WidgetTester tester) async {
    registerFakes();

    await tester.pumpWidget(PoliNexuApp(router: buildAppRouter()));
    await pumpUntilRouted(tester);

    // 'PoliNexu' aparece en splash y login, así que el marcador del destino
    // es el botón del formulario.
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('Con sesión viva, el splash entra directo a /home',
      (WidgetTester tester) async {
    registerFakes(restoreResult: SessionRestoreResult.authenticated);

    await tester.pumpWidget(PoliNexuApp(router: buildAppRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Clases de hoy'), findsOneWidget);
  });

  testWidgets('Con credenciales guardadas, el splash pide sólo el CAPTCHA',
      (WidgetTester tester) async {
    registerFakes(restoreResult: SessionRestoreResult.reauthRequired);

    await tester.pumpWidget(PoliNexuApp(router: buildAppRouter()));
    await pumpUntilRouted(tester);

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('En el primer arranque, el splash lleva al onboarding',
      (WidgetTester tester) async {
    registerFakes(onboardingSeen: false);

    await tester.pumpWidget(PoliNexuApp(router: buildAppRouter()));
    await pumpUntilRouted(tester);

    expect(find.text('Tu SAES, sin el SAES'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });

  testWidgets('Navigating to /home shows the shell with bottom navigation',
      (WidgetTester tester) async {
    registerFakes();

    final router = buildAppRouter();
    await tester.pumpWidget(PoliNexuApp(router: router));
    await pumpUntilRouted(tester);

    router.go('/home');
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Clases de hoy'), findsOneWidget);
    expect(find.text('Tareas pendientes'), findsOneWidget);

    router.go('/tasks');
    await tester.pumpAndSettle();

    expect(find.text('Sin tareas'), findsOneWidget);
    expect(find.text('Crear la primera'), findsOneWidget);
  });
}

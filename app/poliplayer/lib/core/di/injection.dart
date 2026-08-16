import 'package:get_it/get_it.dart';
import '../../data/database/app_database.dart';
import '../../data/local/secure_session_store.dart';
import '../../data/remote/backend_client.dart';
import '../../data/repositories/academic_status_repository_impl.dart';
import '../../data/repositories/app_preferences_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../data/repositories/grades_repository_impl.dart';
import '../../data/repositories/kardex_repository_impl.dart';
import '../../data/repositories/reinscription_repository_impl.dart';
import '../../data/repositories/schedule_overrides_repository_impl.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/services/notification_service_impl.dart';
import '../../data/services/school_cycle_lifecycle_service.dart';
import '../../domain/repositories/academic_status_repository.dart';
import '../../domain/repositories/app_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/grades_repository.dart';
import '../../domain/repositories/kardex_repository.dart';
import '../../domain/repositories/notification_service.dart';
import '../../domain/repositories/reinscription_repository.dart';
import '../../domain/repositories/schedule_overrides_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/school_cycle_gate.dart';
import '../../domain/repositories/session_store.dart';
import '../../domain/repositories/task_repository.dart';
import '../../presentation/blocs/academic_status/academic_status_cubit.dart';
import '../../presentation/blocs/auth/auth_cubit.dart';
import '../../presentation/blocs/calendar/calendar_cubit.dart';
import '../../presentation/blocs/grades/grades_cubit.dart';
import '../../presentation/blocs/kardex/kardex_cubit.dart';
import '../../presentation/blocs/reinscription/reinscription_cubit.dart';
import '../../presentation/blocs/schedule/schedule_cubit.dart';
import '../../presentation/blocs/schedule/schedule_overrides_cubit.dart';
import '../../presentation/blocs/tasks/tasks_cubit.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Clientes de red
  getIt.registerLazySingleton(() => BackendClient());

  // Base de datos local
  getIt.registerLazySingleton(() => AppDatabase(), dispose: (db) => db.close());

  // Servicios
  getIt.registerLazySingleton<NotificationService>(() => NotificationServiceImpl());
  getIt.registerLazySingleton<SessionStore>(() => SecureSessionStore());
  getIt.registerLazySingleton<SchoolCycleGate>(() => SchoolCycleLifecycleService(getIt()));

  // Repositorios
  getIt.registerLazySingleton<AppPreferences>(
    () => AppPreferencesImpl(getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<GradesRepository>(
    () => GradesRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<KardexRepository>(
    () => KardexRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<AcademicStatusRepository>(
    () => AcademicStatusRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<ReinscriptionRepository>(
    () => ReinscriptionRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<ScheduleOverridesRepository>(
    () => ScheduleOverridesRepositoryImpl(getIt()),
  );

  // AuthCubit: factory (nueva instancia por flujo de login/reauth, no
  // comparte estado entre pantallas).
  getIt.registerFactory(() => AuthCubit(getIt(), getIt(), getIt()));

  // Cubits de datos: singleton — sobreviven a los cambios de pestaña del
  // shell (ver `main_shell.dart`/`app_router.dart`, que no usan
  // `IndexedStack`, así que cada navegación reconstruye el widget). Sin
  // esto, cada cambio de pantalla recreaba el Cubit y disparaba un fetch
  // nuevo contra el SAES real. Las pantallas deben usar `BlocProvider.value`
  // (no `BlocProvider(create:...)`) para no cerrarlos al desmontarse.
  getIt.registerLazySingleton(() => ScheduleCubit(getIt(), getIt()));
  getIt.registerLazySingleton(() => CalendarCubit(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => GradesCubit(getIt(), getIt()));
  getIt.registerLazySingleton(() => KardexCubit(getIt()));
  getIt.registerLazySingleton(() => AcademicStatusCubit(getIt()));
  getIt.registerLazySingleton(() => ReinscriptionCubit(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => TasksCubit(getIt(), getIt()));
  getIt.registerLazySingleton(() => ScheduleOverridesCubit(getIt()));
}

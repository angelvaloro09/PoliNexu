import 'package:get_it/get_it.dart';
import '../../data/database/app_database.dart';
import '../../data/local/secure_session_store.dart';
import '../../data/remote/backend_client.dart';
import '../../data/repositories/app_preferences_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../data/repositories/grades_repository_impl.dart';
import '../../data/repositories/kardex_repository_impl.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/services/notification_service_impl.dart';
import '../../domain/repositories/app_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/grades_repository.dart';
import '../../domain/repositories/kardex_repository.dart';
import '../../domain/repositories/notification_service.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/session_store.dart';
import '../../domain/repositories/task_repository.dart';
import '../../presentation/blocs/auth/auth_cubit.dart';
import '../../presentation/blocs/calendar/calendar_cubit.dart';
import '../../presentation/blocs/grades/grades_cubit.dart';
import '../../presentation/blocs/kardex/kardex_cubit.dart';
import '../../presentation/blocs/schedule/schedule_cubit.dart';
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

  // Repositorios
  getIt.registerLazySingleton<AppPreferences>(
    () => AppPreferencesImpl(getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<GradesRepository>(
    () => GradesRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<KardexRepository>(
    () => KardexRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(getIt()),
  );

  // Cubits (factory: nueva instancia cada vez)
  getIt.registerFactory(() => AuthCubit(getIt(), getIt()));
  getIt.registerFactory(() => ScheduleCubit(getIt(), getIt()));
  getIt.registerFactory(() => CalendarCubit(getIt(), getIt()));
  getIt.registerFactory(() => GradesCubit(getIt(), getIt()));
  getIt.registerFactory(() => KardexCubit(getIt()));
  getIt.registerFactory(() => TasksCubit(getIt(), getIt()));
}

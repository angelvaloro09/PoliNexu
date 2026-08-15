# Skill: Flutter + BLoC — Arquitectura y Patrones

## Estructura de Archivos por Feature

Cada feature sigue esta estructura dentro de `lib/presentation/`:

```
presentation/
  blocs/
    <feature>/
      <feature>_cubit.dart      ← lógica
      <feature>_state.dart      ← estados (sealed o abstract class)
  screens/
    <feature>/
      <feature>_screen.dart     ← pantalla principal
  widgets/
    <widget_name>.dart          ← widgets reutilizables
```

---

## Patrón de Cubit

```dart
// <feature>_state.dart
abstract class FeatureState {}
class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState {
  final MyData data;
  FeatureLoaded(this.data);
}
class FeatureError extends FeatureState {
  final String message;
  FeatureError(this.message);
}

// <feature>_cubit.dart
class FeatureCubit extends Cubit<FeatureState> {
  final FeatureRepository _repo;

  FeatureCubit(this._repo) : super(FeatureInitial());

  Future<void> loadData() async {
    emit(FeatureLoading());
    try {
      final data = await _repo.getData();
      emit(FeatureLoaded(data));
    } catch (e) {
      emit(FeatureError(e.toString()));
    }
  }
}
```

## Patrón BlocConsumer en Pantallas

```dart
BlocConsumer<FeatureCubit, FeatureState>(
  listener: (context, state) {
    // Solo efectos secundarios: SnackBars, navegación, diálogos
    if (state is FeatureError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  },
  builder: (context, state) {
    return switch (state) {
      FeatureLoading() => const Center(child: CircularProgressIndicator()),
      FeatureLoaded(:final data) => MyContent(data: data),
      FeatureError(:final message) => ErrorView(message: message),
      _ => const SizedBox.shrink(),
    };
  },
)
```

---

## Drift (SQLite) — Definición de Tablas

```dart
// lib/data/database/tables/<feature>_table.dart
import 'package:drift/drift.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
```

Después de modificar tablas, correr:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## go_router — Configuración

```dart
// lib/presentation/router/app_router.dart
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
        GoRoute(path: '/grades', builder: (_, __) => const GradesScreen()),
        GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
      ],
    ),
  ],
);
```

---

## Inyección de Dependencias (get_it)

```dart
// lib/core/di/injection.dart
final getIt = GetIt.instance;

void configureDependencies() {
  // Clientes de red
  getIt.registerLazySingleton(() => SaesClient());

  // Repositorios
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );

  // Cubits (factory: nueva instancia cada vez)
  getIt.registerFactory(() => AuthCubit(getIt()));
}
```

---

## Reglas de Calidad para Flutter

1. **`const` constructors** en todos los widgets que no dependan de variables de instancia.
2. **Evitar `setState` en lógica de negocio** — solo para cambios de UI puros (e.g. toggle `_obscurePassword`).
3. **`dispose()`** todos los `TextEditingController`, `AnimationController`, etc.
4. **`key` explícito** en listas dinámicas con `ListView.builder`.
5. **Accesibilidad**: todos los `IconButton` deben tener `tooltip`.

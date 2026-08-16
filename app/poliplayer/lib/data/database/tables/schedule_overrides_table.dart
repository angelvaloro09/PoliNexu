import 'package:drift/drift.dart';

/// Color elegido por el alumno para una materia (sobre-escribe el color
/// determinístico de `subject_color.dart`). Clave: materia normalizada
/// (`.trim().toLowerCase()`, mismo criterio que `subjectColor()`).
class SubjectPreferences extends Table {
  TextColumn get subjectKey => text()();
  IntColumn get colorValue => integer().nullable()();

  @override
  Set<Column> get primaryKey => {subjectKey};
}

/// Edificio/salón editado por el alumno para una materia en un día de la
/// semana específico (ej. "los lunes, Cálculo es en el edificio 2, salón
/// 305"), sobre-escribe lo que reporta el SAES para esa combinación.
class ScheduleOverrides extends Table {
  TextColumn get subjectKey => text()();
  TextColumn get day => text()();
  TextColumn get building => text().nullable()();
  TextColumn get classroom => text().nullable()();

  @override
  Set<Column> get primaryKey => {subjectKey, day};
}

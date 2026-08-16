import 'package:drift/drift.dart';

/// Prioridad de tarea: 0 = baja, 1 = media, 2 = alta.
/// Tipo (`type`): 0 = tarea, 1 = examen, 2 = evento importante.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get type => integer().withDefault(const Constant(0))();
  TextColumn get iconKey => text().nullable()();
  BoolColumn get alarmEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get subject => text().nullable()();
}

import 'package:drift/drift.dart';

/// Última calificación conocida por materia (clave `group|subject`) — permite
/// detectar cuando el SAES publica una calificación nueva comparando contra
/// la última vez que se consultó `GradesRepository` (Fase 5: notificación de
/// "nueva calificación disponible").
class GradeSnapshots extends Table {
  TextColumn get subjectKey => text()();
  TextColumn get finalGrade => text()();

  @override
  Set<Column> get primaryKey => {subjectKey};
}

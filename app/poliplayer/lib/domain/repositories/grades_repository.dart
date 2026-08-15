import '../models/grade_entry.dart';
import '../models/remote_data.dart';

abstract class GradesRepository {
  /// Calificaciones del SAES, con caída a la copia local si la red o la
  /// sesión fallan.
  Future<RemoteData<List<GradeEntry>>> getGrades();

  /// Última "foto" de calificaciones (clave `group|subject` → nota) guardada
  /// localmente — permite detectar cuándo el SAES publica algo nuevo.
  Future<Map<String, String>> loadCachedGrades();

  Future<void> saveCachedGrades(Map<String, String> grades);
}

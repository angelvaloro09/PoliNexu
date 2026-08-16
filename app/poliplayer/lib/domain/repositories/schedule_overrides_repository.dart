/// Preferencias locales del alumno sobre su horario: color por materia y
/// edificio/salón editado para una materia en un día de la semana específico.
/// Vive sólo en el dispositivo (Drift) — no es dato del SAES ni se sincroniza
/// con el backend.
class ScheduleOverridesSnapshot {
  /// Materia normalizada (`subjectKey`) → color ARGB elegido por el alumno.
  final Map<String, int> subjectColors;

  /// (materia normalizada, día) → edificio/salón editado.
  final Map<(String, String), ({String? building, String? classroom})> sessionOverrides;

  const ScheduleOverridesSnapshot({
    this.subjectColors = const {},
    this.sessionOverrides = const {},
  });
}

abstract class ScheduleOverridesRepository {
  Stream<ScheduleOverridesSnapshot> watchOverrides();

  Future<void> setSubjectColor(String subject, int? colorValue);

  Future<void> setSessionOverride({
    required String subject,
    required String day,
    String? building,
    String? classroom,
  });
}

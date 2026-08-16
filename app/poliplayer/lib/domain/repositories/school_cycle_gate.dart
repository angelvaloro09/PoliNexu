import '../models/academic_calendar_event.dart';

/// Ciclo de vida de Horario/Calificaciones — ver `SchoolCycleLifecycleService`
/// (`data/services/`) para la implementación y el razonamiento completo.
abstract class SchoolCycleGate {
  /// Cierra el ciclo (limpia caché de Horario/Calificaciones) si "hoy" ya
  /// pasó el fin de todos los periodos conocidos en [events].
  Future<void> applyClosingGate(List<AcademicCalendarEvent> events);

  /// Reabre el ciclo (fuerza recarga de Horario/Calificaciones) si el ciclo
  /// está cerrado y "hoy" ya pasó [citaFin] (fin de la cita de reinscripción).
  Future<void> applyReopeningGate(DateTime? citaFin);
}

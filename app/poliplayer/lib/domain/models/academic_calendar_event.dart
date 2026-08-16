enum AcademicCalendarCategory {
  inicioPeriodo,
  finPeriodo,
  vacaciones,
  descansoObligatorio,
  diaPolitecnico,
  inscripcionReinscripcion,
  evaluacionOrdinaria,
  evaluacionExtraordinaria;

  static AcademicCalendarCategory fromBackendValue(String value) {
    switch (value) {
      case 'inicio_periodo':
        return AcademicCalendarCategory.inicioPeriodo;
      case 'fin_periodo':
        return AcademicCalendarCategory.finPeriodo;
      case 'vacaciones':
        return AcademicCalendarCategory.vacaciones;
      case 'descanso_obligatorio':
        return AcademicCalendarCategory.descansoObligatorio;
      case 'dia_politecnico':
        return AcademicCalendarCategory.diaPolitecnico;
      case 'inscripcion_reinscripcion':
        return AcademicCalendarCategory.inscripcionReinscripcion;
      case 'evaluacion_ordinaria':
        return AcademicCalendarCategory.evaluacionOrdinaria;
      case 'evaluacion_extraordinaria':
        return AcademicCalendarCategory.evaluacionExtraordinaria;
      default:
        throw ArgumentError('Categoría de calendario académico desconocida: $value');
    }
  }
}

class AcademicCalendarEvent {
  final String id;
  final String title;
  final AcademicCalendarCategory category;
  final DateTime startDate;
  final DateTime endDate;

  const AcademicCalendarEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    required this.endDate,
  });

  bool coversDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

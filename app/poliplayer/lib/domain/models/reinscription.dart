class ReinscriptionCreditItem {
  final String description;
  final String credits;
  final bool isTotal;

  const ReinscriptionCreditItem({
    required this.description,
    required this.credits,
    this.isTotal = false,
  });
}

/// Datos de `fichas_reinscripcion.aspx`: la cita de reinscripción del alumno
/// (dispara el repoblado de Horario/Calificaciones, ver `SchoolCycleGate`)
/// más créditos/trayectoria del plan de estudios.
class Reinscription {
  final String average;
  final String failedSubjectsCount;
  final DateTime? appointmentStart;
  final DateTime? appointmentEnd;
  final String totalCredits;
  final String maxLoad;
  final String avgLoad;
  final String minLoad;
  final String minPeriods;
  final String maxPeriods;
  final String creditsEarned;
  final String creditsMissing;
  final String periodsTaken;
  final String periodsAvailable;
  final String authorizedLoad;
  final List<ReinscriptionCreditItem> failedCreditsBreakdown;

  const Reinscription({
    required this.average,
    required this.failedSubjectsCount,
    required this.appointmentStart,
    required this.appointmentEnd,
    required this.totalCredits,
    required this.maxLoad,
    required this.avgLoad,
    required this.minLoad,
    required this.minPeriods,
    required this.maxPeriods,
    required this.creditsEarned,
    required this.creditsMissing,
    required this.periodsTaken,
    required this.periodsAvailable,
    required this.authorizedLoad,
    required this.failedCreditsBreakdown,
  });

  /// "Hoy" cae dentro de la ventana de la cita.
  bool coversDay(DateTime day) {
    final start = appointmentStart;
    final end = appointmentEnd;
    if (start == null || end == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !d.isBefore(startDay) && !d.isAfter(endDay);
  }
}

import '../../domain/models/academic_calendar_event.dart';

/// Rangos [inicioPeriodo, finPeriodo] del ciclo escolar, deducidos del
/// calendario IPN (cada `inicioPeriodo` se empareja con el `finPeriodo` más
/// próximo posterior). El Horario del SAES es una tabla fija por día de la
/// semana — no sabe de vacaciones — así que esto es lo único que permite
/// ocultar clases fuera de ciclo (ver también `isWithinSchoolCycle`) y
/// detectar cuándo cerrar los datos del ciclo (`SchoolCycleLifecycleService`).
List<(DateTime start, DateTime end)> schoolCycleRanges(List<AcademicCalendarEvent> events) {
  final starts = events
      .where((e) => e.category == AcademicCalendarCategory.inicioPeriodo)
      .map((e) => e.startDate)
      .toList()
    ..sort();
  final ends = events
      .where((e) => e.category == AcademicCalendarCategory.finPeriodo)
      .map((e) => e.startDate)
      .toList()
    ..sort();
  return [
    for (final start in starts)
      (
        start,
        ends.firstWhere(
          (e) => e.isAfter(start),
          orElse: () => start.add(const Duration(days: 200)),
        ),
      ),
  ];
}

/// Si no hay eventos `inicioPeriodo`/`finPeriodo` cargados todavía (o el
/// calendario aún no llegó), no hay base para restringir nada — se deja ver
/// el horario completo en vez de ocultarlo por datos ausentes.
bool isWithinSchoolCycle(List<AcademicCalendarEvent> events, DateTime day) {
  final ranges = schoolCycleRanges(events);
  if (ranges.isEmpty) return true;
  final d = DateTime(day.year, day.month, day.day);
  for (final (start, end) in ranges) {
    if (!d.isBefore(start) && !d.isAfter(end)) return true;
  }
  return false;
}

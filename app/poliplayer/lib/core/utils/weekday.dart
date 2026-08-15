/// Etiqueta en español de un día de la semana tal como la usa el SAES en el
/// Horario (`ScheduleSession.day`: "Lunes".."Viernes"). `null` para
/// sábado/domingo — el SAES no lista clases esos días.
String? spanishWeekdayLabel(DateTime date) => switch (date.weekday) {
      DateTime.monday => 'Lunes',
      DateTime.tuesday => 'Martes',
      DateTime.wednesday => 'Miércoles',
      DateTime.thursday => 'Jueves',
      DateTime.friday => 'Viernes',
      _ => null,
    };

/// Inverso de [spanishWeekdayLabel]: de la etiqueta que usa
/// `ScheduleSession.day` a `DateTime.weekday` (1 = lunes .. 7 = domingo).
int? weekdayFromSpanishLabel(String label) => switch (label) {
      'Lunes' => DateTime.monday,
      'Martes' => DateTime.tuesday,
      'Miércoles' => DateTime.wednesday,
      'Jueves' => DateTime.thursday,
      'Viernes' => DateTime.friday,
      _ => null,
    };

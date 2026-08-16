import '../../../domain/models/academic_calendar_event.dart';

sealed class CalendarState {
  const CalendarState();
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  final List<AcademicCalendarEvent> events;
  final DateTime fetchedAt;
  final bool fromCache;

  const CalendarLoaded(this.events, {required this.fetchedAt, this.fromCache = false});
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError(this.message);
}

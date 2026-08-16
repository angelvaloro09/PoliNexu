import '../models/academic_calendar_event.dart';
import '../models/remote_data.dart';

abstract class CalendarRepository {
  /// Calendario académico institucional del IPN. Dato público (sin sesión);
  /// si la red falla pero hay una copia local, la devuelve marcada con
  /// `fromCache: true` en vez de lanzar.
  Future<RemoteData<List<AcademicCalendarEvent>>> getAcademicCalendar();

  /// Lee sólo la copia local (sin red), o `null` si nunca se cargó.
  Future<RemoteData<List<AcademicCalendarEvent>>?> getCachedOnly();
}

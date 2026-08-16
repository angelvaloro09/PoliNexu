import '../models/remote_data.dart';
import '../models/schedule_entry.dart';

abstract class ScheduleRepository {
  /// Horario del SAES. Si la red o la sesión fallan pero hay una copia local,
  /// la devuelve marcada con `fromCache: true` en vez de lanzar.
  Future<RemoteData<List<ScheduleEntry>>> getSchedule();

  /// Lee sólo la copia local (sin red), o `null` si nunca se cargó. Sirve
  /// para pintar de inmediato con lo último conocido mientras `getSchedule()`
  /// trae datos frescos en segundo plano.
  Future<RemoteData<List<ScheduleEntry>>?> getCachedOnly();
}

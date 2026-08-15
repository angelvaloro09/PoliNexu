import '../models/remote_data.dart';
import '../models/schedule_entry.dart';

abstract class ScheduleRepository {
  /// Horario del SAES. Si la red o la sesión fallan pero hay una copia local,
  /// la devuelve marcada con `fromCache: true` en vez de lanzar.
  Future<RemoteData<List<ScheduleEntry>>> getSchedule();
}

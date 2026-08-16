import '../../domain/models/remote_data.dart';
import '../../domain/models/schedule_entry.dart';
import '../../domain/models/session_required_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/notification_service.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final BackendClient _client;
  final AuthRepository _authRepository;
  final AppDatabase _db;
  final NotificationService _notificationService;

  ScheduleRepositoryImpl(this._client, this._authRepository, this._db, this._notificationService);

  @override
  Future<RemoteData<List<ScheduleEntry>>> getSchedule() async {
    // Fin de ciclo: `SchoolCycleLifecycleService` ya limpió la caché y dejó
    // el gate cerrado — no hay nada que mostrar hasta que la cita de
    // reinscripción del alumno lo reabra.
    if (await _db.readFlag(CycleFlags.gate) == 'closed') {
      return RemoteData.fresh(const []);
    }

    try {
      final token = _authRepository.currentSessionToken;
      if (token == null) {
        throw SessionExpiredException('No hay una sesión activa. Inicia sesión primero.');
      }

      final dtos = await _client.getSchedule(token);
      await _db.saveRemoteCache(
        RemoteCacheKeys.schedule,
        dtos.map((e) => e.toJson()).toList(),
      );
      return RemoteData.fresh(_toDomain(dtos));
    } on BackendException catch (e) {
      final expired = e is SessionExpiredException;
      if (expired) await _notificationService.notifySessionExpired();

      // Sesión muerta o sin red: mejor el horario de ayer que una pantalla
      // vacía. Si tampoco hay caché, pedir sesión explícitamente en vez de
      // dejar escapar el tipo de excepción de `data/`.
      final cached = await _db.loadRemoteCache(RemoteCacheKeys.schedule);
      if (cached == null) {
        if (expired) throw const SessionRequiredException('Inicia sesión para ver tu horario.');
        rethrow;
      }

      final dtos = (cached.payload as List)
          .map((e) => ScheduleEntryDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return RemoteData(
        value: _toDomain(dtos),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
        sessionExpired: expired,
      );
    }
  }

  @override
  Future<RemoteData<List<ScheduleEntry>>?> getCachedOnly() async {
    final cached = await _db.loadRemoteCache(RemoteCacheKeys.schedule);
    if (cached == null) return null;

    final dtos = (cached.payload as List)
        .map((e) => ScheduleEntryDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return RemoteData(
      value: _toDomain(dtos),
      fetchedAt: cached.fetchedAt,
      fromCache: true,
    );
  }

  List<ScheduleEntry> _toDomain(List<ScheduleEntryDto> dtos) => dtos
      .map((e) => ScheduleEntry(
            group: e.group,
            code: e.code,
            subject: e.subject,
            teachers: e.teachers,
            sessions: e.sessions
                .map((s) => ScheduleSession(
                      day: s.day,
                      startTime: s.startTime,
                      endTime: s.endTime,
                      building: s.building,
                      classroom: s.classroom,
                    ))
                .toList(),
          ))
      .toList();
}

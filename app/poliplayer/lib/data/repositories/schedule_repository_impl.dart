import '../../domain/models/remote_data.dart';
import '../../domain/models/schedule_entry.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final BackendClient _client;
  final AuthRepository _authRepository;
  final AppDatabase _db;

  ScheduleRepositoryImpl(this._client, this._authRepository, this._db);

  @override
  Future<RemoteData<List<ScheduleEntry>>> getSchedule() async {
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
    } on BackendException {
      // Sesión muerta o sin red: mejor el horario de ayer que una pantalla
      // vacía. Si tampoco hay caché, que el error suba tal cual.
      final cached = await _db.loadRemoteCache(RemoteCacheKeys.schedule);
      if (cached == null) rethrow;

      final dtos = (cached.payload as List)
          .map((e) => ScheduleEntryDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return RemoteData(
        value: _toDomain(dtos),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  List<ScheduleEntry> _toDomain(List<ScheduleEntryDto> dtos) => dtos
      .map((e) => ScheduleEntry(
            group: e.group,
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

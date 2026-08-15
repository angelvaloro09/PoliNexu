import '../../domain/models/grade_entry.dart';
import '../../domain/models/remote_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/grades_repository.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class GradesRepositoryImpl implements GradesRepository {
  final BackendClient _client;
  final AuthRepository _authRepository;
  final AppDatabase _db;

  GradesRepositoryImpl(this._client, this._authRepository, this._db);

  @override
  Future<RemoteData<List<GradeEntry>>> getGrades() async {
    try {
      final token = _authRepository.currentSessionToken;
      if (token == null) {
        throw SessionExpiredException('No hay una sesión activa. Inicia sesión primero.');
      }

      final dtos = await _client.getGrades(token);
      await _db.saveRemoteCache(
        RemoteCacheKeys.grades,
        dtos.map((e) => e.toJson()).toList(),
      );
      return RemoteData.fresh(_toDomain(dtos));
    } on BackendException {
      final cached = await _db.loadRemoteCache(RemoteCacheKeys.grades);
      if (cached == null) rethrow;

      final dtos = (cached.payload as List)
          .map((e) => GradeEntryDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return RemoteData(
        value: _toDomain(dtos),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  @override
  Future<Map<String, String>> loadCachedGrades() => _db.loadGradeSnapshots();

  @override
  Future<void> saveCachedGrades(Map<String, String> grades) => _db.saveGradeSnapshots(grades);

  List<GradeEntry> _toDomain(List<GradeEntryDto> dtos) => dtos
      .map((e) => GradeEntry(
            group: e.group,
            subject: e.subject,
            partial1: e.partial1,
            partial2: e.partial2,
            partial3: e.partial3,
            extraordinary: e.extraordinary,
            final_: e.finalGrade,
          ))
      .toList();
}

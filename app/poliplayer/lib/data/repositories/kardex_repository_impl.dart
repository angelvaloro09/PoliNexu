import '../../domain/models/kardex.dart';
import '../../domain/models/remote_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/kardex_repository.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class KardexRepositoryImpl implements KardexRepository {
  final BackendClient _client;
  final AuthRepository _authRepository;
  final AppDatabase _db;

  KardexRepositoryImpl(this._client, this._authRepository, this._db);

  @override
  Future<RemoteData<Kardex>> getKardex() async {
    try {
      final token = _authRepository.currentSessionToken;
      if (token == null) {
        throw SessionExpiredException('No hay una sesión activa. Inicia sesión primero.');
      }

      final dto = await _client.getKardex(token);
      await _db.saveRemoteCache(RemoteCacheKeys.kardex, dto.toJson());
      return RemoteData.fresh(_toDomain(dto));
    } on BackendException {
      final cached = await _db.loadRemoteCache(RemoteCacheKeys.kardex);
      if (cached == null) rethrow;

      final dto = KardexDto.fromJson(cached.payload as Map<String, dynamic>);
      return RemoteData(
        value: _toDomain(dto),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  Kardex _toDomain(KardexDto dto) => Kardex(
        career: dto.career,
        studyPlan: dto.studyPlan,
        average: dto.average,
        semesters: dto.semesters
            .map((sem) => KardexSemester(
                  label: sem.label,
                  subjects: sem.subjects
                      .map((s) => KardexSubject(
                            key: s.key,
                            subject: s.subject,
                            date: s.date,
                            period: s.period,
                            examType: s.examType,
                            grade: s.grade,
                          ))
                      .toList(),
                ))
            .toList(),
      );
}

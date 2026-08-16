import '../../domain/models/academic_status.dart';
import '../../domain/models/remote_data.dart';
import '../../domain/models/session_required_exception.dart';
import '../../domain/repositories/academic_status_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/notification_service.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class AcademicStatusRepositoryImpl implements AcademicStatusRepository {
  final BackendClient _client;
  final AuthRepository _authRepository;
  final AppDatabase _db;
  final NotificationService _notificationService;

  AcademicStatusRepositoryImpl(
    this._client,
    this._authRepository,
    this._db,
    this._notificationService,
  );

  @override
  Future<RemoteData<AcademicStatus>> getAcademicStatus() async {
    try {
      final token = _authRepository.currentSessionToken;
      if (token == null) {
        throw SessionExpiredException('No hay una sesión activa. Inicia sesión primero.');
      }

      final dto = await _client.getAcademicStatus(token);
      await _db.saveRemoteCache(RemoteCacheKeys.academicStatus, dto.toJson());
      return RemoteData.fresh(_toDomain(dto));
    } on BackendException catch (e) {
      final expired = e is SessionExpiredException;
      if (expired) await _notificationService.notifySessionExpired();

      final cached = await _db.loadRemoteCache(RemoteCacheKeys.academicStatus);
      if (cached == null) {
        if (expired) {
          throw const SessionRequiredException('Inicia sesión para ver tu estado académico.');
        }
        rethrow;
      }

      final dto = AcademicStatusDto.fromJson(cached.payload as Map<String, dynamic>);
      return RemoteData(
        value: _toDomain(dto),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
        sessionExpired: expired,
      );
    }
  }

  @override
  Future<RemoteData<AcademicStatus>?> getCachedOnly() async {
    final cached = await _db.loadRemoteCache(RemoteCacheKeys.academicStatus);
    if (cached == null) return null;

    final dto = AcademicStatusDto.fromJson(cached.payload as Map<String, dynamic>);
    return RemoteData(value: _toDomain(dto), fetchedAt: cached.fetchedAt, fromCache: true);
  }

  AcademicStatus _toDomain(AcademicStatusDto dto) => AcademicStatus(
        failed: dto.failed.map(_subjectToDomain).toList(),
        notTaken: dto.notTaken.map(_subjectToDomain).toList(),
        outOfSequence: dto.outOfSequence.map(_subjectToDomain).toList(),
      );

  AcademicStatusSubject _subjectToDomain(AcademicStatusSubjectDto dto) => AcademicStatusSubject(
        code: dto.code,
        subject: dto.subject,
        period: dto.period,
        times: dto.times,
      );
}

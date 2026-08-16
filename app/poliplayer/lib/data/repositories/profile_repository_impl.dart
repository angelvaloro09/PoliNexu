import '../../domain/models/profile.dart';
import '../../domain/models/remote_data.dart';
import '../../domain/models/session_required_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/notification_service.dart';
import '../../domain/repositories/profile_repository.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final BackendClient _client;
  final AuthRepository _authRepository;
  final AppDatabase _db;
  final NotificationService _notificationService;

  ProfileRepositoryImpl(this._client, this._authRepository, this._db, this._notificationService);

  @override
  Future<RemoteData<Profile>> getProfile() async {
    try {
      final token = _authRepository.currentSessionToken;
      if (token == null) {
        throw SessionExpiredException('No hay una sesión activa. Inicia sesión primero.');
      }

      final dto = await _client.getProfile(token);
      await _db.saveRemoteCache(RemoteCacheKeys.profile, dto.toJson());
      return RemoteData.fresh(_toDomain(dto));
    } on BackendException catch (e) {
      final expired = e is SessionExpiredException;
      if (expired) await _notificationService.notifySessionExpired();

      final cached = await _db.loadRemoteCache(RemoteCacheKeys.profile);
      if (cached == null) {
        if (expired) throw const SessionRequiredException('Inicia sesión para ver tu perfil.');
        rethrow;
      }

      final dto = ProfileDto.fromJson(cached.payload as Map<String, dynamic>);
      return RemoteData(
        value: _toDomain(dto),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
        sessionExpired: expired,
      );
    }
  }

  @override
  Future<RemoteData<Profile>?> getCachedOnly() async {
    final cached = await _db.loadRemoteCache(RemoteCacheKeys.profile);
    if (cached == null) return null;

    final dto = ProfileDto.fromJson(cached.payload as Map<String, dynamic>);
    return RemoteData(value: _toDomain(dto), fetchedAt: cached.fetchedAt, fromCache: true);
  }

  Profile _toDomain(ProfileDto dto) =>
      Profile(boleta: dto.boleta, nombre: dto.nombre, plantel: dto.plantel);
}

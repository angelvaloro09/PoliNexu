import '../../domain/models/reinscription.dart';
import '../../domain/models/remote_data.dart';
import '../../domain/models/session_required_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/notification_service.dart';
import '../../domain/repositories/reinscription_repository.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class ReinscriptionRepositoryImpl implements ReinscriptionRepository {
  final BackendClient _client;
  final AuthRepository _authRepository;
  final AppDatabase _db;
  final NotificationService _notificationService;

  ReinscriptionRepositoryImpl(
    this._client,
    this._authRepository,
    this._db,
    this._notificationService,
  );

  @override
  Future<RemoteData<Reinscription>> getReinscription() async {
    try {
      final token = _authRepository.currentSessionToken;
      if (token == null) {
        throw SessionExpiredException('No hay una sesión activa. Inicia sesión primero.');
      }

      final dto = await _client.getReinscription(token);
      await _db.saveRemoteCache(RemoteCacheKeys.reinscription, dto.toJson());
      return RemoteData.fresh(_toDomain(dto));
    } on BackendException catch (e) {
      final expired = e is SessionExpiredException;
      if (expired) await _notificationService.notifySessionExpired();

      final cached = await _db.loadRemoteCache(RemoteCacheKeys.reinscription);
      if (cached == null) {
        if (expired) {
          throw const SessionRequiredException('Inicia sesión para ver tu reinscripción.');
        }
        rethrow;
      }

      final dto = ReinscriptionDto.fromJson(cached.payload as Map<String, dynamic>);
      return RemoteData(
        value: _toDomain(dto),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
        sessionExpired: expired,
      );
    }
  }

  @override
  Future<RemoteData<Reinscription>?> getCachedOnly() async {
    final cached = await _db.loadRemoteCache(RemoteCacheKeys.reinscription);
    if (cached == null) return null;

    final dto = ReinscriptionDto.fromJson(cached.payload as Map<String, dynamic>);
    return RemoteData(value: _toDomain(dto), fetchedAt: cached.fetchedAt, fromCache: true);
  }

  Reinscription _toDomain(ReinscriptionDto dto) => Reinscription(
        average: dto.average,
        failedSubjectsCount: dto.failedSubjectsCount,
        appointmentStart: dto.appointmentStart == null ? null : DateTime.tryParse(dto.appointmentStart!),
        appointmentEnd: dto.appointmentEnd == null ? null : DateTime.tryParse(dto.appointmentEnd!),
        totalCredits: dto.totalCredits,
        maxLoad: dto.maxLoad,
        avgLoad: dto.avgLoad,
        minLoad: dto.minLoad,
        minPeriods: dto.minPeriods,
        maxPeriods: dto.maxPeriods,
        creditsEarned: dto.creditsEarned,
        creditsMissing: dto.creditsMissing,
        periodsTaken: dto.periodsTaken,
        periodsAvailable: dto.periodsAvailable,
        authorizedLoad: dto.authorizedLoad,
        failedCreditsBreakdown: dto.failedCreditsBreakdown
            .map((e) => ReinscriptionCreditItem(description: e.description, credits: e.credits))
            .toList(),
      );
}

import '../models/profile.dart';
import '../models/remote_data.dart';

abstract class ProfileRepository {
  /// Datos personales del SAES, con caída a la copia local si la red o la
  /// sesión fallan.
  Future<RemoteData<Profile>> getProfile();

  /// Lee sólo la copia local (sin red), o `null` si nunca se cargó.
  Future<RemoteData<Profile>?> getCachedOnly();
}

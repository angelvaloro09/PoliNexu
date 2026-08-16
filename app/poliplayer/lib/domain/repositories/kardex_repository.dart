import '../models/kardex.dart';
import '../models/remote_data.dart';

abstract class KardexRepository {
  /// Kárdex del SAES, con caída a la copia local si la red o la sesión fallan.
  Future<RemoteData<Kardex>> getKardex();

  /// Lee sólo la copia local (sin red), o `null` si nunca se cargó. Sirve
  /// para pintar de inmediato con lo último conocido mientras `getKardex()`
  /// trae datos frescos en segundo plano.
  Future<RemoteData<Kardex>?> getCachedOnly();
}

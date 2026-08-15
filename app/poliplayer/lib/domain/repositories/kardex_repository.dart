import '../models/kardex.dart';
import '../models/remote_data.dart';

abstract class KardexRepository {
  /// Kárdex del SAES, con caída a la copia local si la red o la sesión fallan.
  Future<RemoteData<Kardex>> getKardex();
}

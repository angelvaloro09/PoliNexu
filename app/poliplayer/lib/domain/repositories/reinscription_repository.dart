import '../models/reinscription.dart';
import '../models/remote_data.dart';

abstract class ReinscriptionRepository {
  Future<RemoteData<Reinscription>> getReinscription();
  Future<RemoteData<Reinscription>?> getCachedOnly();
}

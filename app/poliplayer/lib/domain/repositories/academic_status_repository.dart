import '../models/academic_status.dart';
import '../models/remote_data.dart';

abstract class AcademicStatusRepository {
  Future<RemoteData<AcademicStatus>> getAcademicStatus();
  Future<RemoteData<AcademicStatus>?> getCachedOnly();
}

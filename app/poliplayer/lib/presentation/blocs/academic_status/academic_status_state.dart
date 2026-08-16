import '../../../domain/models/academic_status.dart';

sealed class AcademicStatusState {
  const AcademicStatusState();
}

class AcademicStatusInitial extends AcademicStatusState {
  const AcademicStatusInitial();
}

class AcademicStatusLoading extends AcademicStatusState {
  const AcademicStatusLoading();
}

class AcademicStatusLoaded extends AcademicStatusState {
  final AcademicStatus status;
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const AcademicStatusLoaded(
    this.status, {
    required this.fetchedAt,
    this.fromCache = false,
    this.sessionExpired = false,
  });
}

class AcademicStatusError extends AcademicStatusState {
  final String message;
  final bool sessionRequired;
  const AcademicStatusError(this.message, {this.sessionRequired = false});
}

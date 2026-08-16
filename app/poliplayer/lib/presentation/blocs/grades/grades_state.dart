import '../../../domain/models/grade_entry.dart';

sealed class GradesState {
  const GradesState();
}

class GradesInitial extends GradesState {
  const GradesInitial();
}

class GradesLoading extends GradesState {
  const GradesLoading();
}

class GradesLoaded extends GradesState {
  final List<GradeEntry> entries;
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const GradesLoaded(
    this.entries, {
    required this.fetchedAt,
    this.fromCache = false,
    this.sessionExpired = false,
  });
}

class GradesError extends GradesState {
  final String message;
  final bool sessionRequired;
  const GradesError(this.message, {this.sessionRequired = false});
}

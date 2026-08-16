import '../../../domain/models/schedule_entry.dart';

sealed class ScheduleState {
  const ScheduleState();
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  final List<ScheduleEntry> entries;

  /// Cuándo se bajó del SAES. Con [fromCache] `true` puede ser de hace días.
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const ScheduleLoaded(
    this.entries, {
    required this.fetchedAt,
    this.fromCache = false,
    this.sessionExpired = false,
  });
}

class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError(this.message);
}

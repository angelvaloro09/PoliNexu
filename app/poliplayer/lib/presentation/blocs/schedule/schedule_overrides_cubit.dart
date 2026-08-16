import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/schedule_overrides_repository.dart';

class ScheduleOverridesCubit extends Cubit<ScheduleOverridesSnapshot> {
  final ScheduleOverridesRepository _repository;
  StreamSubscription<ScheduleOverridesSnapshot>? _subscription;

  ScheduleOverridesCubit(this._repository) : super(const ScheduleOverridesSnapshot()) {
    _subscription = _repository.watchOverrides().listen(emit);
  }

  Future<void> setSubjectColor(String subject, int? colorValue) =>
      _repository.setSubjectColor(subject, colorValue);

  Future<void> setSessionOverride({
    required String subject,
    required String day,
    String? building,
    String? classroom,
  }) =>
      _repository.setSessionOverride(
        subject: subject,
        day: day,
        building: building,
        classroom: classroom,
      );

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

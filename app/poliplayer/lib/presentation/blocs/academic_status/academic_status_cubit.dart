import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/session_required_exception.dart';
import '../../../domain/repositories/academic_status_repository.dart';
import 'academic_status_state.dart';

class AcademicStatusCubit extends Cubit<AcademicStatusState> {
  final AcademicStatusRepository _repository;

  AcademicStatusCubit(this._repository) : super(const AcademicStatusInitial());

  Future<void> loadAcademicStatus({bool force = false}) async {
    if (!force && state is AcademicStatusLoaded) return;

    final cachedState = state;
    if (cachedState is! AcademicStatusLoaded) {
      final cached = await _repository.getCachedOnly();
      if (cached != null) {
        emit(AcademicStatusLoaded(cached.value, fetchedAt: cached.fetchedAt, fromCache: true));
      } else {
        emit(const AcademicStatusLoading());
      }
    }

    try {
      final data = await _repository.getAcademicStatus();
      emit(AcademicStatusLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
        sessionExpired: data.sessionExpired,
      ));
    } catch (e) {
      if (state is! AcademicStatusLoaded) {
        emit(AcademicStatusError(e.toString(), sessionRequired: e is SessionRequiredException));
      }
    }
  }
}

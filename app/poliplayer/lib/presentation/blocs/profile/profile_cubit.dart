import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/session_required_exception.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository) : super(const ProfileInitial());

  Future<void> loadProfile({bool force = false}) async {
    if (!force && state is ProfileLoaded) return;

    final cachedState = state;
    if (cachedState is! ProfileLoaded) {
      final cached = await _repository.getCachedOnly();
      if (cached != null) {
        emit(ProfileLoaded(cached.value, fetchedAt: cached.fetchedAt, fromCache: true));
      } else {
        emit(const ProfileLoading());
      }
    }

    try {
      final data = await _repository.getProfile();
      emit(ProfileLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
        sessionExpired: data.sessionExpired,
      ));
    } catch (e) {
      if (state is! ProfileLoaded) {
        emit(ProfileError(e.toString(), sessionRequired: e is SessionRequiredException));
      }
    }
  }
}

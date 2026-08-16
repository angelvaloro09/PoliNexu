import '../../../domain/models/profile.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final Profile profile;
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const ProfileLoaded(
    this.profile, {
    required this.fetchedAt,
    this.fromCache = false,
    this.sessionExpired = false,
  });
}

class ProfileError extends ProfileState {
  final String message;
  final bool sessionRequired;
  const ProfileError(this.message, {this.sessionRequired = false});
}

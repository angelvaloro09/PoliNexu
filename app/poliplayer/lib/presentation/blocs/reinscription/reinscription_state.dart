import '../../../domain/models/reinscription.dart';

sealed class ReinscriptionState {
  const ReinscriptionState();
}

class ReinscriptionInitial extends ReinscriptionState {
  const ReinscriptionInitial();
}

class ReinscriptionLoading extends ReinscriptionState {
  const ReinscriptionLoading();
}

class ReinscriptionLoaded extends ReinscriptionState {
  final Reinscription reinscription;
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const ReinscriptionLoaded(
    this.reinscription, {
    required this.fetchedAt,
    this.fromCache = false,
    this.sessionExpired = false,
  });
}

class ReinscriptionError extends ReinscriptionState {
  final String message;
  final bool sessionRequired;
  const ReinscriptionError(this.message, {this.sessionRequired = false});
}

import '../../../domain/models/kardex.dart';

sealed class KardexState {
  const KardexState();
}

class KardexInitial extends KardexState {
  const KardexInitial();
}

class KardexLoading extends KardexState {
  const KardexLoading();
}

class KardexLoaded extends KardexState {
  final Kardex kardex;
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const KardexLoaded(
    this.kardex, {
    required this.fetchedAt,
    this.fromCache = false,
    this.sessionExpired = false,
  });
}

class KardexError extends KardexState {
  final String message;
  final bool sessionRequired;
  const KardexError(this.message, {this.sessionRequired = false});
}

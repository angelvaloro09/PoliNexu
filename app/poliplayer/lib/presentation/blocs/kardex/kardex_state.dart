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

  const KardexLoaded(this.kardex, {required this.fetchedAt, this.fromCache = false});
}

class KardexError extends KardexState {
  final String message;
  const KardexError(this.message);
}

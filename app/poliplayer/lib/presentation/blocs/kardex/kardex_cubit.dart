import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/session_required_exception.dart';
import '../../../domain/repositories/kardex_repository.dart';
import 'kardex_state.dart';

class KardexCubit extends Cubit<KardexState> {
  final KardexRepository _repository;

  KardexCubit(this._repository) : super(const KardexInitial());

  Future<void> loadKardex({bool force = false}) async {
    if (!force && state is KardexLoaded) return;

    final cachedState = state;
    if (cachedState is! KardexLoaded) {
      final cached = await _repository.getCachedOnly();
      if (cached != null) {
        emit(KardexLoaded(cached.value, fetchedAt: cached.fetchedAt, fromCache: true));
      } else {
        emit(const KardexLoading());
      }
    }

    try {
      final data = await _repository.getKardex();
      emit(KardexLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
        sessionExpired: data.sessionExpired,
      ));
    } catch (e) {
      if (state is! KardexLoaded) {
        emit(KardexError(e.toString(), sessionRequired: e is SessionRequiredException));
      }
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/kardex_repository.dart';
import 'kardex_state.dart';

class KardexCubit extends Cubit<KardexState> {
  final KardexRepository _repository;

  KardexCubit(this._repository) : super(const KardexInitial());

  Future<void> loadKardex() async {
    emit(const KardexLoading());
    try {
      final data = await _repository.getKardex();
      emit(KardexLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
      ));
    } catch (e) {
      emit(KardexError(e.toString()));
    }
  }
}

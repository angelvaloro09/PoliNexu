import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/session_required_exception.dart';
import '../../../domain/repositories/notification_service.dart';
import '../../../domain/repositories/reinscription_repository.dart';
import '../../../domain/repositories/school_cycle_gate.dart';
import 'reinscription_state.dart';

class ReinscriptionCubit extends Cubit<ReinscriptionState> {
  final ReinscriptionRepository _repository;
  final NotificationService _notificationService;
  final SchoolCycleGate _cycleGate;

  ReinscriptionCubit(this._repository, this._notificationService, this._cycleGate)
      : super(const ReinscriptionInitial());

  Future<void> loadReinscription({bool force = false}) async {
    if (!force && state is ReinscriptionLoaded) return;

    final cachedState = state;
    if (cachedState is! ReinscriptionLoaded) {
      final cached = await _repository.getCachedOnly();
      if (cached != null) {
        emit(ReinscriptionLoaded(cached.value, fetchedAt: cached.fetchedAt, fromCache: true));
      } else {
        emit(const ReinscriptionLoading());
      }
    }

    try {
      final data = await _repository.getReinscription();

      // Sólo con datos frescos: la alarma y el gate de repoblado dependen de
      // la cita real, no de una copia vieja en caché.
      if (!data.fromCache) {
        final start = data.value.appointmentStart;
        if (start != null) {
          await _notificationService.scheduleReinscriptionReminder(start);
        }
        await _cycleGate.applyReopeningGate(data.value.appointmentEnd);
      }

      emit(ReinscriptionLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
        sessionExpired: data.sessionExpired,
      ));
    } catch (e) {
      if (state is! ReinscriptionLoaded) {
        emit(ReinscriptionError(e.toString(), sessionRequired: e is SessionRequiredException));
      }
    }
  }
}

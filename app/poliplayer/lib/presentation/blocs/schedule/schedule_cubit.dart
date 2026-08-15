import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/notification_service.dart';
import '../../../domain/repositories/schedule_repository.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;
  final NotificationService _notificationService;

  ScheduleCubit(this._repository, this._notificationService) : super(const ScheduleInitial());

  Future<void> loadSchedule() async {
    emit(const ScheduleLoading());
    try {
      final data = await _repository.getSchedule();

      // Las alarmas sólo se reprograman con datos frescos: reprogramarlas
      // desde la caché repetiría el mismo lote en cada arranque sin aportar
      // nada (y `scheduleClassAlarms` cancela y recrea el rango completo).
      if (!data.fromCache) {
        await _notificationService.scheduleClassAlarms(data.value);
      }

      emit(ScheduleLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
      ));
    } catch (e) {
      emit(ScheduleError(e.toString()));
    }
  }
}

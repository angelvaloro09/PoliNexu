import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/notification_service.dart';
import '../../../domain/repositories/schedule_repository.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;
  final NotificationService _notificationService;

  ScheduleCubit(this._repository, this._notificationService) : super(const ScheduleInitial());

  Future<void> loadSchedule({bool force = false}) async {
    // El Cubit es un singleton compartido entre pantallas (ver injection.dart):
    // sin esta guarda, cada vez que una pantalla se reconstruye y vuelve a
    // llamar `..loadSchedule()` se repetiría el fetch contra el SAES real,
    // aunque los datos ya estén cargados. `force` lo usan pull-to-refresh y
    // "reintentar".
    if (!force && state is ScheduleLoaded) return;

    final cachedState = state;
    if (cachedState is! ScheduleLoaded) {
      final cached = await _repository.getCachedOnly();
      if (cached != null) {
        emit(ScheduleLoaded(cached.value, fetchedAt: cached.fetchedAt, fromCache: true));
      } else {
        emit(const ScheduleLoading());
      }
    }

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
        sessionExpired: data.sessionExpired,
      ));
    } catch (e) {
      // Si ya se pintó algo desde caché arriba, mejor dejarlo visible que
      // taparlo con un error — el usuario sigue viendo su horario aunque la
      // red haya fallado.
      if (state is! ScheduleLoaded) emit(ScheduleError(e.toString()));
    }
  }
}

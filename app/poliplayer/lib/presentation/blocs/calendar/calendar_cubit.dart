import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/calendar_repository.dart';
import '../../../domain/repositories/notification_service.dart';
import '../../../domain/repositories/school_cycle_gate.dart';
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarRepository _repository;
  final NotificationService _notificationService;
  final SchoolCycleGate _cycleGate;

  CalendarCubit(this._repository, this._notificationService, this._cycleGate)
      : super(const CalendarInitial());

  Future<void> loadAcademicCalendar({bool force = false}) async {
    if (!force && state is CalendarLoaded) return;

    final cachedState = state;
    if (cachedState is! CalendarLoaded) {
      final cached = await _repository.getCachedOnly();
      if (cached != null) {
        emit(CalendarLoaded(cached.value, fetchedAt: cached.fetchedAt, fromCache: true));
      } else {
        emit(const CalendarLoading());
      }
    }

    try {
      final data = await _repository.getAcademicCalendar();

      // Mismo criterio que las alarmas de clase: sólo reprogramar avisos con
      // datos frescos, para no repetir el mismo lote en cada arranque desde caché.
      if (!data.fromCache) {
        await _notificationService.scheduleAcademicCalendarNotifications(data.value);
      }

      await _cycleGate.applyClosingGate(data.value);

      emit(CalendarLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
      ));
    } catch (e) {
      if (state is! CalendarLoaded) emit(CalendarError(e.toString()));
    }
  }
}

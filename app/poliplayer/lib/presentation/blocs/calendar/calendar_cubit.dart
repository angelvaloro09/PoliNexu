import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/calendar_repository.dart';
import '../../../domain/repositories/notification_service.dart';
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarRepository _repository;
  final NotificationService _notificationService;

  CalendarCubit(this._repository, this._notificationService) : super(const CalendarInitial());

  Future<void> loadAcademicCalendar() async {
    emit(const CalendarLoading());
    try {
      final data = await _repository.getAcademicCalendar();

      // Mismo criterio que las alarmas de clase: sólo reprogramar avisos con
      // datos frescos, para no repetir el mismo lote en cada arranque desde caché.
      if (!data.fromCache) {
        await _notificationService.scheduleAcademicCalendarNotifications(data.value);
      }

      emit(CalendarLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
      ));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }
}

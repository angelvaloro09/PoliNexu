import '../models/academic_calendar_event.dart';
import '../models/schedule_entry.dart';
import '../models/task_item.dart';

abstract class NotificationService {
  /// Inicializa el plugin, zona horaria y canales de notificación. Llamar
  /// una sola vez al arrancar la app, antes de programar cualquier aviso.
  Future<void> initialize();

  /// Pide permiso de notificaciones (Android 13+) y de alarmas exactas.
  Future<void> requestPermissions();

  /// Programa (o reemplaza) el recordatorio de una tarea para su fecha
  /// límite. No hace nada si la tarea no tiene fecha, ya está completada, o
  /// la fecha ya pasó.
  Future<void> scheduleTaskReminder(TaskItem task);

  Future<void> cancelTaskReminder(int taskId);

  /// Reemplaza todas las alarmas de clase por las del [entries] recibido —
  /// cancela las anteriores y programa una notificación recurrente semanal
  /// por cada sesión (mismo día/hora cada semana).
  Future<void> scheduleClassAlarms(List<ScheduleEntry> entries);

  Future<void> notifyNewGrade({required String subject, required String grade});

  /// Reemplaza todos los avisos del calendario académico institucional por
  /// los de [events] — cancela los anteriores y programa un aviso a las
  /// 9:00 a.m. del día anterior al inicio de cada evento.
  Future<void> scheduleAcademicCalendarNotifications(List<AcademicCalendarEvent> events);

  /// Notifica que el SAES cerró la sesión. Se dedupe internamente — llamar
  /// varias veces seguidas (un fetch fallido por pantalla) sólo muestra una.
  Future<void> notifySessionExpired();

  /// Resetea la deduplicación de [notifySessionExpired] — llamar cuando la
  /// sesión vuelve a quedar válida (login o re-login exitosos).
  Future<void> clearSessionExpiredNotice();

  /// Alarma única 30 minutos antes de [citaInicio] — reemplaza cualquier
  /// aviso de reinscripción previo (sólo puede haber una cita vigente).
  Future<void> scheduleReinscriptionReminder(DateTime citaInicio);
}

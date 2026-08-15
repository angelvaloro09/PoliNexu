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
}

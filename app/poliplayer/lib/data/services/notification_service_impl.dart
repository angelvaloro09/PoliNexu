import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/weekday.dart';
import '../../domain/models/academic_calendar_event.dart';
import '../../domain/models/schedule_entry.dart';
import '../../domain/models/task_item.dart';
import '../../domain/repositories/notification_service.dart';

const _tasksChannelId = 'tasks_channel';
const _tasksChannelName = 'Recordatorios de tareas';
const _tasksChannelDescription = 'Avisos de tareas próximas a vencer';

const _classesChannelId = 'classes_channel';
const _classesChannelName = 'Alarmas de clases';
const _classesChannelDescription = 'Avisos antes de que comience cada clase';

const _gradesChannelId = 'grades_channel';
const _gradesChannelName = 'Calificaciones';
const _gradesChannelDescription = 'Avisos de calificaciones nuevas en el SAES';

const _calendarChannelId = 'academic_calendar_channel';
const _calendarChannelName = 'Calendario académico IPN';
const _calendarChannelDescription = 'Avisos de fechas del calendario institucional del IPN';

/// Minutos de anticipación con los que suena la alarma antes de cada clase.
const _classAlarmLeadMinutes = 10;

/// Implementación con `flutter_local_notifications`. Sin `android_alarm_manager_plus`:
/// las alarmas de clase recurrentes semanales se logran con
/// `zonedSchedule(matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime)`,
/// que el propio plugin re-arma cada semana — no hace falta un isolate de
/// fondo aparte ni persistir metadata para que lo lea.
///
/// Todo el contenido de las notificaciones es texto plano — sin emojis, por
/// diseño. El ícono (`@mipmap/ic_launcher`) es lo que da la señal visual.
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Si no se puede detectar la zona horaria del dispositivo, sigue con
      // la zona por defecto de `timezone` (UTC) — mejor que fallar el arranque.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _android;
    if (android != null) {
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _tasksChannelId,
        _tasksChannelName,
        description: _tasksChannelDescription,
      ));
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _classesChannelId,
        _classesChannelName,
        description: _classesChannelDescription,
        importance: Importance.max,
      ));
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _gradesChannelId,
        _gradesChannelName,
        description: _gradesChannelDescription,
      ));
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _calendarChannelId,
        _calendarChannelName,
        description: _calendarChannelDescription,
      ));
    }

    _initialized = true;
  }

  @override
  Future<void> requestPermissions() async {
    final android = _android;
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> scheduleTaskReminder(TaskItem task) async {
    final id = _taskNotificationId(task.id!);
    await _plugin.cancel(id: id);

    final dueDate = task.dueDate;
    if (dueDate == null || task.isCompleted) return;

    // 9:00 a.m. del día de la fecha límite.
    final scheduled = tz.TZDateTime(tz.local, dueDate.year, dueDate.month, dueDate.day, 9);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: id,
      title: 'Tarea por vencer hoy',
      body: task.title,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _tasksChannelId,
          _tasksChannelName,
          channelDescription: _tasksChannelDescription,
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelTaskReminder(int taskId) => _plugin.cancel(id: _taskNotificationId(taskId));

  @override
  Future<void> scheduleClassAlarms(List<ScheduleEntry> entries) async {
    // Reemplaza el lote completo: cancela todas las alarmas de clase
    // previas antes de reprogramar con el horario recién obtenido.
    for (var id = _classAlarmIdBase; id < _classAlarmIdBase + _classAlarmIdRange; id++) {
      await _plugin.cancel(id: id);
    }

    var nextId = _classAlarmIdBase;
    final now = tz.TZDateTime.now(tz.local);

    for (final entry in entries) {
      for (final session in entry.sessions) {
        final weekday = weekdayFromSpanishLabel(session.day);
        final startParts = session.startTime.split(':');
        if (weekday == null || startParts.length != 2) continue;

        final hour = int.tryParse(startParts[0]);
        final minute = int.tryParse(startParts[1]);
        if (hour == null || minute == null) continue;

        var scheduled = _nextOccurrence(now, weekday, hour, minute)
            .subtract(const Duration(minutes: _classAlarmLeadMinutes));
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 7));
        }

        final location = session.classroom != null ? ' · ${session.building} ${session.classroom}' : '';

        await _plugin.zonedSchedule(
          id: nextId,
          title: 'Clase en $_classAlarmLeadMinutes minutos',
          body: '${entry.subject}$location',
          scheduledDate: scheduled,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _classesChannelId,
              _classesChannelName,
              channelDescription: _classesChannelDescription,
              icon: '@mipmap/ic_launcher',
              priority: Priority.high,
              category: AndroidNotificationCategory.alarm,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );

        nextId++;
        if (nextId >= _classAlarmIdBase + _classAlarmIdRange) return; // límite de seguridad
      }
    }
  }

  @override
  Future<void> notifyNewGrade({required String subject, required String grade}) async {
    final id = _gradeNotificationId(subject);
    await _plugin.show(
      id: id,
      title: 'Calificación nueva',
      body: '$subject: $grade',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _gradesChannelId,
          _gradesChannelName,
          channelDescription: _gradesChannelDescription,
          icon: '@mipmap/ic_launcher',
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  @override
  Future<void> scheduleAcademicCalendarNotifications(List<AcademicCalendarEvent> events) async {
    for (var id = _calendarIdBase; id < _calendarIdBase + _calendarIdRange; id++) {
      await _plugin.cancel(id: id);
    }

    final now = tz.TZDateTime.now(tz.local);

    for (final event in events) {
      final start = event.startDate;
      final reminderDay = DateTime(start.year, start.month, start.day - 1);
      final scheduled =
          tz.TZDateTime(tz.local, reminderDay.year, reminderDay.month, reminderDay.day, 9);
      if (scheduled.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        id: _calendarNotificationId(event.id),
        title: 'Mañana: ${event.title}',
        body: 'Calendario académico IPN',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _calendarChannelId,
            _calendarChannelName,
            channelDescription: _calendarChannelDescription,
            icon: '@mipmap/ic_launcher',
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  static const _taskIdBase = 1000;
  static const _classAlarmIdBase = 2000;
  static const _classAlarmIdRange = 1000;
  static const _gradeIdBase = 3000;
  static const _gradeIdRange = 1000;
  static const _calendarIdBase = 4000;
  static const _calendarIdRange = 1000;

  int _calendarNotificationId(String eventId) =>
      _calendarIdBase + (eventId.hashCode.abs() % _calendarIdRange);

  int _taskNotificationId(int taskId) => _taskIdBase + taskId;

  int _gradeNotificationId(String subject) => _gradeIdBase + (subject.hashCode.abs() % _gradeIdRange);

  /// Próxima ocurrencia de [weekday]/[hour]:[minute] a partir de [from]
  /// (incluye hoy mismo si la hora todavía no pasa).
  tz.TZDateTime _nextOccurrence(tz.TZDateTime from, int weekday, int hour, int minute) {
    var candidate = tz.TZDateTime(tz.local, from.year, from.month, from.day, hour, minute);
    while (candidate.weekday != weekday || candidate.isBefore(from)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}

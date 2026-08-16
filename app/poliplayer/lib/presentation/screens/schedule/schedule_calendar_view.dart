import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/task_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/school_cycle.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/subject_color.dart';
import '../../../core/utils/weekday.dart';
import '../../../domain/models/academic_calendar_event.dart';
import '../../../domain/models/schedule_entry.dart';
import '../../../domain/models/task_item.dart';
import '../../blocs/calendar/calendar_cubit.dart';
import '../../blocs/calendar/calendar_state.dart';

import '../../blocs/schedule/schedule_cubit.dart';
import '../../blocs/schedule/schedule_state.dart';
import '../../blocs/tasks/tasks_cubit.dart';
import '../../blocs/tasks/tasks_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_list_row.dart';
import '../../widgets/priority_flag.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_view.dart';

/// Categoría del calendario IPN → ícono representativo, para marcar el
/// calendario y la lista de detalle del día sin depender sólo del color.
const Map<AcademicCalendarCategory, IconData> academicCategoryIcons = {
  AcademicCalendarCategory.vacaciones: Symbols.beach_access_rounded,
  AcademicCalendarCategory.descansoObligatorio: Symbols.event_busy_rounded,
  AcademicCalendarCategory.diaPolitecnico: Symbols.celebration_rounded,
  AcademicCalendarCategory.inicioPeriodo: Symbols.flag_rounded,
  AcademicCalendarCategory.finPeriodo: Symbols.school_rounded,
  AcademicCalendarCategory.inscripcionReinscripcion: Symbols.edit_calendar_rounded,
  AcademicCalendarCategory.evaluacionOrdinaria: Symbols.quiz_rounded,
  AcademicCalendarCategory.evaluacionExtraordinaria: Symbols.quiz_rounded,
};

Color academicCategoryColor(ColorScheme colorScheme, AcademicCalendarCategory category) {
  return switch (category) {
    AcademicCalendarCategory.vacaciones => colorScheme.secondary,
    AcademicCalendarCategory.descansoObligatorio => colorScheme.secondary,
    AcademicCalendarCategory.diaPolitecnico => colorScheme.primary,
    AcademicCalendarCategory.inicioPeriodo => colorScheme.primary,
    AcademicCalendarCategory.finPeriodo => colorScheme.error,
    AcademicCalendarCategory.inscripcionReinscripcion => colorScheme.tertiary,
    AcademicCalendarCategory.evaluacionOrdinaria => colorScheme.tertiary,
    AcademicCalendarCategory.evaluacionExtraordinaria => colorScheme.error,
  };
}

/// Tarea/evento de alta prioridad (examen o evento importante) que cubre
/// [day], si existe — gana el "slot" visual del día sobre un evento del
/// calendario IPN que coincida esa misma fecha (regla de prioridad pedida:
/// el evento del alumno siempre gana sobre el institucional).
TaskItem? highPriorityStudentEventForDay(List<TaskItem> tasks, DateTime day) {
  for (final task in tasks) {
    final due = task.dueDate;
    if (due == null) continue;
    if (task.priority != TaskPriority.high) continue;
    if (task.type != TaskType.examen && task.type != TaskType.eventoImportante) continue;
    if (due.year == day.year && due.month == day.month && due.day == day.day) return task;
  }
  return null;
}

/// Todas las coincidencias de [highPriorityStudentEventForDay] para [day], no
/// sólo la primera — usado para pintar un punto por evento en el selector
/// semanal en vez de sólo saber si hay al menos uno.
List<TaskItem> studentEventsForDay(List<TaskItem> tasks, DateTime day) {
  return tasks.where((task) {
    final due = task.dueDate;
    if (due == null) return false;
    if (task.priority != TaskPriority.high) return false;
    if (task.type != TaskType.examen && task.type != TaskType.eventoImportante) return false;
    return due.year == day.year && due.month == day.month && due.day == day.day;
  }).toList();
}

/// Entrada animada simple (fade + slide) para cards de listas con scroll —
/// sin dependencias nuevas, reutiliza `AppMotion`.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  const FadeSlideIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}

/// Unifica clases (Horario), tareas con fecha límite y calendario IPN en un
/// solo calendario mensual: al seleccionar un día se muestran las clases que
/// recurren ese día de la semana junto con las tareas y eventos IPN de esa
/// fecha.
class ScheduleCalendarView extends StatefulWidget {
  const ScheduleCalendarView({super.key});

  @override
  State<ScheduleCalendarView> createState() => _ScheduleCalendarViewState();
}

class _ScheduleCalendarViewState extends State<ScheduleCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        // Antes, mientras Drift no había emitido, la vista se pintaba vacía y
        // parecía que ese día no tenía nada.
        if (tasksState is TasksInitial) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: SkeletonList(itemCount: 3),
          );
        }

        final tasks = tasksState is TasksLoaded ? tasksState.tasks : const <TaskItem>[];
        final tasksByDay = <DateTime, List<TaskItem>>{};
        for (final task in tasks) {
          final dueDate = task.dueDate;
          if (dueDate == null) continue;
          tasksByDay.putIfAbsent(_dateOnly(dueDate), () => []).add(task);
        }

        return BlocBuilder<ScheduleCubit, ScheduleState>(
          builder: (context, scheduleState) {
            final entries =
                scheduleState is ScheduleLoaded ? scheduleState.entries : const <ScheduleEntry>[];
            final dayTasks = tasksByDay[_dateOnly(_selectedDay)] ?? const <TaskItem>[];
            final dayLabel = spanishWeekdayLabel(_selectedDay);

            final daySessions = <(ScheduleEntry, ScheduleSession)>[];
            if (dayLabel != null) {
              for (final entry in entries) {
                for (final session in entry.sessions) {
                  if (session.day == dayLabel) {
                    daySessions.add((entry, session));
                  }
                }
              }
              daySessions.sort((a, b) => a.$2.startTime.compareTo(b.$2.startTime));
            }

            return BlocBuilder<CalendarCubit, CalendarState>(
              builder: (context, calendarState) {
                final academicEvents = calendarState is CalendarLoaded
                    ? calendarState.events
                    : const <AcademicCalendarEvent>[];
                final dayAcademicEvents =
                    academicEvents.where((e) => e.coversDay(_selectedDay)).toList();
                // El Horario del SAES no sabe de vacaciones: sólo se listan
                // clases si el día cae dentro del ciclo escolar activo.
                final visibleDaySessions =
                    isWithinSchoolCycle(academicEvents, _selectedDay) ? daySessions : const [];

                return Column(
                  children: [
                    TableCalendar<TaskItem>(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      locale: 'es_MX',
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: (day) => tasksByDay[_dateOnly(day)] ?? const [],
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      // `TableCalendar` trae su propia tipografía y colores: sin
                      // esto el encabezado y los días quedaban con los valores por
                      // defecto del paquete, ajenos al resto de la app.
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: theme.textTheme.sectionTitle ?? const TextStyle(),
                        leftChevronIcon: Icon(
                          Symbols.chevron_left_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        rightChevronIcon: Icon(
                          Symbols.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        headerPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ) ??
                            const TextStyle(),
                        weekendStyle: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ) ??
                            const TextStyle(),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: theme.textTheme.bodySecondary ?? const TextStyle(),
                        weekendTextStyle: theme.textTheme.bodySecondary ?? const TextStyle(),
                        outsideTextStyle: theme.textTheme.bodySecondary?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ) ??
                            const TextStyle(),
                        todayDecoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        // Sin fijarlo, el día seleccionado conservaba el color de
                        // texto por defecto sobre el círculo primario.
                        selectedTextStyle: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        markerDecoration: BoxDecoration(
                          color: colorScheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                      ),
                      calendarBuilders: CalendarBuilders<TaskItem>(
                        // Días cubiertos por un evento del calendario IPN se tiñen
                        // con el color/ícono de su categoría — salvo que ese mismo
                        // día tenga un examen/evento del alumno en alta prioridad,
                        // en cuyo caso ese evento del alumno gana el slot visual.
                        defaultBuilder: (context, day, focusedDay) {
                          final winningTask = highPriorityStudentEventForDay(tasks, day);
                          if (winningTask != null) {
                            return _DayCell(
                              day: day,
                              color: priorityColor(colorScheme, winningTask.priority),
                              icon: resolveTaskIcon(winningTask.iconKey),
                              textStyle: theme.textTheme.bodySecondary,
                            );
                          }

                          final event = _academicEventForDay(academicEvents, day);
                          if (event == null) return null;
                          return _DayCell(
                            day: day,
                            color: academicCategoryColor(colorScheme, event.category),
                            icon: academicCategoryIcons[event.category],
                            textStyle: theme.textTheme.bodySecondary,
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          if (dayAcademicEvents.isNotEmpty) ...[
                            SectionHeader(
                              title: 'Calendario IPN',
                              count: dayAcademicEvents.length,
                            ),
                            for (final event in dayAcademicEvents) ...[
                              FadeSlideIn(
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  accentColor: academicCategoryColor(colorScheme, event.category),
                                  child: AppListRow(
                                    icon: academicCategoryIcons[event.category] ?? Symbols.event_rounded,
                                    iconColor: academicCategoryColor(colorScheme, event.category),
                                    title: event.title,
                                    subtitle: event.startDate == event.endDate
                                        ? null
                                        : 'Hasta el ${event.endDate.day}/${event.endDate.month}',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (visibleDaySessions.isNotEmpty) ...[
                            SectionHeader(title: 'Clases', count: visibleDaySessions.length),
                            for (final (entry, session) in visibleDaySessions) ...[
                              FadeSlideIn(
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  accentColor: subjectColor(entry.subject, colorScheme),
                                  child: AppListRow(
                                    icon: Symbols.school_rounded,
                                    iconColor: subjectColor(entry.subject, colorScheme),
                                    title: entry.subject,
                                    subtitle: [
                                      '${session.startTime} - ${session.endTime}',
                                      if (session.classroom != null)
                                        '${session.building ?? ''} ${session.classroom}'.trim(),
                                    ].join('  ·  '),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            const SizedBox(height: AppSpacing.md),
                          ],
                          SectionHeader(title: 'Tareas', count: dayTasks.length),
                          if (dayTasks.isEmpty)
                            const InlineStatus(
                              icon: Symbols.event_available_rounded,
                              message: 'Sin tareas para este día.',
                            )
                          else
                            for (final task in dayTasks) ...[
                              FadeSlideIn(
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  child: AppListRow(
                                    icon: resolveTaskIcon(task.iconKey),
                                    iconColor: task.isCompleted
                                        ? colorScheme.onSurfaceVariant
                                        : priorityColor(colorScheme, task.priority),
                                    title: task.title,
                                    strikethrough: task.isCompleted,
                                    subtitle: task.isCompleted ? 'Completada' : null,
                                    trailing: PriorityFlag(priority: task.priority),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// El evento con la categoría "más fuerte" del día, para el tinte del
  /// calendario (un día puede caer en más de un rango, ej. fin de periodo +
  /// inicio de vacaciones).
  AcademicCalendarEvent? _academicEventForDay(List<AcademicCalendarEvent> events, DateTime day) {
    for (final event in events) {
      if (event.coversDay(day)) return event;
    }
    return null;
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color color;
  final IconData? icon;
  final TextStyle? textStyle;

  const _DayCell({required this.day, required this.color, this.icon, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Margen extra a la derecha/arriba: deja espacio para que el badge
      // sobresalga del círculo sin pisar celdas vecinas.
      margin: const EdgeInsets.fromLTRB(4, 6, 4, 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text('${day.day}', style: textStyle),
          if (icon != null)
            // Protuberancia en el arco superior derecho, fuera del círculo,
            // en vez de un ícono encimado a la fecha.
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                ),
                child: Icon(icon, size: 9, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

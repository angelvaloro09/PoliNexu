import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
import '../../widgets/animated_entrance.dart';
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

// 8 categorías, sólo 4 roles de ColorScheme disponibles sin salirse de la
// paleta de marca — cada par comparte familia (mismo rol base) pero usa el
// tono "on*Container" del otro para distinguirse, en vez de reusar el mismo
// valor dos veces (que hacía indistinguibles a la mitad de las categorías).
Color academicCategoryColor(ColorScheme colorScheme, AcademicCalendarCategory category) {
  return switch (category) {
    AcademicCalendarCategory.vacaciones => colorScheme.secondary,
    AcademicCalendarCategory.descansoObligatorio => colorScheme.onSecondaryContainer,
    AcademicCalendarCategory.diaPolitecnico => colorScheme.primary,
    AcademicCalendarCategory.inicioPeriodo => colorScheme.onPrimaryContainer,
    AcademicCalendarCategory.finPeriodo => colorScheme.error,
    AcademicCalendarCategory.evaluacionExtraordinaria => colorScheme.onErrorContainer,
    AcademicCalendarCategory.inscripcionReinscripcion => colorScheme.tertiary,
    AcademicCalendarCategory.evaluacionOrdinaria => colorScheme.onTertiaryContainer,
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

                final isRestDay = dayAcademicEvents.any((e) =>
                    e.category == AcademicCalendarCategory.descansoObligatorio ||
                    e.category == AcademicCalendarCategory.vacaciones);

                final visibleDaySessions = isWithinSchoolCycle(academicEvents, _selectedDay) &&
                        !isRestDay
                    ? daySessions
                    : const <(ScheduleEntry, ScheduleSession)>[];

                final visibleDayTasks = dayTasks;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: TableCalendar<TaskItem>(
                          firstDay: DateTime.now().subtract(const Duration(days: 365)),
                          lastDay: DateTime.now().add(const Duration(days: 365)),
                          focusedDay: _focusedDay,
                          locale: 'es_MX',
                          // Un poco más alto que el default (52): el número
                          // del día y el punto indicador debajo necesitan
                          // espacio propio para no verse apretados.
                          rowHeight: 56,
                          daysOfWeekHeight: 24,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: theme.textTheme.cardTitle ?? const TextStyle(),
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
                            weekdayStyle: theme.textTheme.meta?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ) ??
                                const TextStyle(),
                            weekendStyle: theme.textTheme.meta?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ) ??
                                const TextStyle(),
                          ),
                          // `calendarStyle`'s day-cell colors ya no aplican:
                          // `calendarBuilders` de abajo cubre todos los
                          // estados (normal/hoy/seleccionado/fuera de mes)
                          // con `_DayCell`, así que no hay estilos muertos
                          // que fijar aquí — sólo queda lo que sí sigue
                          // gobernando table_calendar (encabezados, chevrons).
                          calendarBuilders: CalendarBuilders<TaskItem>(
                            defaultBuilder: (context, day, focusedDay) => _DayCell(
                              day: day,
                              dotColor: _dotColorForDay(tasks, academicEvents, colorScheme, day),
                              textStyle: theme.textTheme.bodySecondary,
                            ),
                            // Días del mes anterior/siguiente que asoman en la
                            // grilla: mismo estilo atenuado que ya tenía
                            // `calendarStyle.outsideTextStyle`, que sin este
                            // builder quedaba sin efecto (`defaultBuilder`
                            // gana y no distinguía "fuera de mes").
                            outsideBuilder: (context, day, focusedDay) => _DayCell(
                              day: day,
                              dotColor: _dotColorForDay(tasks, academicEvents, colorScheme, day),
                              textStyle: theme.textTheme.bodySecondary?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            todayBuilder: (context, day, focusedDay) => _DayCell(
                              day: day,
                              dotColor: _dotColorForDay(tasks, academicEvents, colorScheme, day),
                              textStyle:
                                  TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                              isToday: true,
                            ),
                            selectedBuilder: (context, day, focusedDay) => _DayCell(
                              day: day,
                              dotColor: _dotColorForDay(tasks, academicEvents, colorScheme, day),
                              textStyle: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              isSelected: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: AppMotion.normal,
                        switchInCurve: AppMotion.emphasized,
                        switchOutCurve: AppMotion.emphasizedAccelerate,
                        child: _DayDetailList(
                          key: ValueKey(_dateOnly(_selectedDay)),
                          isRestDay: isRestDay,
                          dayAcademicEvents: dayAcademicEvents,
                          visibleDaySessions: visibleDaySessions,
                          visibleDayTasks: visibleDayTasks,
                        ),
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

  /// Color del punto indicador del día — el mismo "ganador" que antes
  /// decidía la insignia: una tarea/evento de alta prioridad del alumno
  /// gana sobre un evento del calendario IPN. `null` si no hay nada ese día.
  Color? _dotColorForDay(
    List<TaskItem> tasks,
    List<AcademicCalendarEvent> academicEvents,
    ColorScheme colorScheme,
    DateTime day,
  ) {
    final winningTask = highPriorityStudentEventForDay(tasks, day);
    if (winningTask != null) return priorityColor(colorScheme, winningTask.priority);

    final event = _academicEventForDay(academicEvents, day);
    if (event != null) return academicCategoryColor(colorScheme, event.category);

    return null;
  }
}

/// Lista de detalle del día seleccionado (eventos IPN / clases / tareas).
/// Widget propio (y no un `ListView` inline) para que `AnimatedSwitcher`
/// tenga un único child que reemplazar por `ValueKey` al cambiar de día —
/// hace crossfade hacia el contenido nuevo en vez de reemplazarlo de golpe.
class _DayDetailList extends StatelessWidget {
  final bool isRestDay;
  final List<AcademicCalendarEvent> dayAcademicEvents;
  final List<(ScheduleEntry, ScheduleSession)> visibleDaySessions;
  final List<TaskItem> visibleDayTasks;

  const _DayDetailList({
    super.key,
    required this.isRestDay,
    required this.dayAcademicEvents,
    required this.visibleDaySessions,
    required this.visibleDayTasks,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Índice corrido a través de las 3 secciones para que el stagger de
    // entrada sea continuo (no se reinicia en cada sección).
    var entryIndex = 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (isRestDay)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: InlineStatus(
              icon: Symbols.celebration_rounded,
              message: '¡Día de descanso! Disfruta tu tiempo libre.',
            ),
          ),
        if (dayAcademicEvents.isNotEmpty) ...[
          SectionHeader(title: 'Calendario IPN', count: dayAcademicEvents.length),
          for (final event in dayAcademicEvents) ...[
            AnimatedEntrance(
              index: entryIndex++,
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
            AnimatedEntrance(
              index: entryIndex++,
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
        if (!isRestDay) ...[
          SectionHeader(title: 'Actividades', count: visibleDayTasks.length),
          if (visibleDayTasks.isEmpty)
            const InlineStatus(
              icon: Symbols.event_available_rounded,
              message: 'Sin actividades para este día.',
            )
          else
            for (final task in visibleDayTasks) ...[
              AnimatedEntrance(
                index: entryIndex++,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: AppListRow(
                    icon: resolveTaskIcon(task.iconKey),
                    iconColor: task.isCompleted
                        ? colorScheme.onSurfaceVariant
                        : priorityColor(colorScheme, task.priority),
                    title: task.title,
                    strikethrough: task.isCompleted,
                    subtitle: task.isCompleted
                        ? 'Completada'
                        : (task.hasTime
                            ? DateFormat("h:mm a", 'es_MX').format(task.dueDate!)
                            : null),
                    trailing: PriorityFlag(priority: task.priority),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ],
    );
  }
}

/// Celda de día: número dentro de un círculo (relleno si es hoy/seleccionado)
/// y, debajo, un punto de color si el día tiene una tarea/evento importante
/// pendiente — como Google Calendar, no un ícono encimado al número. Antes
/// era una insignia con ícono que sobresalía del círculo hacia la celda
/// vecina; se veía recargado y a veces se recortaba contra el borde de la
/// fila.
class _DayCell extends StatelessWidget {
  final DateTime day;

  /// `null` = sin tarea/evento importante ese día, no se pinta el punto.
  final Color? dotColor;
  final TextStyle? textStyle;
  final bool isSelected;
  final bool isToday;

  const _DayCell({
    required this.day,
    this.dotColor,
    this.textStyle,
    this.isSelected = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : isToday
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text('${day.day}', style: textStyle),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 6,
          width: 6,
          child: dotColor == null
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
        ),
      ],
    );
  }
}

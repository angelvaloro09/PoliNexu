import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/weekday.dart';
import '../../../domain/models/schedule_entry.dart';
import '../../../domain/models/task_item.dart';
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
import '../../../core/utils/subject_color.dart';

/// Unifica clases (Horario) y tareas con fecha límite en un solo calendario:
/// al seleccionar un día se muestran las clases que recurren ese día de la
/// semana junto con las tareas que vencen justo ese día.
class TaskCalendarView extends StatefulWidget {
  const TaskCalendarView({super.key});

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
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
            final entries = scheduleState is ScheduleLoaded ? scheduleState.entries : const <ScheduleEntry>[];
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
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (daySessions.isNotEmpty) ...[
                        SectionHeader(title: 'Clases', count: daySessions.length),
                        for (final (entry, session) in daySessions) ...[
                          AppCard(
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
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: AppListRow(
                              icon: task.isCompleted
                                  ? Symbols.check_circle_rounded
                                  : Symbols.task_alt_rounded,
                              iconColor: task.isCompleted
                                  ? colorScheme.onSurfaceVariant
                                  : priorityColor(colorScheme, task.priority),
                              title: task.title,
                              strikethrough: task.isCompleted,
                              subtitle: task.isCompleted ? 'Completada' : null,
                              trailing: PriorityFlag(priority: task.priority),
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
  }
}

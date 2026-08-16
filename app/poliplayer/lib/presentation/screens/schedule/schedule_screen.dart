import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/school_cycle.dart';
import '../../../core/utils/subject_color.dart';
import '../../../core/utils/weekday.dart';
import '../../../domain/models/academic_calendar_event.dart';
import '../../../domain/models/schedule_entry.dart';
import '../../../domain/models/task_item.dart';
import '../../../domain/repositories/schedule_overrides_repository.dart';
import '../../blocs/calendar/calendar_cubit.dart';
import '../../blocs/calendar/calendar_state.dart';
import '../../blocs/reinscription/reinscription_cubit.dart';
import '../../blocs/reinscription/reinscription_state.dart';
import '../../blocs/schedule/schedule_cubit.dart';
import '../../blocs/schedule/schedule_overrides_cubit.dart';
import '../../blocs/schedule/schedule_state.dart';
import '../../blocs/tasks/tasks_cubit.dart';
import '../../blocs/tasks/tasks_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/priority_flag.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_view.dart';
import '../../../core/constants/task_icons.dart';
import 'schedule_calendar_view.dart';
import 'schedule_override_sheet.dart';

enum _ScheduleViewMode { week, calendar }

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ScheduleCubit>.value(value: getIt<ScheduleCubit>()..loadSchedule()),
        BlocProvider<CalendarCubit>.value(value: getIt<CalendarCubit>()..loadAcademicCalendar()),
        BlocProvider<ReinscriptionCubit>.value(
          value: getIt<ReinscriptionCubit>()..loadReinscription(),
        ),
        BlocProvider<TasksCubit>.value(value: getIt<TasksCubit>()),
        BlocProvider<ScheduleOverridesCubit>.value(value: getIt<ScheduleOverridesCubit>()),
      ],
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  _ScheduleViewMode _mode = _ScheduleViewMode.week;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SegmentedButton<_ScheduleViewMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _ScheduleViewMode.week,
                  icon: Icon(Symbols.view_week_rounded),
                ),
                ButtonSegment(
                  value: _ScheduleViewMode.calendar,
                  icon: Icon(Symbols.calendar_month_rounded),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() => _mode = selection.first),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.emphasized,
        switchOutCurve: AppMotion.emphasizedAccelerate,
        child: _mode == _ScheduleViewMode.week
            ? const _WeekDayView(key: ValueKey('week'))
            : const ScheduleCalendarView(key: ValueKey('calendar')),
      ),
    );
  }
}

/// Selector de día de la semana (LUN/24 AGO ...) — al elegir un día se
/// muestran las clases que recurren ese día, las tareas que vencen esa fecha
/// y los eventos del calendario IPN que la cubran.
class _WeekDayView extends StatefulWidget {
  const _WeekDayView({super.key});

  @override
  State<_WeekDayView> createState() => _WeekDayViewState();
}

class _WeekDayViewState extends State<_WeekDayView> {
  late DateTime _selectedDay;
  late List<DateTime> _weekDates;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    // Lunes=1..Domingo=7 en `DateTime.weekday`: retrocede hasta el lunes de
    // esta semana para anclar la fila de chips.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    _weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));
    _selectedDay = today;
  }

  void _shiftWeek(int deltaDays) {
    setState(() {
      _weekDates = [for (final d in _weekDates) d.add(Duration(days: deltaDays))];
      _selectedDay = _selectedDay.add(Duration(days: deltaDays));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<TasksCubit, TasksState>(
          builder: (context, tasksState) {
            final tasks = tasksState is TasksLoaded ? tasksState.tasks : const <TaskItem>[];
            return SizedBox(
              height: 92,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Symbols.chevron_left_rounded),
                    tooltip: 'Semana anterior',
                    onPressed: () => _shiftWeek(-7),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.emphasized,
                      switchOutCurve: AppMotion.emphasizedAccelerate,
                      child: ListView.separated(
                        key: ValueKey(_weekDates.first),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        scrollDirection: Axis.horizontal,
                        itemCount: _weekDates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final date = _weekDates[index];
                          final selected = isSameDate(date, _selectedDay);
                          final isToday = isSameDate(date, DateTime.now());

                          return _DayChip(
                            date: date,
                            selected: selected,
                            isToday: isToday,
                            eventCount: studentEventsForDay(tasks, date).length,
                            onTap: () => setState(() => _selectedDay = date),
                          );
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.chevron_right_rounded),
                    tooltip: 'Semana siguiente',
                    onPressed: () => _shiftWeek(7),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<ScheduleCubit, ScheduleState>(
            builder: (context, scheduleState) {
              return switch (scheduleState) {
                ScheduleInitial() || ScheduleLoading() => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: SkeletonList(itemCount: 3),
                  ),
                ScheduleError(:final message) => StatusView.error(
                    message: message,
                    onRetry: () => context.read<ScheduleCubit>().loadSchedule(force: true),
                  ),
                ScheduleLoaded(:final entries) => _DayDetail(
                    selectedDay: _selectedDay,
                    entries: entries,
                  ),
              };
            },
          ),
        ),
      ],
    );
  }
}

bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _weekdayAbbrev = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
const _monthAbbrev = [
  'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
  'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
];

class _DayChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool isToday;
  final int eventCount;
  final VoidCallback onTap;

  const _DayChip({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.eventCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = AppTheme.brandGradient(theme.brightness);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: selected ? null : colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.lgAll,
          border: isToday && !selected ? Border.all(color: colorScheme.primary, width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayAbbrev[date.weekday - 1],
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: theme.textTheme.cardTitle?.copyWith(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            Text(
              _monthAbbrev[date.month - 1],
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? colorScheme.onPrimary.withValues(alpha: 0.85) : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < eventCount.clamp(0, 3); i++)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? colorScheme.onPrimary : colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalle del día seleccionado: evento(s) IPN que lo cubran, clases que
/// recurren ese día de la semana y tareas con esa fecha límite.
class _DayDetail extends StatelessWidget {
  final DateTime selectedDay;
  final List<ScheduleEntry> entries;

  const _DayDetail({required this.selectedDay, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayLabel = spanishWeekdayLabel(selectedDay);

    final daySessions = <(ScheduleEntry, ScheduleSession)>[];
    if (dayLabel != null) {
      for (final entry in entries) {
        for (final session in entry.sessions) {
          if (session.day == dayLabel) daySessions.add((entry, session));
        }
      }
      daySessions.sort((a, b) => a.$2.startTime.compareTo(b.$2.startTime));
    }

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        final tasks = tasksState is TasksLoaded ? tasksState.tasks : const <TaskItem>[];
        final dayTasks = tasks.where((t) {
          final due = t.dueDate;
          return due != null && isSameDate(due, selectedDay);
        }).toList();

        return BlocBuilder<CalendarCubit, CalendarState>(
          builder: (context, calendarState) {
            final academicEvents =
                calendarState is CalendarLoaded ? calendarState.events : const <AcademicCalendarEvent>[];
            final dayAcademicEvents = academicEvents.where((e) => e.coversDay(selectedDay)).toList();
            final winningTask = highPriorityStudentEventForDay(tasks, selectedDay);
            // El Horario del SAES no sabe de vacaciones: sólo se listan
            // clases si el día cae dentro del ciclo escolar activo.
            final visibleDaySessions =
                isWithinSchoolCycle(academicEvents, selectedDay) ? daySessions : const [];

            return BlocBuilder<ReinscriptionCubit, ReinscriptionState>(
              builder: (context, reinscriptionState) {
                final citaToday = reinscriptionState is ReinscriptionLoaded &&
                    reinscriptionState.reinscription.coversDay(selectedDay);

                return BlocBuilder<ScheduleOverridesCubit, ScheduleOverridesSnapshot>(
              builder: (context, overrides) {
                return AnimatedSwitcher(
                  duration: AppMotion.normal,
                  switchInCurve: AppMotion.emphasized,
                  switchOutCurve: AppMotion.emphasizedAccelerate,
                  child: ListView(
                  key: ValueKey(selectedDay),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (citaToday && winningTask == null) ...[
                      FadeSlideIn(
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          accentColor: colorScheme.tertiary,
                          child: ListTile(
                            leading: Icon(Symbols.edit_calendar_rounded, color: colorScheme.tertiary),
                            title: const Text('Cita de reinscripción'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // Regla de prioridad: si hay un evento del alumno en alta
                    // prioridad ese día, se muestra primero y el evento IPN se
                    // sigue listando pero sin ganar el color/ícono destacado.
                    if (dayAcademicEvents.isNotEmpty && winningTask == null) ...[
                      SectionHeader(title: 'Calendario IPN', count: dayAcademicEvents.length),
                      for (final event in dayAcademicEvents) ...[
                        FadeSlideIn(
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            accentColor: academicCategoryColor(colorScheme, event.category),
                            child: ListTile(
                              leading: Icon(
                                academicCategoryIcons[event.category] ?? Symbols.event_rounded,
                                color: academicCategoryColor(colorScheme, event.category),
                              ),
                              title: Text(event.title),
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
                          child: _SessionCard(entry: entry, session: session, overrides: overrides),
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
                            child: ListTile(
                              leading: Icon(
                                resolveTaskIcon(task.iconKey),
                                color: task.isCompleted
                                    ? colorScheme.onSurfaceVariant
                                    : priorityColor(colorScheme, task.priority),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: task.isCompleted ? const Text('Completada') : null,
                              trailing: PriorityFlag(priority: task.priority),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    if (entries.isEmpty && visibleDaySessions.isEmpty && dayTasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.md),
                        child: InlineStatus(
                          icon: Symbols.event_busy_rounded,
                          message: 'Sin materias inscritas todavía.',
                        ),
                      ),
                  ],
                  ),
                );
              },
            );
              },
            );
          },
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ScheduleEntry entry;
  final ScheduleSession session;
  final ScheduleOverridesSnapshot overrides;

  const _SessionCard({required this.entry, required this.session, required this.overrides});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = resolvedSubjectColor(entry.subject, colorScheme, overrides.subjectColors);

    final override = overrides.sessionOverrides[(subjectKey(entry.subject), session.day)];
    final building = override?.building ?? session.building;
    final classroom = override?.classroom ?? session.classroom;

    return AppCard(
      accentColor: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.startTime, style: theme.textTheme.cardTitle?.copyWith(color: accent)),
                Text(
                  session.endTime,
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subject, style: theme.textTheme.cardTitle),
                if (entry.teachers.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.teachers,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaChip(icon: Symbols.group_rounded, label: entry.group),
                    if (building != null || classroom != null)
                      _MetaChip(
                        icon: Symbols.location_on_rounded,
                        label: [building, classroom].where((v) => v != null && v.isNotEmpty).join(' '),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.edit_rounded, size: AppIconSize.sm),
            tooltip: 'Personalizar',
            onPressed: () => showScheduleOverrideSheet(
              context,
              cubit: context.read<ScheduleOverridesCubit>(),
              subject: entry.subject,
              day: session.day,
              currentColor: accent,
              currentBuilding: building,
              currentClassroom: classroom,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

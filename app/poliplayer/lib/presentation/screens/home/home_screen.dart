import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
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
import '../../widgets/stale_data_banner.dart';
import '../../widgets/status_view.dart';
import '../../widgets/animated_entrance.dart';
import '../../widgets/nexus_mark.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ScheduleCubit>.value(value: getIt<ScheduleCubit>()..loadSchedule()),
        BlocProvider<CalendarCubit>.value(value: getIt<CalendarCubit>()..loadAcademicCalendar()),
        BlocProvider<TasksCubit>.value(value: getIt<TasksCubit>()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = DateTime.now();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<ScheduleCubit>().loadSchedule(force: true),
        child: BlocBuilder<CalendarCubit, CalendarState>(
          builder: (context, calendarState) {
            final academicEvents =
                calendarState is CalendarLoaded ? calendarState.events : const <AcademicCalendarEvent>[];
            final dayAcademicEvents =
                academicEvents.where((e) => e.coversDay(today)).toList();
            final isRestDay = dayAcademicEvents.any((e) =>
                e.category == AcademicCalendarCategory.descansoObligatorio ||
                e.category == AcademicCalendarCategory.vacaciones);

            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  // Único toque de marca fuera del flujo de auth — sólo en
                  // Home (la pantalla más vista), no en las 5 tabs por igual,
                  // para que no se vuelva papel tapiz.
                  leading: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: NexusMark(size: AppIconSize.md),
                  ),
                  title: Text(
                    _greeting(today),
                    style: theme.textTheme.heroTitle?.copyWith(color: colorScheme.onSurface),
                  ),
                  backgroundColor: colorScheme.surface,
                  scrolledUnderElevation: 0,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0, // El AppBar ya provee espaciado superior
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      AnimatedEntrance(
                        index: 0,
                        child: Text(
                          _capitalize(DateFormat("EEEE d 'de' MMMM", 'es_MX').format(today)),
                          style: theme.textTheme.body?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      if (!isRestDay) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AnimatedEntrance(
                          index: 1,
                          child: _SummaryLine(today: today),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      if (isRestDay) ...[
                        AnimatedEntrance(
                          index: 2,
                          child: const AppCard(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: InlineStatus(
                              icon: Symbols.celebration_rounded,
                              message: '¡Día de descanso! Disfruta tu tiempo libre.',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ] else ...[
                        AnimatedEntrance(
                          index: 2,
                          child: _NextClassCard(today: today),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const AnimatedEntrance(
                          index: 3,
                          child: SectionHeader(title: 'Clases de hoy'),
                        ),
                        _TodayScheduleSection(today: today, startIndex: 4),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      AnimatedEntrance(
                        index: 10,
                        child: SectionHeader(
                          title: 'Tareas pendientes',
                          actionLabel: 'Ver todas',
                          onAction: () => context.go('/tasks'),
                        ),
                      ),
                      _PendingTasksSection(today: today, startIndex: 11),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedEntrance(
                        index: 17,
                        child: SectionHeader(
                          title: 'Actividades próximas',
                          actionLabel: 'Ver todas',
                          onAction: () => context.go('/tasks'),
                        ),
                      ),
                      _UpcomingActivitiesSection(today: today, startIndex: 18),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Buenos días';
    if (now.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

/// Sesiones de hoy, ordenadas por hora de inicio.
List<(ScheduleEntry, ScheduleSession)> _todaySessions(
  List<ScheduleEntry> entries,
  DateTime today,
) {
  final dayLabel = spanishWeekdayLabel(today);
  if (dayLabel == null) return const [];

  final sessions = <(ScheduleEntry, ScheduleSession)>[
    for (final entry in entries)
      for (final session in entry.sessions)
        if (session.day == dayLabel) (entry, session),
  ]..sort((a, b) => a.$2.startTime.compareTo(b.$2.startTime));

  return sessions;
}

/// Convierte "07:30" a un `DateTime` de hoy. `null` si el formato no cuadra.
DateTime? _timeOn(DateTime day, String time) {
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(day.year, day.month, day.day, hour, minute);
}

/// Tareas (no exámenes/eventos) incompletas con fecha hoy-o-vencida.
List<TaskItem> _pendingTasks(List<TaskItem> tasks, DateTime today) {
  final endOfToday = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
  return tasks
      .where((t) =>
          !t.isCompleted &&
          t.type == TaskType.tarea &&
          t.dueDate != null &&
          t.dueDate!.isBefore(endOfToday))
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
}

/// Exámenes/eventos importantes incompletos en los próximos 7 días
/// (incluyendo hoy) — separados de "Tareas pendientes" porque conviene verlos
/// con más anticipación, no sólo el mismo día.
List<TaskItem> _upcomingActivities(List<TaskItem> tasks, DateTime today) {
  final startOfToday = DateTime(today.year, today.month, today.day);
  final endOfWindow = startOfToday.add(const Duration(days: 7));
  return tasks
      .where((t) =>
          !t.isCompleted &&
          (t.type == TaskType.examen || t.type == TaskType.eventoImportante) &&
          t.dueDate != null &&
          !t.dueDate!.isBefore(startOfToday) &&
          t.dueDate!.isBefore(endOfWindow))
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
}

/// "Hoy" / "Mañana" / "d MMM" según qué tan lejos esté [due] de [today].
String _relativeDayLabel(DateTime today, DateTime due) {
  final startOfToday = DateTime(today.year, today.month, today.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  final days = dueDay.difference(startOfToday).inDays;
  return switch (days) {
    0 => 'Hoy',
    1 => 'Mañana',
    _ => DateFormat('d MMM', 'es_MX').format(due),
  };
}

/// Línea "3 clases · 2 tareas · 1 actividad" bajo la fecha — mismo dato que ya
/// alimenta las 3 secciones de abajo, sin pedir nada nuevo. Omite cualquier
/// conteo en 0 en vez de mostrar "0 clases".
class _SummaryLine extends StatelessWidget {
  final DateTime today;

  const _SummaryLine({required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, scheduleState) {
        final classCount = scheduleState is ScheduleLoaded
            ? _todaySessions(scheduleState.entries, today).length
            : 0;

        return BlocBuilder<TasksCubit, TasksState>(
          builder: (context, tasksState) {
            final tasks = tasksState is TasksLoaded ? tasksState.tasks : const <TaskItem>[];
            final taskCount = _pendingTasks(tasks, today).length;
            final activityCount = _upcomingActivities(tasks, today).length;

            final parts = [
              if (classCount > 0) '$classCount clase${classCount == 1 ? '' : 's'}',
              if (taskCount > 0) '$taskCount tarea${taskCount == 1 ? '' : 's'}',
              if (activityCount > 0) '$activityCount actividad${activityCount == 1 ? '' : 'es'}',
            ];
            if (parts.isEmpty) return const SizedBox.shrink();

            return Text(
              parts.join('  ·  '),
              style: theme.textTheme.meta?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            );
          },
        );
      },
    );
  }
}

class _NextClassCard extends StatelessWidget {
  final DateTime today;

  const _NextClassCard({required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded) return const SizedBox.shrink();

        final sessions = _todaySessions(state.entries, today);
        if (sessions.isEmpty) return const SizedBox.shrink();

        (ScheduleEntry, ScheduleSession)? current;
        (ScheduleEntry, ScheduleSession)? next;
        for (final item in sessions) {
          final start = _timeOn(today, item.$2.startTime);
          final end = _timeOn(today, item.$2.endTime);
          if (start == null || end == null) continue;
          if (today.isAfter(start) && today.isBefore(end)) {
            current = item;
            break;
          }
          if (start.isAfter(today)) {
            next ??= item;
          }
        }

        final item = current ?? next;
        if (item == null) return const SizedBox.shrink();

        final (entry, session) = item;
        final isNow = current != null;
        final start = _timeOn(today, session.startTime);
        final minutesAway = start?.difference(today).inMinutes;

        // La única tarjeta "hero" del día — degradado de marca en vez del
        // tonal genérico, todo lo demás en la pantalla queda plano.
        final onGradient = Colors.white;

        return AppCard(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.brandGradient(theme.brightness),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          onTap: () => context.go('/schedule'), // Hace que reaccione al toque con animación
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isNow ? Symbols.play_circle_rounded : Symbols.schedule_rounded,
                    size: AppIconSize.sm,
                    color: onGradient,
                    fill: 1,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isNow
                        ? 'Clase en curso'
                        : minutesAway != null && minutesAway < 60
                            ? 'En $minutesAway min'
                            : 'Próxima clase',
                    style: theme.textTheme.meta?.copyWith(color: onGradient),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.subject,
                style: theme.textTheme.sectionTitle?.copyWith(color: onGradient),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  '${session.startTime} - ${session.endTime}',
                  if (session.classroom != null)
                    '${session.building ?? ''} ${session.classroom}'.trim(),
                ].join('  ·  '),
                style: theme.textTheme.bodySecondary?.copyWith(
                  color: onGradient.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayScheduleSection extends StatelessWidget {
  final DateTime today;
  final int startIndex;

  const _TodayScheduleSection({required this.today, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        switch (state) {
          case ScheduleInitial():
          case ScheduleLoading():
            return const SkeletonList(itemCount: 2);

          case ScheduleError():
            return AnimatedEntrance(
              index: startIndex,
              child: InlineStatus(
                icon: Symbols.cloud_off_rounded,
                message: 'No se pudo cargar tu horario.',
                actionLabel: 'Reintentar',
                onAction: () => context.read<ScheduleCubit>().loadSchedule(force: true),
              ),
            );

          case ScheduleLoaded(:final entries, :final fetchedAt, :final fromCache):
            final sessions = _todaySessions(entries, today);
            if (sessions.isEmpty) {
              return AnimatedEntrance(
                index: startIndex,
                child: const InlineStatus(
                  icon: Symbols.beach_access_rounded,
                  message: 'Hoy no tienes clases.',
                ),
              );
            }

            return Column(
              children: [
                if (fromCache) ...[
                  AnimatedEntrance(
                    index: startIndex,
                    child: StaleDataBanner(fetchedAt: fetchedAt),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                for (var i = 0; i < sessions.length; i++) ...[
                  AnimatedEntrance(
                    index: startIndex + (fromCache ? 1 : 0) + i,
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      accentColor: subjectColor(sessions[i].$1.subject, colorScheme),
                      onTap: () => context.go('/schedule'),
                      child: AppListRow(
                        leading: _TimeChip(time: sessions[i].$2.startTime),
                        title: sessions[i].$1.subject,
                        subtitle: [
                          '${sessions[i].$2.startTime} - ${sessions[i].$2.endTime}',
                          if (sessions[i].$2.classroom != null)
                            '${sessions[i].$2.building ?? ''} ${sessions[i].$2.classroom}'.trim(),
                        ].join('  ·  '),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
        }
      },
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;

  const _TimeChip({required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.mdAll,
      ),
      child: Text(
        time,
        textAlign: TextAlign.center,
        style: theme.textTheme.meta?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PendingTasksSection extends StatelessWidget {
  final DateTime today;
  final int startIndex;

  const _PendingTasksSection({required this.today, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startOfToday = DateTime(today.year, today.month, today.day);

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is! TasksLoaded) return const SkeletonList(itemCount: 2);

        final pending = _pendingTasks(state.tasks, today);

        if (pending.isEmpty) {
          return AnimatedEntrance(
            index: startIndex,
            child: const InlineStatus(
              icon: Symbols.check_circle_rounded,
              message: 'Nada pendiente para hoy.',
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < pending.length; i++) ...[
              AnimatedEntrance(
                index: startIndex + i,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  accentColor: priorityColor(colorScheme, pending[i].priority),
                  onTap: () => context.go('/tasks'),
                  child: AppListRow(
                    icon: pending[i].dueDate!.isBefore(startOfToday)
                        ? Symbols.warning_rounded
                        : Symbols.task_alt_rounded,
                    iconColor: pending[i].dueDate!.isBefore(startOfToday)
                        ? colorScheme.error
                        : colorScheme.primary,
                    title: pending[i].title,
                    subtitle: pending[i].dueDate!.isBefore(startOfToday)
                        ? 'Venció el ${DateFormat('d MMM', 'es_MX').format(pending[i].dueDate!)}'
                        : 'Vence hoy${pending[i].hasTime ? DateFormat(" 'a las' h:mm a", 'es_MX').format(pending[i].dueDate!) : ''}',
                    trailing: PriorityFlag(priority: pending[i].priority),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

/// Exámenes y eventos importantes de los próximos 7 días — separados de
/// "Tareas pendientes" porque son otro tipo de pendiente (conviene verlos con
/// anticipación, no sólo el día que vencen).
class _UpcomingActivitiesSection extends StatelessWidget {
  final DateTime today;
  final int startIndex;

  const _UpcomingActivitiesSection({required this.today, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is! TasksLoaded) return const SkeletonList(itemCount: 2);

        final upcoming = _upcomingActivities(state.tasks, today);

        if (upcoming.isEmpty) {
          return AnimatedEntrance(
            index: startIndex,
            child: const InlineStatus(
              icon: Symbols.event_available_rounded,
              message: 'Sin actividades próximas.',
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < upcoming.length; i++) ...[
              AnimatedEntrance(
                index: startIndex + i,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  accentColor: priorityColor(colorScheme, upcoming[i].priority),
                  onTap: () => context.go('/tasks'),
                  child: AppListRow(
                    icon: upcoming[i].type == TaskType.examen
                        ? Symbols.quiz_rounded
                        : Symbols.event_rounded,
                    iconColor: priorityColor(colorScheme, upcoming[i].priority),
                    title: upcoming[i].title,
                    subtitle: _relativeDayLabel(today, upcoming[i].dueDate!) +
                        (upcoming[i].hasTime
                            ? DateFormat(" 'a las' h:mm a", 'es_MX').format(upcoming[i].dueDate!)
                            : ''),
                    trailing: PriorityFlag(priority: upcoming[i].priority),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

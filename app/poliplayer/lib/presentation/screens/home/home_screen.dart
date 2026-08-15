import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/weekday.dart';
import '../../../domain/models/schedule_entry.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ScheduleCubit>(create: (_) => getIt<ScheduleCubit>()..loadSchedule()),
        BlocProvider<TasksCubit>(create: (_) => getIt<TasksCubit>()),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ScheduleCubit>().loadSchedule(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              // Encabezado propio en vez de AppBar: en la pantalla de inicio el
              // saludo *es* el título, y una barra encima sólo lo repetiría.
              Text(
                _greeting(today),
                style: theme.textTheme.heroTitle?.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _capitalize(DateFormat("EEEE d 'de' MMMM", 'es_MX').format(today)),
                style: theme.textTheme.body?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              _NextClassCard(today: today),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Clases de hoy'),
              _TodayScheduleSection(today: today),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Tareas pendientes',
                actionLabel: 'Ver todas',
                onAction: () => context.go('/tasks'),
              ),
              _PendingTasksSection(today: today),
            ],
          ),
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

/// Tarjeta destacada con la clase en curso o la siguiente del día.
///
/// Es la información que más se consulta al abrir la app, así que va arriba y
/// con más peso visual que la lista completa.
class _NextClassCard extends StatelessWidget {
  final DateTime today;

  const _NextClassCard({required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded) return const SizedBox.shrink();

        final sessions = _todaySessions(state.entries, today);
        if (sessions.isEmpty) return const SizedBox.shrink();

        // En curso: la que ya empezó y no ha terminado. Si no hay, la próxima.
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

        return AppCard(
          emphasized: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isNow ? Symbols.play_circle_rounded : Symbols.schedule_rounded,
                    size: AppIconSize.sm,
                    color: colorScheme.onSecondaryContainer,
                    fill: 1,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isNow
                        ? 'Clase en curso'
                        : minutesAway != null && minutesAway < 60
                            ? 'En $minutesAway min'
                            : 'Próxima clase',
                    style: theme.textTheme.meta?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.subject,
                style: theme.textTheme.sectionTitle?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  '${session.startTime} - ${session.endTime}',
                  if (session.classroom != null)
                    '${session.building ?? ''} ${session.classroom}'.trim(),
                ].join('  ·  '),
                style: theme.textTheme.bodySecondary?.copyWith(
                  color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
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

  const _TodayScheduleSection({required this.today});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        switch (state) {
          case ScheduleInitial():
          case ScheduleLoading():
            return const SkeletonList(itemCount: 2);

          case ScheduleError():
            return InlineStatus(
              icon: Symbols.cloud_off_rounded,
              message: 'No se pudo cargar tu horario.',
              actionLabel: 'Reintentar',
              onAction: () => context.read<ScheduleCubit>().loadSchedule(),
            );

          case ScheduleLoaded(:final entries, :final fetchedAt, :final fromCache):
            final sessions = _todaySessions(entries, today);
            if (sessions.isEmpty) {
              return const InlineStatus(
                icon: Symbols.beach_access_rounded,
                message: 'Hoy no tienes clases.',
              );
            }

            return Column(
              children: [
                if (fromCache) ...[
                  StaleDataBanner(fetchedAt: fetchedAt),
                  const SizedBox(height: AppSpacing.sm),
                ],
                for (final (entry, session) in sessions) ...[
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: AppListRow(
                      leading: _TimeChip(time: session.startTime),
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
              ],
            );
        }
      },
    );
  }
}

/// Hora de inicio como bloque, en vez de un ícono genérico de calendario
/// repetido en todas las filas: en una lista de clases el dato que distingue
/// una fila de otra es la hora.
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

  const _PendingTasksSection({required this.today});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is! TasksLoaded) return const SkeletonList(itemCount: 2);

        final pending = state.tasks
            .where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(endOfToday))
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        if (pending.isEmpty) {
          return const InlineStatus(
            icon: Symbols.check_circle_rounded,
            message: 'Nada pendiente para hoy.',
          );
        }

        return Column(
          children: [
            for (final task in pending) ...[
              AppCard(
                padding: EdgeInsets.zero,
                onTap: () => context.go('/tasks'),
                child: AppListRow(
                  icon: task.dueDate!.isBefore(startOfToday)
                      ? Symbols.warning_rounded
                      : Symbols.task_alt_rounded,
                  iconColor: task.dueDate!.isBefore(startOfToday)
                      ? colorScheme.error
                      : colorScheme.primary,
                  title: task.title,
                  subtitle: task.dueDate!.isBefore(startOfToday)
                      ? 'Venció el ${DateFormat('d MMM', 'es_MX').format(task.dueDate!)}'
                      : 'Vence hoy',
                  trailing: PriorityFlag(priority: task.priority),
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

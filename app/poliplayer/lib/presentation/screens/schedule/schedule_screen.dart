import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/subject_color.dart';
import '../../../core/utils/weekday.dart';
import '../../../domain/models/schedule_entry.dart';
import '../../blocs/schedule/schedule_cubit.dart';
import '../../blocs/schedule/schedule_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/stale_data_banner.dart';
import '../../widgets/status_view.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScheduleCubit>()..loadSchedule(),
      child: const _ScheduleView(),
    );
  }
}

/// Días de la semana en orden, para agrupar. El sábado se muestra sólo si hay
/// clases ese día.
const _weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

class _ScheduleView extends StatelessWidget {
  const _ScheduleView();

  @override
  Widget build(BuildContext context) {
    final todayLabel = spanishWeekdayLabel(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Horario')),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          return switch (state) {
            ScheduleInitial() || ScheduleLoading() => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonList(itemCount: 4),
              ),
            ScheduleError(:final message) => StatusView.error(
                message: message,
                onRetry: () => context.read<ScheduleCubit>().loadSchedule(),
              ),
            ScheduleLoaded(:final entries) when entries.isEmpty => StatusView.empty(
                icon: Symbols.event_busy_rounded,
                title: 'Sin materias inscritas',
                message: 'Cuando el SAES publique tu horario, aparecerá aquí.',
                actionLabel: 'Actualizar',
                onAction: () => context.read<ScheduleCubit>().loadSchedule(),
              ),
            ScheduleLoaded(:final entries, :final fetchedAt, :final fromCache) =>
              RefreshIndicator(
                onRefresh: () => context.read<ScheduleCubit>().loadSchedule(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    if (fromCache) ...[
                      StaleDataBanner(fetchedAt: fetchedAt),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    ..._buildDays(context, entries, todayLabel),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }

  /// Agrupa por día de la semana. Antes era una lista plana de materias, donde
  /// había que leer cada tarjeta entera para saber qué tocaba el martes.
  List<Widget> _buildDays(
    BuildContext context,
    List<ScheduleEntry> entries,
    String? todayLabel,
  ) {
    final byDay = <String, List<(ScheduleEntry, ScheduleSession)>>{};
    for (final entry in entries) {
      for (final session in entry.sessions) {
        byDay.putIfAbsent(session.day, () => []).add((entry, session));
      }
    }
    for (final sessions in byDay.values) {
      sessions.sort((a, b) => a.$2.startTime.compareTo(b.$2.startTime));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final widgets = <Widget>[];

    for (final day in _weekDays) {
      final sessions = byDay[day];
      if (sessions == null || sessions.isEmpty) continue;

      final isToday = day == todayLabel;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
          child: Row(
            children: [
              Text(
                day,
                style: theme.textTheme.sectionTitle?.copyWith(
                  color: isToday ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Hoy',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      for (final (entry, session) in sessions) {
        widgets.add(_SessionCard(entry: entry, session: session));
        widgets.add(const SizedBox(height: AppSpacing.sm));
      }
      widgets.add(const SizedBox(height: AppSpacing.md));
    }

    // Materias inscritas sin sesiones asignadas: si no se listan aparte,
    // desaparecen de la pantalla sin explicación.
    final withoutSessions = entries.where((e) => e.sessions.isEmpty).toList();
    if (withoutSessions.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text('Sin horario asignado', style: theme.textTheme.sectionTitle),
        ),
      );
      for (final entry in withoutSessions) {
        widgets.add(
          AppCard(
            accentColor: subjectColor(entry.subject, colorScheme),
            child: Text(entry.subject, style: theme.textTheme.cardTitle),
          ),
        );
        widgets.add(const SizedBox(height: AppSpacing.sm));
      }
    }

    return widgets;
  }
}

class _SessionCard extends StatelessWidget {
  final ScheduleEntry entry;
  final ScheduleSession session;

  const _SessionCard({required this.entry, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = subjectColor(entry.subject, colorScheme);

    return AppCard(
      accentColor: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bloque de horas a la izquierda: es lo que se escanea al buscar
          // "qué sigue", así que va primero y alineado en columna.
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.startTime,
                  style: theme.textTheme.cardTitle?.copyWith(color: accent),
                ),
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
                    style: theme.textTheme.bodySecondary?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                // `Wrap` y no `Row`: con aula y edificio largos, una fila sin
                // `Expanded` se desbordaba.
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaChip(icon: Symbols.group_rounded, label: entry.group),
                    if (session.building != null || session.classroom != null)
                      _MetaChip(
                        icon: Symbols.location_on_rounded,
                        label: [session.building, session.classroom]
                            .where((v) => v != null && v.isNotEmpty)
                            .join(' '),
                      ),
                  ],
                ),
              ],
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
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

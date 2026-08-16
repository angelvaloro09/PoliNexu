import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/academic_status.dart';
import '../../../domain/models/reinscription.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/academic_status/academic_status_cubit.dart';
import '../../blocs/academic_status/academic_status_state.dart';
import '../../blocs/reinscription/reinscription_cubit.dart';
import '../../blocs/reinscription/reinscription_state.dart';
import '../../blocs/schedule/schedule_cubit.dart';
import '../../blocs/schedule/schedule_state.dart';
import '../../widgets/animated_entrance.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/stale_data_banner.dart';
import '../../widgets/status_view.dart';

String _loginRoute() => getIt<AuthRepository>().currentAccountId != null ? '/reauth' : '/login';

/// Materias del horario actual del alumno, por código — usado para filtrar
/// reprobadas/no-cursadas que ya está atendiendo este ciclo (recurse o
/// primer curse). Mismo patrón no-reactivo que `tasks_screen.dart` usa para
/// leer `ScheduleCubit` sin suscribirse: sólo se necesita una foto al abrir.
Set<String> _scheduledSubjectCodes() {
  final state = getIt<ScheduleCubit>().state;
  if (state is! ScheduleLoaded) return const {};
  return state.entries.map((e) => e.code).nonNulls.toSet();
}

class AcademicStatusScreen extends StatelessWidget {
  const AcademicStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AcademicStatusCubit>.value(
          value: getIt<AcademicStatusCubit>()..loadAcademicStatus(),
        ),
        BlocProvider<ReinscriptionCubit>.value(
          value: getIt<ReinscriptionCubit>()..loadReinscription(),
        ),
      ],
      child: const _AcademicStatusView(),
    );
  }
}

class _AcademicStatusView extends StatelessWidget {
  const _AcademicStatusView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado y reinscripción')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: const [
          SectionHeader(title: 'Materias pendientes'),
          _AcademicStatusSection(),
          SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'Reinscripción'),
          _ReinscriptionSection(),
        ],
      ),
    );
  }
}

class _AcademicStatusSection extends StatelessWidget {
  const _AcademicStatusSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademicStatusCubit, AcademicStatusState>(
      builder: (context, state) {
        return switch (state) {
          AcademicStatusInitial() || AcademicStatusLoading() =>
            const SkeletonList(itemCount: 3),
          AcademicStatusError(:final message, :final sessionRequired) when sessionRequired =>
            StatusView.error(
              title: 'Requiere sesión',
              icon: Symbols.lock_rounded,
              actionLabel: 'Iniciar sesión',
              message: message,
              onRetry: () => context.go(_loginRoute()),
            ),
          AcademicStatusError(:final message) => StatusView.error(
              message: message,
              onRetry: () => context.read<AcademicStatusCubit>().loadAcademicStatus(force: true),
            ),
          AcademicStatusLoaded(:final status, :final fetchedAt, :final fromCache, :final sessionExpired) =>
            _AcademicStatusContent(
              status: status,
              fetchedAt: fetchedAt,
              fromCache: fromCache,
              sessionExpired: sessionExpired,
            ),
        };
      },
    );
  }
}

class _AcademicStatusContent extends StatelessWidget {
  final AcademicStatus status;
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const _AcademicStatusContent({
    required this.status,
    required this.fetchedAt,
    required this.fromCache,
    required this.sessionExpired,
  });

  @override
  Widget build(BuildContext context) {
    final scheduled = _scheduledSubjectCodes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fromCache) ...[
          StaleDataBanner(
            fetchedAt: fetchedAt,
            sessionExpired: sessionExpired,
            onLoginTap: sessionExpired ? () => context.go(_loginRoute()) : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _AcademicStatusGroup(
          title: 'Materias reprobadas',
          subjects: status.failed,
          emptyMessage: 'Sin materias reprobadas.',
          groupType: _SubjectGroupType.failed,
          badgeFor: (subject) => scheduled.contains(subject.code) ? _Badge.recurse : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AcademicStatusGroup(
          title: 'Materias no cursadas',
          subjects: status.notTaken,
          emptyMessage: 'Sin materias pendientes por cursar.',
          groupType: _SubjectGroupType.notTaken,
          badgeFor: (subject) => scheduled.contains(subject.code) ? _Badge.cursando : null,
          startIndex: status.failed.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AcademicStatusGroup(
          title: 'Materias desfasadas',
          subjects: status.outOfSequence,
          emptyMessage: 'Sin materias desfasadas.',
          groupType: _SubjectGroupType.outOfSequence,
          badgeFor: (subject) => null,
          startIndex: status.failed.length + status.notTaken.length,
        ),
      ],
    );
  }
}

/// Tipo de pendiente — cada uno lee distinto de un vistazo (ícono + color),
/// no sólo por el texto del badge de "Recurse"/"Cursando" (que es sobre otra
/// cosa: si el alumno ya la está atendiendo este ciclo).
enum _SubjectGroupType {
  failed(Symbols.cancel_rounded),
  notTaken(Symbols.remove_circle_outline_rounded),
  outOfSequence(Symbols.schedule_rounded);

  final IconData icon;
  const _SubjectGroupType(this.icon);

  Color color(ColorScheme colorScheme) => switch (this) {
        _SubjectGroupType.failed => colorScheme.error,
        _SubjectGroupType.notTaken => colorScheme.onSurfaceVariant,
        _SubjectGroupType.outOfSequence => colorScheme.tertiary,
      };
}

class _AcademicStatusGroup extends StatelessWidget {
  final String title;
  final List<AcademicStatusSubject> subjects;
  final String emptyMessage;
  final _SubjectGroupType groupType;
  final _Badge? Function(AcademicStatusSubject) badgeFor;

  /// Índice de entrada del primer elemento — permite que el stagger sea
  /// continuo entre los 3 grupos en vez de reiniciarse en cada uno.
  final int startIndex;

  const _AcademicStatusGroup({
    required this.title,
    required this.subjects,
    required this.emptyMessage,
    required this.groupType,
    required this.badgeFor,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, count: subjects.isEmpty ? null : subjects.length),
        if (subjects.isEmpty)
          InlineStatus(icon: Symbols.task_alt_rounded, message: emptyMessage)
        else
          for (final (i, subject) in subjects.indexed) ...[
            AnimatedEntrance(
              index: startIndex + i,
              child: _SubjectCard(subject: subject, groupType: groupType, badge: badgeFor(subject)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

enum _Badge {
  recurse('Recurse'),
  cursando('Cursando');

  final String label;
  const _Badge(this.label);
}

class _SubjectCard extends StatelessWidget {
  final AcademicStatusSubject subject;
  final _SubjectGroupType groupType;
  final _Badge? badge;

  const _SubjectCard({required this.subject, required this.groupType, this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupColor = groupType.color(colorScheme);
    final badgeColor = switch (badge) {
      _Badge.recurse => (bg: colorScheme.errorContainer, fg: colorScheme.onErrorContainer),
      _Badge.cursando => (bg: colorScheme.tertiaryContainer, fg: colorScheme.onTertiaryContainer),
      null => null,
    };

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: groupColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(groupType.icon, size: AppIconSize.sm, color: groupColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.subject, style: theme.textTheme.cardTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  [subject.code, subject.period].where((v) => v.trim().isNotEmpty).join('  ·  '),
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (badge != null && badgeColor != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.bg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                badge!.label,
                style: theme.textTheme.meta?.copyWith(color: badgeColor.fg),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReinscriptionSection extends StatelessWidget {
  const _ReinscriptionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReinscriptionCubit, ReinscriptionState>(
      builder: (context, state) {
        return switch (state) {
          ReinscriptionInitial() || ReinscriptionLoading() => const SkeletonList(itemCount: 2),
          ReinscriptionError(:final message, :final sessionRequired) when sessionRequired =>
            StatusView.error(
              title: 'Requiere sesión',
              icon: Symbols.lock_rounded,
              actionLabel: 'Iniciar sesión',
              message: message,
              onRetry: () => context.go(_loginRoute()),
            ),
          ReinscriptionError(:final message) => StatusView.error(
              message: message,
              onRetry: () => context.read<ReinscriptionCubit>().loadReinscription(force: true),
            ),
          ReinscriptionLoaded(:final reinscription, :final fetchedAt, :final fromCache, :final sessionExpired) =>
            _ReinscriptionContent(
              reinscription: reinscription,
              fetchedAt: fetchedAt,
              fromCache: fromCache,
              sessionExpired: sessionExpired,
            ),
        };
      },
    );
  }
}

class _ReinscriptionContent extends StatelessWidget {
  final Reinscription reinscription;
  final DateTime fetchedAt;
  final bool fromCache;
  final bool sessionExpired;

  const _ReinscriptionContent({
    required this.reinscription,
    required this.fetchedAt,
    required this.fromCache,
    required this.sessionExpired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat("d 'de' MMMM, HH:mm", 'es_MX');
    final today = reinscription.coversDay(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fromCache) ...[
          StaleDataBanner(
            fetchedAt: fetchedAt,
            sessionExpired: sessionExpired,
            onLoginTap: sessionExpired ? () => context.go(_loginRoute()) : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AnimatedEntrance(
          index: 0,
          child: AppCard(
            accentColor: today ? colorScheme.tertiary : null,
            child: Row(
              children: [
                Icon(Symbols.edit_calendar_rounded, color: colorScheme.tertiary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cita de reinscripción', style: theme.textTheme.cardTitle),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        reinscription.appointmentStart == null
                            ? 'Sin fecha asignada todavía.'
                            : 'Del ${dateFormat.format(reinscription.appointmentStart!)}\n'
                                'al ${dateFormat.format(reinscription.appointmentEnd!)}',
                        style: theme.textTheme.bodySecondary?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedEntrance(
          index: 1,
          child: AppCard(
            // Grid de 2 columnas en vez de `Wrap`: con 8 métricas y
            // etiquetas largas en español, el `Wrap` se acomodaba distinto
            // según el ancho de pantalla y se veía desordenado. Filas
            // manuales (no `GridView`) para que cada una tome el alto que
            // su contenido necesite, sin recortar etiquetas de 2 líneas.
            child: _MetricGrid(
              metrics: [
                _Metric(label: 'Promedio', value: reinscription.average),
                _Metric(label: 'Materias reprobadas', value: reinscription.failedSubjectsCount),
                _Metric(label: 'Créditos del plan', value: reinscription.totalCredits),
                _Metric(label: 'Créditos obtenidos', value: reinscription.creditsEarned),
                _Metric(label: 'Créditos faltantes', value: reinscription.creditsMissing),
                _Metric(label: 'Periodos cursados', value: reinscription.periodsTaken),
                _Metric(label: 'Periodos disponibles', value: reinscription.periodsAvailable),
                _Metric(label: 'Carga autorizada', value: reinscription.authorizedLoad),
              ],
            ),
          ),
        ),
        if (reinscription.failedCreditsBreakdown.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: 'Créditos de reprobadas'),
          for (final (i, item) in reinscription.failedCreditsBreakdown.indexed) ...[
            AnimatedEntrance(
              index: 2 + i,
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                emphasized: item.isTotal,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: item.isTotal
                            ? theme.textTheme.cardTitle
                            : theme.textTheme.bodySecondary,
                      ),
                    ),
                    Text(
                      item.credits,
                      style: theme.textTheme.cardTitle?.copyWith(
                        color: item.isTotal ? colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}

/// Distribuye [metrics] en filas de 2 columnas de ancho igual.
class _MetricGrid extends StatelessWidget {
  final List<_Metric> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < metrics.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: metrics[i]),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: i + 1 < metrics.length ? metrics[i + 1] : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.cardTitle),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

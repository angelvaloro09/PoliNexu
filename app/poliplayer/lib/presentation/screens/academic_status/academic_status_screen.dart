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
    final failed = status.failed.where((s) => !scheduled.contains(s.code)).toList();
    final notTaken = status.notTaken.where((s) => !scheduled.contains(s.code)).toList();

    if (failed.isEmpty && notTaken.isEmpty && status.outOfSequence.isEmpty) {
      return const _EmptyPending();
    }

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
        for (final subject in failed) ...[
          _SubjectCard(subject: subject, badge: 'Recurse'),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final subject in notTaken) ...[
          _SubjectCard(subject: subject),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final subject in status.outOfSequence) ...[
          _SubjectCard(subject: subject),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _EmptyPending extends StatelessWidget {
  const _EmptyPending();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Symbols.task_alt_rounded, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Sin materias pendientes fuera de tu horario actual.',
              style: theme.textTheme.bodySecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final AcademicStatusSubject subject;
  final String? badge;

  const _SubjectCard({required this.subject, this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.subject, style: theme.textTheme.cardTitle),
                const SizedBox(height: 2),
                Text(
                  [subject.code, subject.period].where((v) => v.trim().isNotEmpty).join('  ·  '),
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                badge!,
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onErrorContainer),
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
        AppCard(
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
                    const SizedBox(height: 2),
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
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
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
        if (reinscription.failedCreditsBreakdown.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: 'Créditos de reprobadas'),
          for (final item in reinscription.failedCreditsBreakdown) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(item.description, style: theme.textTheme.bodySecondary)),
                  Text(item.credits, style: theme.textTheme.cardTitle),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
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

    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.cardTitle),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

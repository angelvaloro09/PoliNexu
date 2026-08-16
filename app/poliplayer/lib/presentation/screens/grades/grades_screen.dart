import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/subject_color.dart';
import '../../../domain/models/grade_entry.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/grades/grades_cubit.dart';
import '../../blocs/grades/grades_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/stale_data_banner.dart';
import '../../widgets/status_view.dart';

/// A dónde mandar al usuario a re-loguearse: sólo-CAPTCHA si hay cuenta
/// guardada, login completo si no.
String _loginRoute() => getIt<AuthRepository>().currentAccountId != null ? '/reauth' : '/login';

/// Calificación mínima aprobatoria en el IPN.
const _passingGrade = 6;

/// Convierte "8", "8.5" o "-" a número. `null` si aún no hay calificación.
double? parseGrade(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty || normalized == '-') return null;
  return double.tryParse(normalized);
}

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GradesCubit>.value(
      value: getIt<GradesCubit>()..loadGrades(),
      child: const _GradesView(),
    );
  }
}

class _GradesView extends StatelessWidget {
  const _GradesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificaciones')),
      body: BlocBuilder<GradesCubit, GradesState>(
        builder: (context, state) {
          return switch (state) {
            GradesInitial() || GradesLoading() => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonList(itemCount: 5),
              ),
            GradesError(:final message, :final sessionRequired) when sessionRequired =>
              StatusView.error(
                title: 'Requiere sesión',
                icon: Symbols.lock_rounded,
                actionLabel: 'Iniciar sesión',
                message: message,
                onRetry: () => context.go(_loginRoute()),
              ),
            GradesError(:final message) => StatusView.error(
                message: message,
                onRetry: () => context.read<GradesCubit>().loadGrades(force: true),
              ),
            GradesLoaded(:final entries) when entries.isEmpty => StatusView.empty(
                icon: Symbols.grade_rounded,
                title: 'Todavía no hay calificaciones',
                message: 'Aparecerán aquí en cuanto tus profesores las capturen.',
                actionLabel: 'Actualizar',
                onAction: () => context.read<GradesCubit>().loadGrades(force: true),
              ),
            GradesLoaded(:final entries, :final fetchedAt, :final fromCache, :final sessionExpired) =>
              RefreshIndicator(
                onRefresh: () => context.read<GradesCubit>().loadGrades(force: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    if (fromCache) ...[
                      StaleDataBanner(
                        fetchedAt: fetchedAt,
                        sessionExpired: sessionExpired,
                        onLoginTap: sessionExpired ? () => context.go(_loginRoute()) : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // Accesos que antes eran dos íconos sin etiqueta en la
                    // AppBar: nadie descubre un icono de calculadora ahí.
                    const _ToolsRow(),
                    const SizedBox(height: AppSpacing.md),
                    _AverageCard(entries: entries),
                    const SizedBox(height: AppSpacing.lg),
                    for (final entry in entries) ...[
                      _GradeCard(entry: entry),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _ToolsRow extends StatelessWidget {
  const _ToolsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/kardex'),
            icon: const Icon(Symbols.school_rounded, size: AppIconSize.sm),
            label: const Text('Kárdex'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/academic-status'),
            icon: const Icon(Symbols.fact_check_rounded, size: AppIconSize.sm),
            label: const Text('Estado'),
          ),
        ),
      ],
    );
  }
}

/// Promedio del semestre en curso sobre las materias que ya tienen final.
class _AverageCard extends StatelessWidget {
  final List<GradeEntry> entries;

  const _AverageCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final finals = entries.map((e) => parseGrade(e.final_)).nonNulls.toList();
    final average = finals.isEmpty
        ? null
        : finals.reduce((a, b) => a + b) / finals.length;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promedio del semestre',
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Anima al llegar el dato en vez de aparecer de golpe.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: average ?? 0),
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasized,
                  builder: (context, value, _) => Text(
                    average == null ? '—' : value.toStringAsFixed(2),
                    style: theme.textTheme.metric?.copyWith(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${finals.length} de ${entries.length}',
                style: theme.textTheme.cardTitle?.copyWith(color: colorScheme.onSurface),
              ),
              Text(
                'con final',
                style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final GradeEntry entry;

  const _GradeCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = subjectColor(entry.subject, colorScheme);
    final finalGrade = parseGrade(entry.final_);

    return AppCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.subject, style: theme.textTheme.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Grupo: ${entry.group}',
                      style: theme.textTheme.meta?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FinalBadge(value: entry.final_),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Los parciales van en una fila de bloques del mismo ancho. Antes
          // eran cinco columnas de texto que se cortaban en pantallas normales.
          Row(
            children: [
              Expanded(child: _PartialCell(label: '1°', value: entry.partial1)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _PartialCell(label: '2°', value: entry.partial2)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _PartialCell(label: '3°', value: entry.partial3)),
              if (parseGrade(entry.extraordinary) != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _PartialCell(label: 'ETS', value: entry.extraordinary)),
              ],
            ],
          ),
          if (finalGrade != null && finalGrade < _passingGrade) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Symbols.warning_rounded, size: 14, color: colorScheme.error),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'No aprobada',
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Calificación final, con color según si aprueba.
class _FinalBadge extends StatelessWidget {
  final String value;

  const _FinalBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grade = parseGrade(value);

    final (background, foreground) = switch (grade) {
      null => (colorScheme.surfaceContainerHigh, colorScheme.onSurfaceVariant),
      final g when g < _passingGrade => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      _ => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
    };

    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.mdAll),
      child: Text(
        grade == null ? '—' : value.trim(),
        style: theme.textTheme.cardTitle?.copyWith(color: foreground, fontSize: 18),
      ),
    );
  }
}

class _PartialCell extends StatelessWidget {
  final String label;
  final String value;

  const _PartialCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grade = parseGrade(value);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        children: [
          Text(
            grade == null ? '—' : value.trim(),
            style: theme.textTheme.cardTitle?.copyWith(
              color: grade == null
                  ? colorScheme.onSurfaceVariant
                  : grade < _passingGrade
                      ? colorScheme.error
                      : colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

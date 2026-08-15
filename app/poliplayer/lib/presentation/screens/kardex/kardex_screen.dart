import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/kardex.dart';
import '../../blocs/kardex/kardex_cubit.dart';
import '../../blocs/kardex/kardex_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/stale_data_banner.dart';
import '../../widgets/status_view.dart';
import '../grades/grades_screen.dart' show parseGrade;

/// Calificación mínima aprobatoria en el IPN.
const _passingGrade = 6;

class KardexScreen extends StatelessWidget {
  const KardexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<KardexCubit>(
      create: (_) => getIt<KardexCubit>()..loadKardex(),
      child: const _KardexView(),
    );
  }
}

class _KardexView extends StatelessWidget {
  const _KardexView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kárdex')),
      body: BlocBuilder<KardexCubit, KardexState>(
        builder: (context, state) {
          return switch (state) {
            KardexInitial() || KardexLoading() => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonList(itemCount: 4),
              ),
            KardexError(:final message) => StatusView.error(
                message: message,
                onRetry: () => context.read<KardexCubit>().loadKardex(),
              ),
            KardexLoaded(:final kardex) when kardex.semesters.isEmpty => StatusView.empty(
                icon: Symbols.history_edu_rounded,
                title: 'Kárdex vacío',
                message: 'El SAES no devolvió materias cursadas.',
                actionLabel: 'Actualizar',
                onAction: () => context.read<KardexCubit>().loadKardex(),
              ),
            KardexLoaded(:final kardex, :final fetchedAt, :final fromCache) => RefreshIndicator(
                onRefresh: () => context.read<KardexCubit>().loadKardex(),
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
                    _SummaryCard(kardex: kardex),
                    const SizedBox(height: AppSpacing.lg),
                    // El más reciente primero: es el que se consulta.
                    for (final semester in kardex.semesters.reversed) ...[
                      _SemesterTile(semester: semester),
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

class _SummaryCard extends StatelessWidget {
  final Kardex kardex;

  const _SummaryCard({required this.kardex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final approved = kardex.semesters
        .expand((s) => s.subjects)
        .where((s) => (parseGrade(s.grade) ?? 0) >= _passingGrade)
        .length;
    final total = kardex.semesters.expand((s) => s.subjects).length;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kardex.career, style: theme.textTheme.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Plan de estudios ${kardex.studyPlan}',
            style: theme.textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: kardex.average,
                  label: 'Promedio general',
                  emphasized: true,
                ),
              ),
              Expanded(
                child: _Metric(value: '$approved/$total', label: 'Materias acreditadas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final bool emphasized;

  const _Metric({required this.value, required this.label, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Columna y no `Row`: un número en `headlineMedium` junto a una etiqueta
    // en `labelMedium` dentro de una fila deja las líneas base desalineadas.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.metric?.copyWith(
            color: emphasized ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Un semestre, plegable.
///
/// Antes cada semestre era una tarjeta abierta con todas sus materias, así que
/// la pantalla eran cientos de filas y había que hacer mucho scroll para
/// llegar a lo reciente.
class _SemesterTile extends StatelessWidget {
  final KardexSemester semester;

  const _SemesterTile({required this.semester});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final grades = semester.subjects.map((s) => parseGrade(s.grade)).nonNulls.toList();
    final average = grades.isEmpty ? null : grades.reduce((a, b) => a + b) / grades.length;
    final failed = grades.where((g) => g < _passingGrade).length;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        // El ExpansionTile trae divisores propios que rompen el borde de la
        // tarjeta; se anulan aquí en vez de globalmente.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          collapsedShape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(semester.label, style: theme.textTheme.cardTitle),
          subtitle: Text(
            [
              '${semester.subjects.length} materias',
              if (average != null) 'promedio ${average.toStringAsFixed(2)}',
              if (failed > 0) '$failed no acreditada${failed == 1 ? '' : 's'}',
            ].join('  ·  '),
            style: theme.textTheme.meta?.copyWith(
              color: failed > 0 ? colorScheme.error : colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            for (final subject in semester.subjects)
              _SubjectRow(subject: subject),
          ],
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final KardexSubject subject;

  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grade = parseGrade(subject.grade);
    final failed = grade != null && grade < _passingGrade;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.body,
                ),
                const SizedBox(height: 2),
                Text(
                  [subject.period, subject.examType]
                      .where((v) => v.trim().isNotEmpty)
                      .join('  ·  '),
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 40,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: failed ? colorScheme.errorContainer : colorScheme.surfaceContainerHigh,
              borderRadius: AppRadius.smAll,
            ),
            child: Text(
              subject.grade.trim().isEmpty ? '—' : subject.grade.trim(),
              style: theme.textTheme.cardTitle?.copyWith(
                color: failed ? colorScheme.onErrorContainer : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

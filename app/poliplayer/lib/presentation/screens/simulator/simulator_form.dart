import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/subject_color.dart';
import '../../../domain/models/grade_entry.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';

/// Simulador de promedio: las materias ya calificadas cuentan con su
/// calificación real; las pendientes (`final == '-'`) se pueden simular
/// escribiendo una calificación hipotética. El promedio es un promedio
/// simple — el SAES no expone créditos/ponderación por materia en los datos
/// que scrapeamos, así que no se puede calcular un promedio ponderado real.
class SimulatorForm extends StatefulWidget {
  final List<GradeEntry> entries;

  const SimulatorForm({super.key, required this.entries});

  @override
  State<SimulatorForm> createState() => _SimulatorFormState();
}

class _SimulatorFormState extends State<SimulatorForm> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String subjectKey) {
    return _controllers.putIfAbsent(subjectKey, () => TextEditingController());
  }

  double? _parseFinal(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    return double.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final fixedGrades = <double>[];
    final pending = <GradeEntry>[];
    for (final entry in widget.entries) {
      final grade = _parseFinal(entry.final_);
      if (grade != null) {
        fixedGrades.add(grade);
      } else {
        pending.add(entry);
      }
    }

    final simulatedGrades = <double>[];
    for (final entry in pending) {
      final text = _controllerFor(entry.group + entry.subject).text;
      final value = double.tryParse(text.trim());
      if (value != null) simulatedGrades.add(value.clamp(0, 10));
    }

    final allGrades = [...fixedGrades, ...simulatedGrades];
    final average = allGrades.isEmpty ? null : allGrades.reduce((a, b) => a + b) / allGrades.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _SummaryCard(
                average: average,
                gradedCount: fixedGrades.length,
                pendingCount: pending.length,
                filledCount: simulatedGrades.length,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (pending.isNotEmpty) ...[
                const SectionHeader(title: 'Simula tus pendientes'),
                for (final entry in pending) ...[
                  _PendingSubjectTile(
                    entry: entry,
                    controller: _controllerFor(entry.group + entry.subject),
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
              if (fixedGrades.isNotEmpty) ...[
                SectionHeader(title: 'Ya calificadas', count: fixedGrades.length),
                for (final entry in widget.entries)
                  if (_parseFinal(entry.final_) != null) ...[
                    _FixedSubjectTile(entry: entry),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double? average;
  final int gradedCount;
  final int pendingCount;
  final int filledCount;

  const _SummaryCard({
    required this.average,
    required this.gradedCount,
    required this.pendingCount,
    required this.filledCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Antes era un `Container` sin radio que replicaba a mano el color del
    // `cardTheme`; ahora usa la misma tarjeta que el resto de la app.
    return AppCard(
      emphasized: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // El promedio cambia con cada tecla: animarlo hace visible el efecto
          // de lo que se acaba de escribir.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: average ?? 0),
            duration: AppMotion.normal,
            curve: AppMotion.emphasized,
            builder: (context, value, _) => Text(
              average == null ? '—' : value.toStringAsFixed(2),
              style: theme.textTheme.heroTitle?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Promedio simulado (promedio simple)',
            style: theme.textTheme.meta?.copyWith(
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            pendingCount == 0
                ? '$gradedCount materias calificadas'
                : '$gradedCount calificadas · $filledCount de $pendingCount pendientes simuladas',
            style: theme.textTheme.bodySecondary?.copyWith(
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PendingSubjectTile extends StatelessWidget {
  final GradeEntry entry;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _PendingSubjectTile({required this.entry, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      accentColor: subjectColor(entry.subject, colorScheme),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(entry.subject, style: theme.textTheme.cardTitle)),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 76,
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d{0,1})?$'))],
              decoration: InputDecoration(
                hintText: '0-10',
                // El radio de 24 del tema aplasta un campo de 76px; aquí se
                // baja al escalón que corresponde a un control compacto.
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedSubjectTile extends StatelessWidget {
  final GradeEntry entry;

  const _FixedSubjectTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Misma tarjeta que las pendientes: antes una lista eran tarjetas y la
    // otra filas sueltas, y parecían de pantallas distintas.
    return AppCard(
      accentColor: subjectColor(entry.subject, colorScheme),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Symbols.check_circle_rounded,
            size: AppIconSize.sm,
            color: colorScheme.primary,
            fill: 1,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.subject,
              style: theme.textTheme.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 76,
            child: Text(
              entry.final_,
              textAlign: TextAlign.center,
              style: theme.textTheme.cardTitle?.copyWith(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

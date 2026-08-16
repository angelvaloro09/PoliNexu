import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/subject_color.dart';
import '../../blocs/schedule/schedule_overrides_cubit.dart';

/// Bottom sheet para personalizar una materia: color propio (todas sus
/// sesiones) y edificio/salón editado para un día de la semana específico
/// (ej. "los lunes, Cálculo es en el edificio 2, salón 305" — aplica a todos
/// los lunes de esa materia, no sólo a esta ocurrencia).
void showScheduleOverrideSheet(
  BuildContext context, {
  required ScheduleOverridesCubit cubit,
  required String subject,
  required String day,
  required Color currentColor,
  String? currentBuilding,
  String? currentClassroom,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ScheduleOverrideSheet(
      cubit: cubit,
      subject: subject,
      day: day,
      currentColor: currentColor,
      currentBuilding: currentBuilding,
      currentClassroom: currentClassroom,
    ),
  );
}

class _ScheduleOverrideSheet extends StatefulWidget {
  final ScheduleOverridesCubit cubit;
  final String subject;
  final String day;
  final Color currentColor;
  final String? currentBuilding;
  final String? currentClassroom;

  const _ScheduleOverrideSheet({
    required this.cubit,
    required this.subject,
    required this.day,
    required this.currentColor,
    this.currentBuilding,
    this.currentClassroom,
  });

  @override
  State<_ScheduleOverrideSheet> createState() => _ScheduleOverrideSheetState();
}

class _ScheduleOverrideSheetState extends State<_ScheduleOverrideSheet> {
  late Color _color;
  late final TextEditingController _buildingController;
  late final TextEditingController _classroomController;

  @override
  void initState() {
    super.initState();
    _color = widget.currentColor;
    _buildingController = TextEditingController(text: widget.currentBuilding ?? '');
    _classroomController = TextEditingController(text: widget.currentClassroom ?? '');
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  void _save() {
    widget.cubit.setSubjectColor(subjectKey(widget.subject), _color.toARGB32());
    final building = _buildingController.text.trim();
    final classroom = _classroomController.text.trim();
    widget.cubit.setSessionOverride(
      subject: subjectKey(widget.subject),
      day: widget.day,
      building: building.isEmpty ? null : building,
      classroom: classroom.isEmpty ? null : classroom,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.subject, style: theme.textTheme.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Los cambios aplican a todos los ${widget.day} de esta materia.',
            style: theme.textTheme.meta?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Color', style: theme.textTheme.meta?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final swatch in subjectColorSwatches)
                _ColorSwatch(
                  color: swatch,
                  selected: swatch.toARGB32() == _color.toARGB32(),
                  onTap: () => setState(() => _color = swatch),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _buildingController,
            decoration: const InputDecoration(labelText: 'Edificio'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _classroomController,
            decoration: const InputDecoration(labelText: 'Salón'),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: selected ? 40 : 36,
        height: selected ? 40 : 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
              : null,
        ),
        child: AnimatedScale(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          scale: selected ? 1 : 0,
          child: const Icon(Symbols.check_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

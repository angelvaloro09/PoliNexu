import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/task_item.dart';

/// Color asociado a cada prioridad. Una sola definición: Home y la lista de
/// Tareas la pintaban por separado y podían divergir.
///
/// Media usa `tertiary` (no `primary`, el color de acción/chrome de la app —
/// una bandera de prioridad media pintada de "azul de botón" no se lee como
/// señal de prioridad, se confunde con la UI). Baja usa `onSurfaceVariant` a
/// propósito: "baja" significa que no reclama atención, discreta es el punto.
Color priorityColor(ColorScheme colorScheme, TaskPriority priority) => switch (priority) {
      TaskPriority.high => colorScheme.error,
      TaskPriority.medium => colorScheme.tertiary,
      TaskPriority.low => colorScheme.onSurfaceVariant,
    };

String priorityLabel(TaskPriority priority) => switch (priority) {
      TaskPriority.high => 'Alta',
      TaskPriority.medium => 'Media',
      TaskPriority.low => 'Baja',
    };

/// Indicador de prioridad de una tarea.
class PriorityFlag extends StatelessWidget {
  final TaskPriority priority;

  /// Muestra también la etiqueta de texto, no sólo la bandera.
  final bool showLabel;

  const PriorityFlag({super.key, required this.priority, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = priorityColor(theme.colorScheme, priority);

    if (!showLabel) {
      return Icon(Symbols.flag_rounded, color: color, size: AppIconSize.sm, fill: 1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.flag_rounded, color: color, size: 14, fill: 1),
          const SizedBox(width: AppSpacing.xs),
          Text(
            priorityLabel(priority),
            style: theme.textTheme.meta?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

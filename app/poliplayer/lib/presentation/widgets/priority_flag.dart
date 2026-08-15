import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_radius.dart';
import '../../domain/models/task_item.dart';

/// Color asociado a cada prioridad. Una sola definición: Home y la lista de
/// Tareas la pintaban por separado y podían divergir.
Color priorityColor(ColorScheme colorScheme, TaskPriority priority) => switch (priority) {
      TaskPriority.high => colorScheme.error,
      TaskPriority.medium => colorScheme.primary,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.flag_rounded, color: color, size: 14, fill: 1),
          const SizedBox(width: 4),
          Text(
            priorityLabel(priority),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Encabezado de sección: título a la izquierda, acción opcional a la derecha.
///
/// Centraliza el patrón "Tareas pendientes … Ver todas" para que todas las
/// secciones tengan la misma altura, tipografía y alineación.
class SectionHeader extends StatelessWidget {
  final String title;

  /// Contador opcional junto al título (p. ej. número de tareas pendientes).
  final int? count;

  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count != null ? '$title:' : title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.sectionTitle?.copyWith(color: colorScheme.onSurface),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$count',
              style: theme.textTheme.sectionTitle?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onAction != null && actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

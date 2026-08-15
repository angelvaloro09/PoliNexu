import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Fila de lista con el estilo de la app.
///
/// Sustituye los `ListTile` crudos: su padding horizontal fijo de 16dp chocaba
/// con el radio de 24 de la tarjeta contenedora y las filas se veían apretadas
/// contra las esquinas. Aquí el ícono va dentro de un contenedor redondeado
/// (como en las apps de Google) en vez de flotar suelto.
class AppListRow extends StatelessWidget {
  final IconData? icon;

  /// Color del ícono y de su fondo. Por defecto, `primary`.
  final Color? iconColor;

  /// Reemplaza el ícono por un widget propio (checkbox, avatar, hora).
  final Widget? leading;

  final String title;
  final String? subtitle;

  /// Tachado del título (tarea completada).
  final bool strikethrough;

  final Widget? trailing;
  final VoidCallback? onTap;

  const AppListRow({
    super.key,
    this.icon,
    this.iconColor,
    this.leading,
    required this.title,
    this.subtitle,
    this.strikethrough = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = iconColor ?? colorScheme.primary;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(icon, size: AppIconSize.sm, color: accent),
            ),
          if (leading != null || icon != null) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.cardTitle?.copyWith(
                    color: strikethrough ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                    decoration: strikethrough ? TextDecoration.lineThrough : null,
                    decorationColor: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySecondary?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, borderRadius: AppRadius.lgAll, child: row);
  }
}

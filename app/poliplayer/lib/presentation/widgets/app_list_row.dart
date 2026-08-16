import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Fila de lista con el estilo de la app.
///
/// Sustituye los `ListTile` crudos: su padding horizontal fijo de 16dp chocaba
/// con el radio de 24 de la tarjeta contenedora y las filas se veían apretadas
/// contra las esquinas. Aquí el ícono va dentro de un contenedor redondeado
/// (como en las apps de Google) en vez de flotar suelto.
class AppListRow extends StatefulWidget {
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
  State<AppListRow> createState() => _AppListRowState();
}

// Mismo mecanismo de tap-scale que `AppCard`: 1.0→0.98 en tap-down, vuelve en
// up/cancel — para que una fila y una tarjeta se sientan con el mismo peso
// cuando aparecen juntas en pantalla.
class _AppListRowState extends State<AppListRow> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      reverseDuration: AppMotion.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: AppMotion.standard),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) _scaleController.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = widget.iconColor ?? colorScheme.primary;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          if (widget.leading != null)
            widget.leading!
          else if (widget.icon != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(widget.icon, size: AppIconSize.sm, color: accent),
            ),
          if (widget.leading != null || widget.icon != null)
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.cardTitle?.copyWith(
                    color: widget.strikethrough
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                    decoration: widget.strikethrough ? TextDecoration.lineThrough : null,
                    decorationColor: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    widget.subtitle!,
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
          if (widget.trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            widget.trailing!,
          ],
        ],
      ),
    );

    if (widget.onTap == null) return row;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        borderRadius: AppRadius.lgAll,
        child: row,
      ),
    );
  }
}

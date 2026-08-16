import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_motion.dart';

/// Tarjeta de contenido con el padding y el radio de la app.
///
/// Añade una micro-interacción de escalado ("hundimiento") al presionarse si
/// tiene definido un [onTap].
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Superficie más marcada, para destacar una tarjeta sobre el resto.
  final bool emphasized;

  /// Color de acento en el borde izquierdo (categoría, materia, prioridad).
  final Color? accentColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.emphasized = false,
    this.accentColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(
        parent: _scaleController,
        curve: AppMotion.standard,
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Padding(padding: widget.padding, child: widget.child);

    if (widget.accentColor != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: widget.accentColor),
            Expanded(child: content),
          ],
        ),
      );
    }

    final card = Card(
      color: widget.emphasized ? colorScheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: widget.onTap == null
          ? content
          : InkWell(
              onTap: widget.onTap,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              borderRadius: AppRadius.lgAll,
              child: content,
            ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: card,
    );
  }
}

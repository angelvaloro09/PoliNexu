import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Estado de pantalla completa cuando no hay contenido que mostrar.
///
/// Unifica los tres casos que antes se resolvían por separado (o no se
/// resolvían): error con reintento, lista vacía, y sin conexión. Antes cada
/// pantalla ponía un `Text` suelto para el vacío y sólo algunas tenían botón
/// de reintentar.
class StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tiñe el ícono con el color de error.
  final bool isError;

  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  /// Fallo al cargar: siempre ofrece reintentar. `title`/`icon`/`actionLabel`
  /// son personalizables para casos como "Requiere sesión" (Notas/Kárdex sin
  /// caché tras expirar la sesión), donde el botón no reintenta sino que
  /// manda a re-login.
  factory StatusView.error({
    Key? key,
    required String message,
    required VoidCallback onRetry,
    String title = 'Algo salió mal',
    IconData icon = Symbols.error_rounded,
    String actionLabel = 'Reintentar',
  }) =>
      StatusView(
        key: key,
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onRetry,
        isError: true,
      );

  /// La petición funcionó pero no hay nada que mostrar.
  factory StatusView.empty({
    Key? key,
    IconData icon = Symbols.inbox_rounded,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      StatusView(
        key: key,
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = isError ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppMotion.slow,
              curve: AppMotion.emphasized,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: AppRadius.lgAll,
                ),
                child: Icon(icon, size: AppIconSize.lg, color: accent),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.sectionTitle?.copyWith(color: colorScheme.onSurface),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySecondary?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Versión compacta para usar dentro de una sección de otra pantalla (p. ej.
/// "Clases de hoy" en Home), donde un estado a pantalla completa no cabe.
class InlineStatus extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const InlineStatus({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIconSize.sm, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySecondary?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

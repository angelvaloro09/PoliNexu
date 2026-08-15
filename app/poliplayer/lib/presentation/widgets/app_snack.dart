import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Avisos efímeros con un solo estilo.
///
/// Antes cada pantalla armaba su `SnackBar` a mano — uno con `Colors.green`
/// hardcodeado (el único color crudo de la app) y los de error con texto sobre
/// `error` sin fijar el color de contenido. El `snackBarTheme` pone la forma y
/// el comportamiento; esto pone el ícono y la semántica.
class AppSnack {
  AppSnack._();

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    // Sin esto, dos avisos seguidos se encolan y el segundo aparece tarde.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        action: action,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppIconSize.sm, color: iconColor ?? colorScheme.onInverseSurface),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) => show(
        context,
        message: message,
        icon: Symbols.check_circle_rounded,
        iconColor: Theme.of(context).colorScheme.inversePrimary,
      );

  static void error(BuildContext context, String message) => show(
        context,
        message: message,
        icon: Symbols.error_rounded,
        iconColor: Theme.of(context).colorScheme.error,
      );

  static void info(BuildContext context, String message, {SnackBarAction? action}) => show(
        context,
        message: message,
        icon: Symbols.info_rounded,
        action: action,
      );

  /// Aviso con deshacer. [onUndo] corre si el usuario toca la acción.
  static void undo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) =>
      show(
        context,
        message: message,
        icon: Symbols.delete_rounded,
        action: SnackBarAction(label: 'Deshacer', onPressed: onUndo),
      );
}

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Tarjeta de contenido con el padding y el radio de la app.
///
/// El `cardTheme` define color, radio y elevación, pero cada pantalla seguía
/// envolviendo su contenido en un `Padding` propio y pisando el `margin` del
/// theme con valores distintos. Esto lo resuelve en un solo lugar; el espacio
/// **entre** tarjetas lo pone la lista (`separatorBuilder`), no la tarjeta.
class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Padding(padding: padding, child: child);

    if (accentColor != null) {
      // `IntrinsicHeight` es necesario: esta tarjeta vive dentro de listas
      // (Sliver/ListView) que dan altura no acotada (maxHeight=infinity) a
      // sus hijos. `crossAxisAlignment.stretch` intenta forzar esa altura a
      // la barra de acento de 4px, y un `Container` de solo ancho no puede
      // resolver una altura infinita — crashea con "BoxConstraints forces an
      // infinite height". `IntrinsicHeight` mide primero la altura real del
      // contenido y se la pasa al `Row` como una altura acotada normal.
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Card(
      color: emphasized ? colorScheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              // El `clipBehavior: antiAlias` de la Card recorta la tinta al
              // radio; sin esto el ripple se pinta cuadrado en las esquinas.
              borderRadius: AppRadius.lgAll,
              child: content,
            ),
    );
  }
}

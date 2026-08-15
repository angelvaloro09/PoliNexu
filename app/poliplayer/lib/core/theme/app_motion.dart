import 'package:flutter/animation.dart';

/// Duraciones y curvas de animación.
///
/// Material 3 usa curvas "enfatizadas" (aceleración rápida, desaceleración
/// larga) en vez del `easeInOut` simétrico: el movimiento se siente decidido
/// en vez de flotante. Todas las transiciones de la app salen de aquí para que
/// el ritmo sea el mismo en todas partes.
class AppMotion {
  AppMotion._();

  /// Cambios de estado dentro de un control (checkbox, ícono, color).
  static const Duration fast = Duration(milliseconds: 150);

  /// Transiciones estándar: cambio de contenido, entrada de listas.
  static const Duration normal = Duration(milliseconds: 250);

  /// Transiciones de pantalla y entradas de página.
  static const Duration slow = Duration(milliseconds: 400);

  /// Secuencia de arranque del splash.
  static const Duration intro = Duration(milliseconds: 900);

  /// Curva estándar M3 para elementos que entran a pantalla.
  static const Curve emphasized = Curves.easeOutCubic;

  /// Para elementos que salen: acelera y se va.
  static const Curve emphasizedAccelerate = Curves.easeInCubic;

  /// Para cambios que empiezan y terminan en pantalla (color, tamaño).
  static const Curve standard = Curves.easeInOutCubic;

  /// Retraso entre elementos consecutivos en una entrada escalonada.
  static const Duration staggerStep = Duration(milliseconds: 40);
}

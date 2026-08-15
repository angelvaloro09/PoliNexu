import 'package:flutter/widgets.dart';

/// Radios de esquina de la app.
///
/// Antes había cinco valores sueltos (8, 20, 24, 28, 32) repartidos entre el
/// theme y las pantallas, así que dos superficies vecinas podían tener curvas
/// distintas sin razón. La escala es la de Material You: cuanto más pequeño el
/// elemento, más cerrado el radio.
class AppRadius {
  AppRadius._();

  /// Badges y etiquetas pequeñas.
  static const double sm = 8;

  /// Controles compactos dentro de una tarjeta.
  static const double md = 16;

  /// Tarjetas, inputs, diálogos. El radio base de la app.
  static const double lg = 24;

  /// Superficies grandes: bottom sheets, hojas modales.
  static const double xl = 28;

  /// Botones tipo píldora y contenedores completamente redondeados.
  static const double pill = 999;

  static BorderRadius all(double radius) => BorderRadius.circular(radius);

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

  /// Sólo las esquinas superiores — bottom sheets.
  static const BorderRadius topXl = BorderRadius.vertical(top: Radius.circular(xl));
}

/// Tamaños de ícono. Material Symbols se ve mal en tamaños arbitrarios: estos
/// tres cubren todos los usos de la app (meta-info, acción, estado vacío).
class AppIconSize {
  AppIconSize._();

  /// Íconos inline junto a texto secundario.
  static const double sm = 18;

  /// Íconos de acción: AppBar, botones, listas.
  static const double md = 24;

  /// Ilustración de estado vacío/error.
  static const double lg = 48;
}

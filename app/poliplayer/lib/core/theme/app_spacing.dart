/// Grid de espaciado de 8dp — usar estas constantes en vez de valores sueltos
/// en `SizedBox`/`EdgeInsets` para mantener consistencia entre pantallas.
class AppSpacing {
  AppSpacing._();

  /// Separación mínima (título→subtítulo dentro de una fila). Por debajo de
  /// `xs`, para el único caso donde 4dp ya se ve como demasiado aire.
  static const double xxs = 2;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

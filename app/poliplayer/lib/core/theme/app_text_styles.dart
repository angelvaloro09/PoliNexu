import 'package:flutter/material.dart';

/// Pesos de fuente según la escala tipográfica de `design_system.md`.
/// Material 3 no aplica estos pesos por defecto — centraliza los `copyWith`
/// que antes se repetían inline en cada pantalla.
extension AppTextStyles on TextTheme {
  /// Título hero de pantalla principal (login, onboarding). 600, tracking -0.5.
  TextStyle? get heroTitle => displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  /// Título de sección dentro de una pantalla ("Clases de hoy"). 600.
  ///
  /// `titleLarge` y no `headlineMedium`: con ~28sp los encabezados de sección
  /// competían con el título de la pantalla en vez de subordinarse a él.
  TextStyle? get sectionTitle => titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Título de tarjeta (nombre de materia, de tarea). 600.
  ///
  /// Un escalón por debajo de [sectionTitle]: la jerarquía queda
  /// pantalla (displaySmall) → sección (22) → tarjeta (16).
  TextStyle? get cardTitle => titleMedium?.copyWith(fontWeight: FontWeight.w600);

  /// Número grande destacado: promedio, calificación final, cuenta regresiva.
  TextStyle? get metric => headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  /// Labels de botones, subtítulos. 500.
  TextStyle? get actionLabel => titleMedium?.copyWith(fontWeight: FontWeight.w500);

  /// Cuerpo de texto principal. 400.
  TextStyle? get body => bodyLarge?.copyWith(fontWeight: FontWeight.w400);

  /// Texto secundario, descripciones. 400.
  TextStyle? get bodySecondary => bodyMedium?.copyWith(fontWeight: FontWeight.w400);

  /// Chips, badges, meta-info. 500.
  TextStyle? get meta => labelMedium?.copyWith(fontWeight: FontWeight.w500);
}

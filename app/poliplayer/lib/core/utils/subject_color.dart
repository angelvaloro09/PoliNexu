import 'package:flutter/material.dart';

/// Paleta de acentos para distinguir materias entre sí.
///
/// No son colores de marca ni de estado: sólo sirven para que dos clases
/// seguidas se distingan de un vistazo. Se eligieron con la saturación de
/// Material You para que convivan con el azul de PoliNexu sin competir.
const _accentsLight = [
  Color(0xFF1E63D1), // azul de marca
  Color(0xFF00796B), // verde azulado
  Color(0xFFB4530A), // ámbar oscuro
  Color(0xFF6A3AB2), // violeta
  Color(0xFFB3261E), // rojo
  Color(0xFF00629E), // azul cielo
];

const _accentsDark = [
  Color(0xFFA8C7FA),
  Color(0xFF6ED3C4),
  Color(0xFFFFB77C),
  Color(0xFFCBBEFF),
  Color(0xFFF2B8B5),
  Color(0xFF8ECDF7),
];

/// Color estable para una materia: el mismo nombre siempre da el mismo color.
///
/// Se deriva del hash del nombre en vez de del índice en la lista, para que el
/// color no cambie cuando el SAES reordena las materias o se da de baja una.
Color subjectColor(String subject, ColorScheme colorScheme) {
  final palette = colorScheme.brightness == Brightness.light ? _accentsLight : _accentsDark;
  final hash = subject.trim().toLowerCase().hashCode.abs();
  return palette[hash % palette.length];
}

/// Clave normalizada de materia — mismo criterio que usa el hash de arriba,
/// compartida con `ScheduleOverridesRepository` para que ambos lados
/// (auto-color y color guardado por el alumno) hablen de la misma materia.
String subjectKey(String subject) => subject.trim().toLowerCase();

/// Como [subjectColor], pero si el alumno guardó un color propio para esta
/// materia (vía `ScheduleOverridesRepository`), ese gana sobre el determinístico.
Color resolvedSubjectColor(String subject, ColorScheme colorScheme, Map<String, int> overrides) {
  final override = overrides[subjectKey(subject)];
  if (override != null) return Color(override);
  return subjectColor(subject, colorScheme);
}

/// Swatches elegibles en el selector de color por materia — mismas paletas
/// que el fallback automático, para que el resultado nunca desentone.
List<Color> get subjectColorSwatches => [..._accentsLight, ..._accentsDark];

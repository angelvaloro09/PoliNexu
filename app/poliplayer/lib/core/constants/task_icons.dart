import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Set cerrado de íconos que el alumno puede elegir para una tarea, examen o
/// evento importante — se guarda la clave (texto), no un codepoint arbitrario,
/// para no depender de que el paquete de íconos mantenga los mismos valores
/// entre versiones.
const Map<String, IconData> taskIcons = {
  'task': Symbols.task_alt_rounded,
  'assignment': Symbols.assignment_rounded,
  'quiz': Symbols.quiz_rounded,
  'exam': Symbols.edit_document_rounded,
  'book': Symbols.menu_book_rounded,
  'lab': Symbols.science_rounded,
  'presentation': Symbols.co_present_rounded,
  'event': Symbols.event_rounded,
  'deadline': Symbols.event_busy_rounded,
  'flag': Symbols.flag_rounded,
  'group': Symbols.group_rounded,
  'star': Symbols.star_rounded,
  'alarm': Symbols.alarm_rounded,
  'sports': Symbols.sports_soccer_rounded,
  'celebration': Symbols.celebration_rounded,
  'payments': Symbols.payments_rounded,
};

const String defaultTaskIconKey = 'task';

IconData resolveTaskIcon(String? iconKey) => taskIcons[iconKey] ?? taskIcons[defaultTaskIconKey]!;

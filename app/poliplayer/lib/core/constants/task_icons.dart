import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

const Map<String, Map<String, IconData>> taskIconCategories = {
  'Académico': {
    'task': Symbols.task_alt_rounded,
    'assignment': Symbols.assignment_rounded,
    'quiz': Symbols.quiz_rounded,
    'exam': Symbols.edit_document_rounded,
    'book': Symbols.menu_book_rounded,
    'presentation': Symbols.co_present_rounded,
    'group': Symbols.group_rounded,
    'star': Symbols.star_rounded,
  },
  'Áreas del IPN': {
    'math': Symbols.calculate_rounded,
    'physics': Symbols.functions_rounded,
    'computing': Symbols.computer_rounded,
    'electronics': Symbols.memory_rounded,
    'lab': Symbols.science_rounded,
    'biology': Symbols.biotech_rounded,
    'business': Symbols.storefront_rounded,
  },
  'Personal': {
    'event': Symbols.event_rounded,
    'deadline': Symbols.event_busy_rounded,
    'flag': Symbols.flag_rounded,
    'alarm': Symbols.alarm_rounded,
    'sports': Symbols.sports_soccer_rounded,
    'celebration': Symbols.celebration_rounded,
    'payments': Symbols.payments_rounded,
    'fitness': Symbols.fitness_center_rounded,
    'travel': Symbols.flight_rounded,
  },
};

/// A flattened map for backwards compatibility and easy lookup.
final Map<String, IconData> taskIcons = {
  for (final category in taskIconCategories.values) ...category,
};

const String defaultTaskIconKey = 'task';

IconData resolveTaskIcon(String? iconKey) => taskIcons[iconKey] ?? taskIcons[defaultTaskIconKey]!;

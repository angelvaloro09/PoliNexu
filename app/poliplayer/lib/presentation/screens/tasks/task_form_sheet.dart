import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/task_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_motion.dart';
import '../../../domain/models/task_item.dart';
import '../../../domain/models/academic_calendar_event.dart';
import '../../blocs/tasks/tasks_cubit.dart';
import '../../blocs/calendar/calendar_cubit.dart';
import '../../blocs/calendar/calendar_state.dart';
import '../../widgets/app_snack.dart';

void showTaskFormSheet(
  BuildContext context, {
  required TasksCubit cubit,
  TaskItem? task,
  List<String> subjectOptions = const [],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TaskFormSheet(cubit: cubit, task: task, subjectOptions: subjectOptions),
  );
}

class _TaskFormSheet extends StatefulWidget {
  final TasksCubit cubit;
  final TaskItem? task;
  final List<String> subjectOptions;

  const _TaskFormSheet({required this.cubit, this.task, required this.subjectOptions});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _subjectController;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  late TaskPriority _priority;
  late TaskType _type;
  late String _iconKey;
  late bool _alarmEnabled;

  // Repetitive logic
  bool _isRepetitive = false;
  final Set<int> _selectedDays = {};
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  
  // Editing a series
  bool _updateSeries = true;
  DateTime? _updateSeriesUntil;

  bool get _isEditing => widget.task != null;
  bool get _isPartOfSeries => _isEditing && widget.task?.recurrenceGroupId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _subjectController = TextEditingController(text: widget.task?.subject ?? '');
    _dueDate = widget.task?.dueDate;
    if (widget.task?.hasTime == true && _dueDate != null) {
      _dueTime = TimeOfDay.fromDateTime(_dueDate!);
    }
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _type = widget.task?.type ?? TaskType.tarea;
    _iconKey = widget.task?.iconKey ?? defaultTaskIconKey;
    _alarmEnabled = widget.task?.alarmEnabled ?? true;

    if (!_isEditing) {
      _recurrenceStartDate = DateTime.now();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEditing && _recurrenceEndDate == null) {
      _calculateDefaultEndDate();
    }
  }

  void _calculateDefaultEndDate() {
    final calendarState = context.read<CalendarCubit>().state;
    if (calendarState is CalendarLoaded) {
      final finCiclo = calendarState.events.where((e) => e.category == AcademicCalendarCategory.finCiclo).firstOrNull;
      if (finCiclo != null && finCiclo.endDate.isAfter(DateTime.now())) {
        _recurrenceEndDate = finCiclo.endDate;
        return;
      }
    }
    // Fallback: 6 months
    _recurrenceEndDate = DateTime.now().add(const Duration(days: 180));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({DateTime? initial, required void Function(DateTime) onPicked}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
        if (_dueDate == null) {
          final now = DateTime.now();
          _dueDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        } else {
          _dueDate = DateTime(
            _dueDate!.year,
            _dueDate!.month,
            _dueDate!.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isEditing && _isRepetitive && _selectedDays.isEmpty) {
      AppSnack.show(context, 'Selecciona al menos un día para la tarea repetitiva');
      return;
    }

    final subject = _subjectController.text.trim();
    final title = _type == TaskType.examen ? subject : _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (_isEditing) {
      final taskToSave = widget.task!.copyWith(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        hasTime: _dueTime != null,
        priority: _priority,
        type: _type,
        iconKey: _iconKey,
        alarmEnabled: _alarmEnabled,
        subject: subject.isEmpty ? null : subject,
      );

      if (_isPartOfSeries && _updateSeries) {
        await widget.cubit.updateRepetitiveTaskSeries(taskToSave, widget.task!.dueDate!, untilDate: _updateSeriesUntil);
        AppSnack.success(context, 'Serie actualizada exitosamente');
      } else {
        await widget.cubit.updateTask(taskToSave);
        AppSnack.success(context, 'Actualizada exitosamente');
      }
    } else {
      if (_isRepetitive && _recurrenceStartDate != null && _recurrenceEndDate != null) {
        final groupId = const Uuid().v4();
        final List<TaskItem> generatedTasks = [];
        DateTime current = _recurrenceStartDate!;
        
        while (current.isBefore(_recurrenceEndDate!) || current.isAtSameMomentAs(_recurrenceEndDate!)) {
          if (_selectedDays.contains(current.weekday)) {
            DateTime taskDueDate = current;
            if (_dueTime != null) {
              taskDueDate = DateTime(current.year, current.month, current.day, _dueTime!.hour, _dueTime!.minute);
            }
            generatedTasks.add(TaskItem(
              title: title,
              description: description.isEmpty ? null : description,
              dueDate: taskDueDate,
              hasTime: _dueTime != null,
              priority: _priority,
              createdAt: DateTime.now(),
              type: _type,
              iconKey: _iconKey,
              alarmEnabled: _alarmEnabled,
              subject: subject.isEmpty ? null : subject,
              recurrenceGroupId: groupId,
            ));
          }
          current = current.add(const Duration(days: 1));
        }

        if (generatedTasks.isEmpty) {
          AppSnack.show(context, 'No hay días que coincidan en el rango seleccionado');
          return;
        }

        await widget.cubit.addRepetitiveTasks(generatedTasks);
        AppSnack.success(context, '${generatedTasks.length} tareas creadas');
      } else {
        final taskToSave = TaskItem(
          title: title,
          description: description.isEmpty ? null : description,
          dueDate: _dueDate,
          hasTime: _dueTime != null,
          priority: _priority,
          createdAt: DateTime.now(),
          type: _type,
          iconKey: _iconKey,
          alarmEnabled: _alarmEnabled,
          subject: subject.isEmpty ? null : subject,
        );
        await widget.cubit.addTask(taskToSave);
        AppSnack.success(context, 'Guardada exitosamente');
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _delete() {
    final task = widget.task!;
    widget.cubit.deleteTask(task.id!);
    Navigator.of(context).pop();
    AppSnack.undo(
      context,
      message: 'Tarea eliminada',
      onUndo: () => widget.cubit.addTask(task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isExam = _type == TaskType.examen;
    final isPersonal = _type == TaskType.eventoImportante;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar' : 'Nuevo',
                      style: theme.textTheme.sectionTitle,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: _delete,
                      icon: const Icon(Symbols.delete_rounded),
                      color: colorScheme.error,
                      tooltip: 'Eliminar',
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<TaskType>(
                segments: const [
                  ButtonSegment(value: TaskType.tarea, label: Text('Tarea')),
                  ButtonSegment(value: TaskType.examen, label: Text('Examen')),
                  ButtonSegment(value: TaskType.eventoImportante, label: Text('Personal')),
                ],
                selected: {_type},
                onSelectionChanged: (selection) => setState(() => _type = selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSize(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isExam) ...[
                      TextFormField(
                        controller: _titleController,
                        autofocus: !_isEditing,
                        decoration: const InputDecoration(labelText: 'Título'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa un título' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!isPersonal) ...[
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: _subjectController.text),
                        optionsBuilder: (value) {
                          if (value.text.isEmpty) return widget.subjectOptions;
                          final query = value.text.toLowerCase();
                          return widget.subjectOptions.where((s) => s.toLowerCase().contains(query));
                        },
                        onSelected: (selection) => _subjectController.text = selection,
                        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                          controller.text = _subjectController.text;
                          controller.addListener(() => _subjectController.text = controller.text);
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: isExam ? 'Materia (Obligatorio)' : 'Materia (Opcional)',
                            ),
                            validator: isExam
                                ? (value) => value == null || value.trim().isEmpty
                                    ? 'Ingresa la materia para el examen'
                                    : null
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),

              if (!_isEditing && !isExam) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hacer repetitiva'),
                  value: _isRepetitive,
                  onChanged: (value) => setState(() => _isRepetitive = value),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_isPartOfSeries) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Symbols.event_repeat_rounded, size: AppIconSize.sm, color: colorScheme.onSecondaryContainer),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Tarea Repetitiva',
                              style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSecondaryContainer),
                            ),
                          ),
                          Switch(
                            value: _updateSeries,
                            onChanged: (val) => setState(() => _updateSeries = val),
                          )
                        ],
                      ),
                      if (_updateSeries) ...[
                        Text(
                          'Los cambios aplicarán para esta tarea y todas las futuras de este día en la serie.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSecondaryContainer),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(
                            initial: _updateSeriesUntil,
                            onPicked: (d) => _updateSeriesUntil = d,
                          ),
                          icon: const Icon(Symbols.calendar_month_rounded, size: AppIconSize.sm),
                          label: Text(_updateSeriesUntil == null ? 'Cambiar hasta... (Infinito)' : 'Hasta el ${DateFormat("d MMM, y", 'es_MX').format(_updateSeriesUntil!)}'),
                        ),
                        if (_updateSeriesUntil != null)
                          TextButton(
                            onPressed: () => setState(() => _updateSeriesUntil = null),
                            child: const Text('Quitar límite'),
                          )
                      ] else ...[
                        Text(
                          'Solo se actualizará este evento individual.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSecondaryContainer),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AnimatedSize(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                child: _isRepetitive && !_isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Días de la semana', style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              for (var i = 1; i <= 7; i++)
                                FilterChip(
                                  label: Text(['L', 'M', 'X', 'J', 'V', 'S', 'D'][i - 1]),
                                  selected: _selectedDays.contains(i),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDays.add(i);
                                      } else {
                                        _selectedDays.remove(i);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _pickDate(initial: _recurrenceStartDate, onPicked: (d) {
                                    _recurrenceStartDate = d;
                                    if (_recurrenceEndDate != null && d.isAfter(_recurrenceEndDate!)) {
                                      _recurrenceEndDate = d.add(const Duration(days: 1));
                                    }
                                  }),
                                  child: Text(_recurrenceStartDate == null ? 'Inicio' : DateFormat("d MMM", 'es_MX').format(_recurrenceStartDate!)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _pickDate(initial: _recurrenceEndDate, onPicked: (d) {
                                    _recurrenceEndDate = d;
                                    if (_recurrenceStartDate != null && d.isBefore(_recurrenceStartDate!)) {
                                      _recurrenceStartDate = d.subtract(const Duration(days: 1));
                                    }
                                  }),
                                  child: Text(_recurrenceEndDate == null ? 'Fin' : DateFormat("d MMM", 'es_MX').format(_recurrenceEndDate!)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: _pickDueTime,
                            icon: const Icon(Symbols.schedule_rounded, size: AppIconSize.sm),
                            label: Text(_dueTime == null ? 'Hora (Opcional)' : _dueTime!.format(context)),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(initial: _dueDate, onPicked: (d) {
                                if (_dueDate != null) {
                                  _dueDate = DateTime(d.year, d.month, d.day, _dueDate!.hour, _dueDate!.minute);
                                } else {
                                  _dueDate = d;
                                }
                              }),
                              icon: const Icon(Symbols.event_rounded, size: AppIconSize.sm),
                              label: Text(
                                _dueDate == null
                                    ? (isExam ? 'Fecha del examen' : 'Fecha límite')
                                    : DateFormat("d MMM, y", 'es_MX').format(_dueDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: _pickDueTime,
                              icon: const Icon(Symbols.schedule_rounded, size: AppIconSize.sm),
                              label: Text(
                                _dueTime == null ? 'Hora' : _dueTime!.format(context),
                              ),
                            ),
                          ),
                          if (_dueDate != null || _dueTime != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _dueDate = null;
                                  _dueTime = null;
                                });
                              },
                              icon: const Icon(Symbols.close_rounded),
                              tooltip: 'Limpiar fecha',
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Prioridad',
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(value: TaskPriority.low, label: Text('Baja')),
                  ButtonSegment(value: TaskPriority.medium, label: Text('Media')),
                  ButtonSegment(value: TaskPriority.high, label: Text('Alta')),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) => setState(() => _priority = selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Ícono',
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              ...taskIconCategories.entries.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.key,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: category.value.entries.map((entry) {
                          return _IconChoice(
                            icon: entry.value,
                            selected: entry.key == _iconKey,
                            onTap: () => setState(() => _iconKey = entry.key),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Programar alarma'),
                value: _alarmEnabled,
                onChanged: (value) => setState(() => _alarmEnabled = value),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Guardar cambios' : 'Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

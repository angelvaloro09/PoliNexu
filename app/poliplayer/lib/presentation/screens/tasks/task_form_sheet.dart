import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/task_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/task_item.dart';
import '../../blocs/tasks/tasks_cubit.dart';
import '../../widgets/app_snack.dart';

/// Abre el formulario de alta/edición de una tarea. Pasa [task] para editar
/// una existente; omítelo para crear una nueva. [subjectOptions] alimenta el
/// autocompletado de materia (normalmente las materias del horario actual).
void showTaskFormSheet(
  BuildContext context, {
  required TasksCubit cubit,
  TaskItem? task,
  List<String> subjectOptions = const [],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // La forma y el asa de arrastre vienen del `bottomSheetTheme`; antes se
    // pasaban a mano en esta llamada y no había asa.
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
  late TaskPriority _priority;
  late TaskType _type;
  late String _iconKey;
  late bool _alarmEnabled;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _subjectController = TextEditingController(text: widget.task?.subject ?? '');
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _type = widget.task?.type ?? TaskType.tarea;
    _iconKey = widget.task?.iconKey ?? defaultTaskIconKey;
    _alarmEnabled = widget.task?.alarmEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final subject = _subjectController.text.trim();

    if (_isEditing) {
      widget.cubit.updateTask(widget.task!.copyWith(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        priority: _priority,
        type: _type,
        iconKey: _iconKey,
        alarmEnabled: _alarmEnabled,
        subject: subject.isEmpty ? null : subject,
      ));
    } else {
      widget.cubit.addTask(TaskItem(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        priority: _priority,
        createdAt: DateTime.now(),
        type: _type,
        iconKey: _iconKey,
        alarmEnabled: _alarmEnabled,
        subject: subject.isEmpty ? null : subject,
      ));
    }

    Navigator.of(context).pop();
    AppSnack.success(context, _isEditing ? 'Tarea actualizada' : 'Tarea creada');
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
                  // Borrar sólo se podía deslizando en la lista: quien abre la
                  // tarea para editarla no tenía forma de eliminarla desde aquí.
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
                  ButtonSegment(value: TaskType.eventoImportante, label: Text('Evento')),
                ],
                selected: {_type},
                onSelectionChanged: (selection) => setState(() => _type = selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa un título' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _subjectController.text),
                optionsBuilder: (value) {
                  if (value.text.isEmpty) return widget.subjectOptions;
                  final query = value.text.toLowerCase();
                  return widget.subjectOptions
                      .where((s) => s.toLowerCase().contains(query));
                },
                onSelected: (selection) => _subjectController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  // Sincroniza el controller real (el de Autocomplete es interno)
                  // con el que se usa para guardar en `_submit`.
                  controller.text = _subjectController.text;
                  controller.addListener(() => _subjectController.text = controller.text);
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Materia (opcional)'),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Symbols.event_rounded, size: AppIconSize.sm),
                      label: Text(
                        _dueDate == null
                            ? 'Fecha límite'
                            : DateFormat("d 'de' MMMM, y", 'es_MX').format(_dueDate!),
                      ),
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Symbols.close_rounded),
                      tooltip: 'Quitar fecha',
                    ),
                ],
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
              const SizedBox(height: AppSpacing.md),
              Text('Ícono',
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final entry in taskIcons.entries)
                    _IconChoice(
                      icon: entry.value,
                      selected: entry.key == _iconKey,
                      onTap: () => setState(() => _iconKey = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
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

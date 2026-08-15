import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/task_item.dart';
import '../../blocs/tasks/tasks_cubit.dart';
import '../../widgets/app_snack.dart';

/// Abre el formulario de alta/edición de una tarea. Pasa [task] para editar
/// una existente; omítelo para crear una nueva.
void showTaskFormSheet(BuildContext context, {required TasksCubit cubit, TaskItem? task}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // La forma y el asa de arrastre vienen del `bottomSheetTheme`; antes se
    // pasaban a mano en esta llamada y no había asa.
    useSafeArea: true,
    builder: (_) => _TaskFormSheet(cubit: cubit, task: task),
  );
}

class _TaskFormSheet extends StatefulWidget {
  final TasksCubit cubit;
  final TaskItem? task;

  const _TaskFormSheet({required this.cubit, this.task});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _dueDate;
  late TaskPriority _priority;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

    if (_isEditing) {
      widget.cubit.updateTask(widget.task!.copyWith(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        priority: _priority,
      ));
    } else {
      widget.cubit.addTask(TaskItem(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        priority: _priority,
        createdAt: DateTime.now(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Editar tarea' : 'Nueva tarea',
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
                    tooltip: 'Eliminar tarea',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _titleController,
              autofocus: !_isEditing,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              minLines: 1,
              maxLines: 3,
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
            Text('Prioridad', style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant)),
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
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'Guardar cambios' : 'Crear tarea'),
            ),
          ],
        ),
      ),
    );
  }
}

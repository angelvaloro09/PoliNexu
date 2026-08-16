import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/task_item.dart';
import '../../../domain/repositories/notification_service.dart';
import '../../../domain/repositories/task_repository.dart';
import 'tasks_state.dart';

/// A diferencia de los demás Cubits (que hacen `loadX()` sobre HTTP), este se
/// suscribe al `Stream` reactivo de Drift — la UI se actualiza sola ante
/// cualquier cambio en la base local, sin necesidad de refrescar manualmente.
class TasksCubit extends Cubit<TasksState> {
  final TaskRepository _repository;
  final NotificationService _notificationService;
  StreamSubscription<List<TaskItem>>? _subscription;

  TasksCubit(this._repository, this._notificationService) : super(const TasksInitial()) {
    _subscription = _repository.watchTasks().listen(
          (tasks) => emit(TasksLoaded(tasks)),
          onError: (Object e) => emit(TasksError(e.toString())),
        );
  }

  Future<void> addTask(TaskItem task) async {
    final saved = await _repository.addTask(task);
    await _notificationService.scheduleTaskReminder(saved);
  }

  Future<void> updateTask(TaskItem task) async {
    await _repository.updateTask(task);
    await _notificationService.scheduleTaskReminder(task);
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await _notificationService.cancelTaskReminder(id);
  }

  Future<void> toggleCompleted(TaskItem task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _repository.updateTask(updated);
    // scheduleTaskReminder cancela internamente si ya quedó completada.
    await _notificationService.scheduleTaskReminder(updated);
  }

  Future<void> addRepetitiveTasks(List<TaskItem> tasks) async {
    for (final task in tasks) {
      await addTask(task);
    }
  }

  Future<void> updateRepetitiveTaskSeries(TaskItem editedTask, DateTime editedTaskOriginalDate, {DateTime? untilDate}) async {
    if (state is! TasksLoaded) return;
    if (editedTask.recurrenceGroupId == null) return;
    if (editedTask.dueDate == null) return;

    final allTasks = (state as TasksLoaded).tasks;
    final groupTasks = allTasks.where((t) => t.recurrenceGroupId == editedTask.recurrenceGroupId && t.dueDate != null).toList();

    for (final task in groupTasks) {
      // 1. Mismo día de la semana
      if (task.dueDate!.weekday != editedTaskOriginalDate.weekday) continue;
      
      // 2. Evento futuro (incluye el día actual)
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final editDate = DateTime(editedTaskOriginalDate.year, editedTaskOriginalDate.month, editedTaskOriginalDate.day);
      if (taskDate.isBefore(editDate)) continue;

      // 3. Límite opcional
      if (untilDate != null) {
        final until = DateTime(untilDate.year, untilDate.month, untilDate.day);
        if (taskDate.isAfter(until)) continue;
      }

      DateTime updatedDueDate = task.dueDate!;
      if (editedTask.hasTime) {
        updatedDueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
          editedTask.dueDate!.hour,
          editedTask.dueDate!.minute,
        );
      } else {
        updatedDueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      }

      final updatedTask = task.copyWith(
        title: editedTask.title,
        description: editedTask.description,
        dueDate: updatedDueDate,
        hasTime: editedTask.hasTime,
        priority: editedTask.priority,
        type: editedTask.type,
        iconKey: editedTask.iconKey,
        alarmEnabled: editedTask.alarmEnabled,
        subject: editedTask.subject,
      );

      await updateTask(updatedTask);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

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

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

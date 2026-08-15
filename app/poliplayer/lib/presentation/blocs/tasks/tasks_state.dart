import '../../../domain/models/task_item.dart';

sealed class TasksState {
  const TasksState();
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

class TasksLoaded extends TasksState {
  final List<TaskItem> tasks;
  const TasksLoaded(this.tasks);
}

class TasksError extends TasksState {
  final String message;
  const TasksError(this.message);
}

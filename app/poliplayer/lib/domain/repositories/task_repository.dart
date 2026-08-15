import '../models/task_item.dart';

abstract class TaskRepository {
  Stream<List<TaskItem>> watchTasks();

  /// Retorna la tarea insertada con su `id` asignado por la base de datos —
  /// lo necesita el llamador para poder programar su recordatorio.
  Future<TaskItem> addTask(TaskItem task);

  Future<void> updateTask(TaskItem task);
  Future<void> deleteTask(int id);
}

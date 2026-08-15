import 'package:drift/drift.dart' show Value;
import '../../domain/models/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../database/app_database.dart';

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;

  TaskRepositoryImpl(this._db);

  @override
  Stream<List<TaskItem>> watchTasks() {
    return _db.watchAllTasks().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<TaskItem> addTask(TaskItem task) async {
    final id = await _db.insertTask(TasksCompanion.insert(
      title: task.title,
      description: Value(task.description),
      dueDate: Value(task.dueDate),
      priority: Value(task.priority.index),
    ));
    return TaskItem(
      id: id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
      priority: task.priority,
      createdAt: task.createdAt,
    );
  }

  @override
  Future<void> updateTask(TaskItem task) {
    return _db.updateTask(Task(
      id: task.id!,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
      priority: task.priority.index,
      createdAt: task.createdAt,
    ));
  }

  @override
  Future<void> deleteTask(int id) => _db.deleteTask(id);

  TaskItem _toDomain(Task row) => TaskItem(
        id: row.id,
        title: row.title,
        description: row.description,
        dueDate: row.dueDate,
        isCompleted: row.isCompleted,
        priority: TaskPriority.fromValue(row.priority),
        createdAt: row.createdAt,
      );
}

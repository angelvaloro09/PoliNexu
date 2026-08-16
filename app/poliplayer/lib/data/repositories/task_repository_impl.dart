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
      hasTime: Value(task.hasTime),
      priority: Value(task.priority.index),
      type: Value(task.type.index),
      iconKey: Value(task.iconKey),
      alarmEnabled: Value(task.alarmEnabled),
      subject: Value(task.subject),
    ));
    return TaskItem(
      id: id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      hasTime: task.hasTime,
      isCompleted: task.isCompleted,
      priority: task.priority,
      createdAt: task.createdAt,
      type: task.type,
      iconKey: task.iconKey,
      alarmEnabled: task.alarmEnabled,
      subject: task.subject,
    );
  }

  @override
  Future<void> updateTask(TaskItem task) {
    return _db.updateTask(Task(
      id: task.id!,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      hasTime: task.hasTime,
      isCompleted: task.isCompleted,
      priority: task.priority.index,
      createdAt: task.createdAt,
      type: task.type.index,
      iconKey: task.iconKey,
      alarmEnabled: task.alarmEnabled,
      subject: task.subject,
    ));
  }

  @override
  Future<void> deleteTask(int id) => _db.deleteTask(id);

  TaskItem _toDomain(Task row) => TaskItem(
        id: row.id,
        title: row.title,
        description: row.description,
        dueDate: row.dueDate,
        hasTime: row.hasTime,
        isCompleted: row.isCompleted,
        priority: TaskPriority.fromValue(row.priority),
        createdAt: row.createdAt,
        type: TaskType.fromValue(row.type),
        iconKey: row.iconKey,
        alarmEnabled: row.alarmEnabled,
        subject: row.subject,
      );
}

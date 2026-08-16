enum TaskPriority {
  low,
  medium,
  high;

  static TaskPriority fromValue(int value) => TaskPriority.values[value.clamp(0, 2)];
}

enum TaskType {
  tarea,
  examen,
  eventoImportante;

  static TaskType fromValue(int value) => TaskType.values[value.clamp(0, 2)];
}

class TaskItem {
  final int? id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool hasTime;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime createdAt;
  final TaskType type;
  final String? iconKey;
  final bool alarmEnabled;
  final String? subject;
  final String? recurrenceGroupId;

  const TaskItem({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.hasTime = false,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    this.type = TaskType.tarea,
    this.iconKey,
    this.alarmEnabled = true,
    this.subject,
    this.recurrenceGroupId,
  });

  TaskItem copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? hasTime,
    bool? isCompleted,
    TaskPriority? priority,
    TaskType? type,
    String? iconKey,
    bool? alarmEnabled,
    String? subject,
    String? recurrenceGroupId,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      subject: subject ?? this.subject,
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
    );
  }
}

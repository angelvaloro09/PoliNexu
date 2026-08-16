// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmEnabledMeta = const VerificationMeta(
    'alarmEnabled',
  );
  @override
  late final GeneratedColumn<bool> alarmEnabled = GeneratedColumn<bool>(
    'alarm_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alarm_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    dueDate,
    isCompleted,
    priority,
    createdAt,
    type,
    iconKey,
    alarmEnabled,
    subject,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('alarm_enabled')) {
      context.handle(
        _alarmEnabledMeta,
        alarmEnabled.isAcceptableOrUnknown(
          data['alarm_enabled']!,
          _alarmEnabledMeta,
        ),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      alarmEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alarm_enabled'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final int priority;
  final DateTime createdAt;
  final int type;
  final String? iconKey;
  final bool alarmEnabled;
  final String? subject;
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.isCompleted,
    required this.priority,
    required this.createdAt,
    required this.type,
    this.iconKey,
    required this.alarmEnabled,
    this.subject,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['priority'] = Variable<int>(priority);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['type'] = Variable<int>(type);
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    map['alarm_enabled'] = Variable<bool>(alarmEnabled);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isCompleted: Value(isCompleted),
      priority: Value(priority),
      createdAt: Value(createdAt),
      type: Value(type),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      alarmEnabled: Value(alarmEnabled),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      priority: serializer.fromJson<int>(json['priority']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      type: serializer.fromJson<int>(json['type']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      alarmEnabled: serializer.fromJson<bool>(json['alarmEnabled']),
      subject: serializer.fromJson<String?>(json['subject']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'priority': serializer.toJson<int>(priority),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'type': serializer.toJson<int>(type),
      'iconKey': serializer.toJson<String?>(iconKey),
      'alarmEnabled': serializer.toJson<bool>(alarmEnabled),
      'subject': serializer.toJson<String?>(subject),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    bool? isCompleted,
    int? priority,
    DateTime? createdAt,
    int? type,
    Value<String?> iconKey = const Value.absent(),
    bool? alarmEnabled,
    Value<String?> subject = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    type: type ?? this.type,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    subject: subject.present ? subject.value : this.subject,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      priority: data.priority.present ? data.priority.value : this.priority,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      alarmEnabled: data.alarmEnabled.present
          ? data.alarmEnabled.value
          : this.alarmEnabled,
      subject: data.subject.present ? data.subject.value : this.subject,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('iconKey: $iconKey, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    dueDate,
    isCompleted,
    priority,
    createdAt,
    type,
    iconKey,
    alarmEnabled,
    subject,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.dueDate == this.dueDate &&
          other.isCompleted == this.isCompleted &&
          other.priority == this.priority &&
          other.createdAt == this.createdAt &&
          other.type == this.type &&
          other.iconKey == this.iconKey &&
          other.alarmEnabled == this.alarmEnabled &&
          other.subject == this.subject);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime?> dueDate;
  final Value<bool> isCompleted;
  final Value<int> priority;
  final Value<DateTime> createdAt;
  final Value<int> type;
  final Value<String?> iconKey;
  final Value<bool> alarmEnabled;
  final Value<String?> subject;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.priority = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.alarmEnabled = const Value.absent(),
    this.subject = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.priority = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.alarmEnabled = const Value.absent(),
    this.subject = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? dueDate,
    Expression<bool>? isCompleted,
    Expression<int>? priority,
    Expression<DateTime>? createdAt,
    Expression<int>? type,
    Expression<String>? iconKey,
    Expression<bool>? alarmEnabled,
    Expression<String>? subject,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (priority != null) 'priority': priority,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
      if (iconKey != null) 'icon_key': iconKey,
      if (alarmEnabled != null) 'alarm_enabled': alarmEnabled,
      if (subject != null) 'subject': subject,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime?>? dueDate,
    Value<bool>? isCompleted,
    Value<int>? priority,
    Value<DateTime>? createdAt,
    Value<int>? type,
    Value<String?>? iconKey,
    Value<bool>? alarmEnabled,
    Value<String?>? subject,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      subject: subject ?? this.subject,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (alarmEnabled.present) {
      map['alarm_enabled'] = Variable<bool>(alarmEnabled.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('iconKey: $iconKey, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('subject: $subject')
          ..write(')'))
        .toString();
  }
}

class $GradeSnapshotsTable extends GradeSnapshots
    with TableInfo<$GradeSnapshotsTable, GradeSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradeSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectKeyMeta = const VerificationMeta(
    'subjectKey',
  );
  @override
  late final GeneratedColumn<String> subjectKey = GeneratedColumn<String>(
    'subject_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalGradeMeta = const VerificationMeta(
    'finalGrade',
  );
  @override
  late final GeneratedColumn<String> finalGrade = GeneratedColumn<String>(
    'final_grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [subjectKey, finalGrade];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grade_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<GradeSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_key')) {
      context.handle(
        _subjectKeyMeta,
        subjectKey.isAcceptableOrUnknown(data['subject_key']!, _subjectKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectKeyMeta);
    }
    if (data.containsKey('final_grade')) {
      context.handle(
        _finalGradeMeta,
        finalGrade.isAcceptableOrUnknown(data['final_grade']!, _finalGradeMeta),
      );
    } else if (isInserting) {
      context.missing(_finalGradeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectKey};
  @override
  GradeSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradeSnapshot(
      subjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_key'],
      )!,
      finalGrade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_grade'],
      )!,
    );
  }

  @override
  $GradeSnapshotsTable createAlias(String alias) {
    return $GradeSnapshotsTable(attachedDatabase, alias);
  }
}

class GradeSnapshot extends DataClass implements Insertable<GradeSnapshot> {
  final String subjectKey;
  final String finalGrade;
  const GradeSnapshot({required this.subjectKey, required this.finalGrade});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_key'] = Variable<String>(subjectKey);
    map['final_grade'] = Variable<String>(finalGrade);
    return map;
  }

  GradeSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return GradeSnapshotsCompanion(
      subjectKey: Value(subjectKey),
      finalGrade: Value(finalGrade),
    );
  }

  factory GradeSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradeSnapshot(
      subjectKey: serializer.fromJson<String>(json['subjectKey']),
      finalGrade: serializer.fromJson<String>(json['finalGrade']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectKey': serializer.toJson<String>(subjectKey),
      'finalGrade': serializer.toJson<String>(finalGrade),
    };
  }

  GradeSnapshot copyWith({String? subjectKey, String? finalGrade}) =>
      GradeSnapshot(
        subjectKey: subjectKey ?? this.subjectKey,
        finalGrade: finalGrade ?? this.finalGrade,
      );
  GradeSnapshot copyWithCompanion(GradeSnapshotsCompanion data) {
    return GradeSnapshot(
      subjectKey: data.subjectKey.present
          ? data.subjectKey.value
          : this.subjectKey,
      finalGrade: data.finalGrade.present
          ? data.finalGrade.value
          : this.finalGrade,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradeSnapshot(')
          ..write('subjectKey: $subjectKey, ')
          ..write('finalGrade: $finalGrade')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subjectKey, finalGrade);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradeSnapshot &&
          other.subjectKey == this.subjectKey &&
          other.finalGrade == this.finalGrade);
}

class GradeSnapshotsCompanion extends UpdateCompanion<GradeSnapshot> {
  final Value<String> subjectKey;
  final Value<String> finalGrade;
  final Value<int> rowid;
  const GradeSnapshotsCompanion({
    this.subjectKey = const Value.absent(),
    this.finalGrade = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GradeSnapshotsCompanion.insert({
    required String subjectKey,
    required String finalGrade,
    this.rowid = const Value.absent(),
  }) : subjectKey = Value(subjectKey),
       finalGrade = Value(finalGrade);
  static Insertable<GradeSnapshot> custom({
    Expression<String>? subjectKey,
    Expression<String>? finalGrade,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectKey != null) 'subject_key': subjectKey,
      if (finalGrade != null) 'final_grade': finalGrade,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GradeSnapshotsCompanion copyWith({
    Value<String>? subjectKey,
    Value<String>? finalGrade,
    Value<int>? rowid,
  }) {
    return GradeSnapshotsCompanion(
      subjectKey: subjectKey ?? this.subjectKey,
      finalGrade: finalGrade ?? this.finalGrade,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectKey.present) {
      map['subject_key'] = Variable<String>(subjectKey.value);
    }
    if (finalGrade.present) {
      map['final_grade'] = Variable<String>(finalGrade.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradeSnapshotsCompanion(')
          ..write('subjectKey: $subjectKey, ')
          ..write('finalGrade: $finalGrade, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteCacheEntriesTable extends RemoteCacheEntries
    with TableInfo<$RemoteCacheEntriesTable, RemoteCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, payloadJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  RemoteCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteCacheEntry(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $RemoteCacheEntriesTable createAlias(String alias) {
    return $RemoteCacheEntriesTable(attachedDatabase, alias);
  }
}

class RemoteCacheEntry extends DataClass
    implements Insertable<RemoteCacheEntry> {
  final String cacheKey;
  final String payloadJson;
  final DateTime fetchedAt;
  const RemoteCacheEntry({
    required this.cacheKey,
    required this.payloadJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  RemoteCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return RemoteCacheEntriesCompanion(
      cacheKey: Value(cacheKey),
      payloadJson: Value(payloadJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory RemoteCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteCacheEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  RemoteCacheEntry copyWith({
    String? cacheKey,
    String? payloadJson,
    DateTime? fetchedAt,
  }) => RemoteCacheEntry(
    cacheKey: cacheKey ?? this.cacheKey,
    payloadJson: payloadJson ?? this.payloadJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  RemoteCacheEntry copyWithCompanion(RemoteCacheEntriesCompanion data) {
    return RemoteCacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteCacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, payloadJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteCacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.payloadJson == this.payloadJson &&
          other.fetchedAt == this.fetchedAt);
}

class RemoteCacheEntriesCompanion extends UpdateCompanion<RemoteCacheEntry> {
  final Value<String> cacheKey;
  final Value<String> payloadJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const RemoteCacheEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteCacheEntriesCompanion.insert({
    required String cacheKey,
    required String payloadJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       payloadJson = Value(payloadJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<RemoteCacheEntry> custom({
    Expression<String>? cacheKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteCacheEntriesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? payloadJson,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return RemoteCacheEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteCacheEntriesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppFlagsTable extends AppFlags with TableInfo<$AppFlagsTable, AppFlag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppFlagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _flagKeyMeta = const VerificationMeta(
    'flagKey',
  );
  @override
  late final GeneratedColumn<String> flagKey = GeneratedColumn<String>(
    'flag_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [flagKey, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppFlag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('flag_key')) {
      context.handle(
        _flagKeyMeta,
        flagKey.isAcceptableOrUnknown(data['flag_key']!, _flagKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_flagKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {flagKey};
  @override
  AppFlag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppFlag(
      flagKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flag_key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppFlagsTable createAlias(String alias) {
    return $AppFlagsTable(attachedDatabase, alias);
  }
}

class AppFlag extends DataClass implements Insertable<AppFlag> {
  final String flagKey;
  final String value;
  const AppFlag({required this.flagKey, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['flag_key'] = Variable<String>(flagKey);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppFlagsCompanion toCompanion(bool nullToAbsent) {
    return AppFlagsCompanion(flagKey: Value(flagKey), value: Value(value));
  }

  factory AppFlag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppFlag(
      flagKey: serializer.fromJson<String>(json['flagKey']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'flagKey': serializer.toJson<String>(flagKey),
      'value': serializer.toJson<String>(value),
    };
  }

  AppFlag copyWith({String? flagKey, String? value}) =>
      AppFlag(flagKey: flagKey ?? this.flagKey, value: value ?? this.value);
  AppFlag copyWithCompanion(AppFlagsCompanion data) {
    return AppFlag(
      flagKey: data.flagKey.present ? data.flagKey.value : this.flagKey,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppFlag(')
          ..write('flagKey: $flagKey, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(flagKey, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppFlag &&
          other.flagKey == this.flagKey &&
          other.value == this.value);
}

class AppFlagsCompanion extends UpdateCompanion<AppFlag> {
  final Value<String> flagKey;
  final Value<String> value;
  final Value<int> rowid;
  const AppFlagsCompanion({
    this.flagKey = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppFlagsCompanion.insert({
    required String flagKey,
    required String value,
    this.rowid = const Value.absent(),
  }) : flagKey = Value(flagKey),
       value = Value(value);
  static Insertable<AppFlag> custom({
    Expression<String>? flagKey,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (flagKey != null) 'flag_key': flagKey,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppFlagsCompanion copyWith({
    Value<String>? flagKey,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppFlagsCompanion(
      flagKey: flagKey ?? this.flagKey,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (flagKey.present) {
      map['flag_key'] = Variable<String>(flagKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppFlagsCompanion(')
          ..write('flagKey: $flagKey, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubjectPreferencesTable extends SubjectPreferences
    with TableInfo<$SubjectPreferencesTable, SubjectPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectKeyMeta = const VerificationMeta(
    'subjectKey',
  );
  @override
  late final GeneratedColumn<String> subjectKey = GeneratedColumn<String>(
    'subject_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [subjectKey, colorValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_key')) {
      context.handle(
        _subjectKeyMeta,
        subjectKey.isAcceptableOrUnknown(data['subject_key']!, _subjectKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectKeyMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectKey};
  @override
  SubjectPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectPreference(
      subjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_key'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
    );
  }

  @override
  $SubjectPreferencesTable createAlias(String alias) {
    return $SubjectPreferencesTable(attachedDatabase, alias);
  }
}

class SubjectPreference extends DataClass
    implements Insertable<SubjectPreference> {
  final String subjectKey;
  final int? colorValue;
  const SubjectPreference({required this.subjectKey, this.colorValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_key'] = Variable<String>(subjectKey);
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    return map;
  }

  SubjectPreferencesCompanion toCompanion(bool nullToAbsent) {
    return SubjectPreferencesCompanion(
      subjectKey: Value(subjectKey),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
    );
  }

  factory SubjectPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectPreference(
      subjectKey: serializer.fromJson<String>(json['subjectKey']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectKey': serializer.toJson<String>(subjectKey),
      'colorValue': serializer.toJson<int?>(colorValue),
    };
  }

  SubjectPreference copyWith({
    String? subjectKey,
    Value<int?> colorValue = const Value.absent(),
  }) => SubjectPreference(
    subjectKey: subjectKey ?? this.subjectKey,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
  );
  SubjectPreference copyWithCompanion(SubjectPreferencesCompanion data) {
    return SubjectPreference(
      subjectKey: data.subjectKey.present
          ? data.subjectKey.value
          : this.subjectKey,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectPreference(')
          ..write('subjectKey: $subjectKey, ')
          ..write('colorValue: $colorValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subjectKey, colorValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectPreference &&
          other.subjectKey == this.subjectKey &&
          other.colorValue == this.colorValue);
}

class SubjectPreferencesCompanion extends UpdateCompanion<SubjectPreference> {
  final Value<String> subjectKey;
  final Value<int?> colorValue;
  final Value<int> rowid;
  const SubjectPreferencesCompanion({
    this.subjectKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectPreferencesCompanion.insert({
    required String subjectKey,
    this.colorValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : subjectKey = Value(subjectKey);
  static Insertable<SubjectPreference> custom({
    Expression<String>? subjectKey,
    Expression<int>? colorValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectKey != null) 'subject_key': subjectKey,
      if (colorValue != null) 'color_value': colorValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectPreferencesCompanion copyWith({
    Value<String>? subjectKey,
    Value<int?>? colorValue,
    Value<int>? rowid,
  }) {
    return SubjectPreferencesCompanion(
      subjectKey: subjectKey ?? this.subjectKey,
      colorValue: colorValue ?? this.colorValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectKey.present) {
      map['subject_key'] = Variable<String>(subjectKey.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectPreferencesCompanion(')
          ..write('subjectKey: $subjectKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduleOverridesTable extends ScheduleOverrides
    with TableInfo<$ScheduleOverridesTable, ScheduleOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectKeyMeta = const VerificationMeta(
    'subjectKey',
  );
  @override
  late final GeneratedColumn<String> subjectKey = GeneratedColumn<String>(
    'subject_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buildingMeta = const VerificationMeta(
    'building',
  );
  @override
  late final GeneratedColumn<String> building = GeneratedColumn<String>(
    'building',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classroomMeta = const VerificationMeta(
    'classroom',
  );
  @override
  late final GeneratedColumn<String> classroom = GeneratedColumn<String>(
    'classroom',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [subjectKey, day, building, classroom];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_key')) {
      context.handle(
        _subjectKeyMeta,
        subjectKey.isAcceptableOrUnknown(data['subject_key']!, _subjectKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectKeyMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('building')) {
      context.handle(
        _buildingMeta,
        building.isAcceptableOrUnknown(data['building']!, _buildingMeta),
      );
    }
    if (data.containsKey('classroom')) {
      context.handle(
        _classroomMeta,
        classroom.isAcceptableOrUnknown(data['classroom']!, _classroomMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectKey, day};
  @override
  ScheduleOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleOverride(
      subjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_key'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      building: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}building'],
      ),
      classroom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom'],
      ),
    );
  }

  @override
  $ScheduleOverridesTable createAlias(String alias) {
    return $ScheduleOverridesTable(attachedDatabase, alias);
  }
}

class ScheduleOverride extends DataClass
    implements Insertable<ScheduleOverride> {
  final String subjectKey;
  final String day;
  final String? building;
  final String? classroom;
  const ScheduleOverride({
    required this.subjectKey,
    required this.day,
    this.building,
    this.classroom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_key'] = Variable<String>(subjectKey);
    map['day'] = Variable<String>(day);
    if (!nullToAbsent || building != null) {
      map['building'] = Variable<String>(building);
    }
    if (!nullToAbsent || classroom != null) {
      map['classroom'] = Variable<String>(classroom);
    }
    return map;
  }

  ScheduleOverridesCompanion toCompanion(bool nullToAbsent) {
    return ScheduleOverridesCompanion(
      subjectKey: Value(subjectKey),
      day: Value(day),
      building: building == null && nullToAbsent
          ? const Value.absent()
          : Value(building),
      classroom: classroom == null && nullToAbsent
          ? const Value.absent()
          : Value(classroom),
    );
  }

  factory ScheduleOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleOverride(
      subjectKey: serializer.fromJson<String>(json['subjectKey']),
      day: serializer.fromJson<String>(json['day']),
      building: serializer.fromJson<String?>(json['building']),
      classroom: serializer.fromJson<String?>(json['classroom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectKey': serializer.toJson<String>(subjectKey),
      'day': serializer.toJson<String>(day),
      'building': serializer.toJson<String?>(building),
      'classroom': serializer.toJson<String?>(classroom),
    };
  }

  ScheduleOverride copyWith({
    String? subjectKey,
    String? day,
    Value<String?> building = const Value.absent(),
    Value<String?> classroom = const Value.absent(),
  }) => ScheduleOverride(
    subjectKey: subjectKey ?? this.subjectKey,
    day: day ?? this.day,
    building: building.present ? building.value : this.building,
    classroom: classroom.present ? classroom.value : this.classroom,
  );
  ScheduleOverride copyWithCompanion(ScheduleOverridesCompanion data) {
    return ScheduleOverride(
      subjectKey: data.subjectKey.present
          ? data.subjectKey.value
          : this.subjectKey,
      day: data.day.present ? data.day.value : this.day,
      building: data.building.present ? data.building.value : this.building,
      classroom: data.classroom.present ? data.classroom.value : this.classroom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleOverride(')
          ..write('subjectKey: $subjectKey, ')
          ..write('day: $day, ')
          ..write('building: $building, ')
          ..write('classroom: $classroom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subjectKey, day, building, classroom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleOverride &&
          other.subjectKey == this.subjectKey &&
          other.day == this.day &&
          other.building == this.building &&
          other.classroom == this.classroom);
}

class ScheduleOverridesCompanion extends UpdateCompanion<ScheduleOverride> {
  final Value<String> subjectKey;
  final Value<String> day;
  final Value<String?> building;
  final Value<String?> classroom;
  final Value<int> rowid;
  const ScheduleOverridesCompanion({
    this.subjectKey = const Value.absent(),
    this.day = const Value.absent(),
    this.building = const Value.absent(),
    this.classroom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleOverridesCompanion.insert({
    required String subjectKey,
    required String day,
    this.building = const Value.absent(),
    this.classroom = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : subjectKey = Value(subjectKey),
       day = Value(day);
  static Insertable<ScheduleOverride> custom({
    Expression<String>? subjectKey,
    Expression<String>? day,
    Expression<String>? building,
    Expression<String>? classroom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectKey != null) 'subject_key': subjectKey,
      if (day != null) 'day': day,
      if (building != null) 'building': building,
      if (classroom != null) 'classroom': classroom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleOverridesCompanion copyWith({
    Value<String>? subjectKey,
    Value<String>? day,
    Value<String?>? building,
    Value<String?>? classroom,
    Value<int>? rowid,
  }) {
    return ScheduleOverridesCompanion(
      subjectKey: subjectKey ?? this.subjectKey,
      day: day ?? this.day,
      building: building ?? this.building,
      classroom: classroom ?? this.classroom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectKey.present) {
      map['subject_key'] = Variable<String>(subjectKey.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (building.present) {
      map['building'] = Variable<String>(building.value);
    }
    if (classroom.present) {
      map['classroom'] = Variable<String>(classroom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleOverridesCompanion(')
          ..write('subjectKey: $subjectKey, ')
          ..write('day: $day, ')
          ..write('building: $building, ')
          ..write('classroom: $classroom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $GradeSnapshotsTable gradeSnapshots = $GradeSnapshotsTable(this);
  late final $RemoteCacheEntriesTable remoteCacheEntries =
      $RemoteCacheEntriesTable(this);
  late final $AppFlagsTable appFlags = $AppFlagsTable(this);
  late final $SubjectPreferencesTable subjectPreferences =
      $SubjectPreferencesTable(this);
  late final $ScheduleOverridesTable scheduleOverrides =
      $ScheduleOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    gradeSnapshots,
    remoteCacheEntries,
    appFlags,
    subjectPreferences,
    scheduleOverrides,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      Value<DateTime?> dueDate,
      Value<bool> isCompleted,
      Value<int> priority,
      Value<DateTime> createdAt,
      Value<int> type,
      Value<String?> iconKey,
      Value<bool> alarmEnabled,
      Value<String?> subject,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<DateTime?> dueDate,
      Value<bool> isCompleted,
      Value<int> priority,
      Value<DateTime> createdAt,
      Value<int> type,
      Value<String?> iconKey,
      Value<bool> alarmEnabled,
      Value<String?> subject,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<bool> alarmEnabled = const Value.absent(),
                Value<String?> subject = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                description: description,
                dueDate: dueDate,
                isCompleted: isCompleted,
                priority: priority,
                createdAt: createdAt,
                type: type,
                iconKey: iconKey,
                alarmEnabled: alarmEnabled,
                subject: subject,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<bool> alarmEnabled = const Value.absent(),
                Value<String?> subject = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                description: description,
                dueDate: dueDate,
                isCompleted: isCompleted,
                priority: priority,
                createdAt: createdAt,
                type: type,
                iconKey: iconKey,
                alarmEnabled: alarmEnabled,
                subject: subject,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$GradeSnapshotsTableCreateCompanionBuilder =
    GradeSnapshotsCompanion Function({
      required String subjectKey,
      required String finalGrade,
      Value<int> rowid,
    });
typedef $$GradeSnapshotsTableUpdateCompanionBuilder =
    GradeSnapshotsCompanion Function({
      Value<String> subjectKey,
      Value<String> finalGrade,
      Value<int> rowid,
    });

class $$GradeSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $GradeSnapshotsTable> {
  $$GradeSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalGrade => $composableBuilder(
    column: $table.finalGrade,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GradeSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $GradeSnapshotsTable> {
  $$GradeSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalGrade => $composableBuilder(
    column: $table.finalGrade,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GradeSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradeSnapshotsTable> {
  $$GradeSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalGrade => $composableBuilder(
    column: $table.finalGrade,
    builder: (column) => column,
  );
}

class $$GradeSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GradeSnapshotsTable,
          GradeSnapshot,
          $$GradeSnapshotsTableFilterComposer,
          $$GradeSnapshotsTableOrderingComposer,
          $$GradeSnapshotsTableAnnotationComposer,
          $$GradeSnapshotsTableCreateCompanionBuilder,
          $$GradeSnapshotsTableUpdateCompanionBuilder,
          (
            GradeSnapshot,
            BaseReferences<_$AppDatabase, $GradeSnapshotsTable, GradeSnapshot>,
          ),
          GradeSnapshot,
          PrefetchHooks Function()
        > {
  $$GradeSnapshotsTableTableManager(
    _$AppDatabase db,
    $GradeSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradeSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradeSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradeSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> subjectKey = const Value.absent(),
                Value<String> finalGrade = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GradeSnapshotsCompanion(
                subjectKey: subjectKey,
                finalGrade: finalGrade,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subjectKey,
                required String finalGrade,
                Value<int> rowid = const Value.absent(),
              }) => GradeSnapshotsCompanion.insert(
                subjectKey: subjectKey,
                finalGrade: finalGrade,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GradeSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GradeSnapshotsTable,
      GradeSnapshot,
      $$GradeSnapshotsTableFilterComposer,
      $$GradeSnapshotsTableOrderingComposer,
      $$GradeSnapshotsTableAnnotationComposer,
      $$GradeSnapshotsTableCreateCompanionBuilder,
      $$GradeSnapshotsTableUpdateCompanionBuilder,
      (
        GradeSnapshot,
        BaseReferences<_$AppDatabase, $GradeSnapshotsTable, GradeSnapshot>,
      ),
      GradeSnapshot,
      PrefetchHooks Function()
    >;
typedef $$RemoteCacheEntriesTableCreateCompanionBuilder =
    RemoteCacheEntriesCompanion Function({
      required String cacheKey,
      required String payloadJson,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$RemoteCacheEntriesTableUpdateCompanionBuilder =
    RemoteCacheEntriesCompanion Function({
      Value<String> cacheKey,
      Value<String> payloadJson,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$RemoteCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteCacheEntriesTable> {
  $$RemoteCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteCacheEntriesTable> {
  $$RemoteCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteCacheEntriesTable> {
  $$RemoteCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$RemoteCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteCacheEntriesTable,
          RemoteCacheEntry,
          $$RemoteCacheEntriesTableFilterComposer,
          $$RemoteCacheEntriesTableOrderingComposer,
          $$RemoteCacheEntriesTableAnnotationComposer,
          $$RemoteCacheEntriesTableCreateCompanionBuilder,
          $$RemoteCacheEntriesTableUpdateCompanionBuilder,
          (
            RemoteCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $RemoteCacheEntriesTable,
              RemoteCacheEntry
            >,
          ),
          RemoteCacheEntry,
          PrefetchHooks Function()
        > {
  $$RemoteCacheEntriesTableTableManager(
    _$AppDatabase db,
    $RemoteCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteCacheEntriesCompanion(
                cacheKey: cacheKey,
                payloadJson: payloadJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String payloadJson,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => RemoteCacheEntriesCompanion.insert(
                cacheKey: cacheKey,
                payloadJson: payloadJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteCacheEntriesTable,
      RemoteCacheEntry,
      $$RemoteCacheEntriesTableFilterComposer,
      $$RemoteCacheEntriesTableOrderingComposer,
      $$RemoteCacheEntriesTableAnnotationComposer,
      $$RemoteCacheEntriesTableCreateCompanionBuilder,
      $$RemoteCacheEntriesTableUpdateCompanionBuilder,
      (
        RemoteCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $RemoteCacheEntriesTable,
          RemoteCacheEntry
        >,
      ),
      RemoteCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$AppFlagsTableCreateCompanionBuilder =
    AppFlagsCompanion Function({
      required String flagKey,
      required String value,
      Value<int> rowid,
    });
typedef $$AppFlagsTableUpdateCompanionBuilder =
    AppFlagsCompanion Function({
      Value<String> flagKey,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppFlagsTableFilterComposer
    extends Composer<_$AppDatabase, $AppFlagsTable> {
  $$AppFlagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get flagKey => $composableBuilder(
    column: $table.flagKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppFlagsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppFlagsTable> {
  $$AppFlagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get flagKey => $composableBuilder(
    column: $table.flagKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppFlagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppFlagsTable> {
  $$AppFlagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get flagKey =>
      $composableBuilder(column: $table.flagKey, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppFlagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppFlagsTable,
          AppFlag,
          $$AppFlagsTableFilterComposer,
          $$AppFlagsTableOrderingComposer,
          $$AppFlagsTableAnnotationComposer,
          $$AppFlagsTableCreateCompanionBuilder,
          $$AppFlagsTableUpdateCompanionBuilder,
          (AppFlag, BaseReferences<_$AppDatabase, $AppFlagsTable, AppFlag>),
          AppFlag,
          PrefetchHooks Function()
        > {
  $$AppFlagsTableTableManager(_$AppDatabase db, $AppFlagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppFlagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppFlagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppFlagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> flagKey = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppFlagsCompanion(
                flagKey: flagKey,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String flagKey,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppFlagsCompanion.insert(
                flagKey: flagKey,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppFlagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppFlagsTable,
      AppFlag,
      $$AppFlagsTableFilterComposer,
      $$AppFlagsTableOrderingComposer,
      $$AppFlagsTableAnnotationComposer,
      $$AppFlagsTableCreateCompanionBuilder,
      $$AppFlagsTableUpdateCompanionBuilder,
      (AppFlag, BaseReferences<_$AppDatabase, $AppFlagsTable, AppFlag>),
      AppFlag,
      PrefetchHooks Function()
    >;
typedef $$SubjectPreferencesTableCreateCompanionBuilder =
    SubjectPreferencesCompanion Function({
      required String subjectKey,
      Value<int?> colorValue,
      Value<int> rowid,
    });
typedef $$SubjectPreferencesTableUpdateCompanionBuilder =
    SubjectPreferencesCompanion Function({
      Value<String> subjectKey,
      Value<int?> colorValue,
      Value<int> rowid,
    });

class $$SubjectPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectPreferencesTable> {
  $$SubjectPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubjectPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectPreferencesTable> {
  $$SubjectPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectPreferencesTable> {
  $$SubjectPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );
}

class $$SubjectPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectPreferencesTable,
          SubjectPreference,
          $$SubjectPreferencesTableFilterComposer,
          $$SubjectPreferencesTableOrderingComposer,
          $$SubjectPreferencesTableAnnotationComposer,
          $$SubjectPreferencesTableCreateCompanionBuilder,
          $$SubjectPreferencesTableUpdateCompanionBuilder,
          (
            SubjectPreference,
            BaseReferences<
              _$AppDatabase,
              $SubjectPreferencesTable,
              SubjectPreference
            >,
          ),
          SubjectPreference,
          PrefetchHooks Function()
        > {
  $$SubjectPreferencesTableTableManager(
    _$AppDatabase db,
    $SubjectPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> subjectKey = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectPreferencesCompanion(
                subjectKey: subjectKey,
                colorValue: colorValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subjectKey,
                Value<int?> colorValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectPreferencesCompanion.insert(
                subjectKey: subjectKey,
                colorValue: colorValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubjectPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectPreferencesTable,
      SubjectPreference,
      $$SubjectPreferencesTableFilterComposer,
      $$SubjectPreferencesTableOrderingComposer,
      $$SubjectPreferencesTableAnnotationComposer,
      $$SubjectPreferencesTableCreateCompanionBuilder,
      $$SubjectPreferencesTableUpdateCompanionBuilder,
      (
        SubjectPreference,
        BaseReferences<
          _$AppDatabase,
          $SubjectPreferencesTable,
          SubjectPreference
        >,
      ),
      SubjectPreference,
      PrefetchHooks Function()
    >;
typedef $$ScheduleOverridesTableCreateCompanionBuilder =
    ScheduleOverridesCompanion Function({
      required String subjectKey,
      required String day,
      Value<String?> building,
      Value<String?> classroom,
      Value<int> rowid,
    });
typedef $$ScheduleOverridesTableUpdateCompanionBuilder =
    ScheduleOverridesCompanion Function({
      Value<String> subjectKey,
      Value<String> day,
      Value<String?> building,
      Value<String?> classroom,
      Value<int> rowid,
    });

class $$ScheduleOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleOverridesTable> {
  $$ScheduleOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get building => $composableBuilder(
    column: $table.building,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classroom => $composableBuilder(
    column: $table.classroom,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduleOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleOverridesTable> {
  $$ScheduleOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get building => $composableBuilder(
    column: $table.building,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classroom => $composableBuilder(
    column: $table.classroom,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduleOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleOverridesTable> {
  $$ScheduleOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subjectKey => $composableBuilder(
    column: $table.subjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get building =>
      $composableBuilder(column: $table.building, builder: (column) => column);

  GeneratedColumn<String> get classroom =>
      $composableBuilder(column: $table.classroom, builder: (column) => column);
}

class $$ScheduleOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleOverridesTable,
          ScheduleOverride,
          $$ScheduleOverridesTableFilterComposer,
          $$ScheduleOverridesTableOrderingComposer,
          $$ScheduleOverridesTableAnnotationComposer,
          $$ScheduleOverridesTableCreateCompanionBuilder,
          $$ScheduleOverridesTableUpdateCompanionBuilder,
          (
            ScheduleOverride,
            BaseReferences<
              _$AppDatabase,
              $ScheduleOverridesTable,
              ScheduleOverride
            >,
          ),
          ScheduleOverride,
          PrefetchHooks Function()
        > {
  $$ScheduleOverridesTableTableManager(
    _$AppDatabase db,
    $ScheduleOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> subjectKey = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String?> building = const Value.absent(),
                Value<String?> classroom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleOverridesCompanion(
                subjectKey: subjectKey,
                day: day,
                building: building,
                classroom: classroom,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subjectKey,
                required String day,
                Value<String?> building = const Value.absent(),
                Value<String?> classroom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleOverridesCompanion.insert(
                subjectKey: subjectKey,
                day: day,
                building: building,
                classroom: classroom,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduleOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleOverridesTable,
      ScheduleOverride,
      $$ScheduleOverridesTableFilterComposer,
      $$ScheduleOverridesTableOrderingComposer,
      $$ScheduleOverridesTableAnnotationComposer,
      $$ScheduleOverridesTableCreateCompanionBuilder,
      $$ScheduleOverridesTableUpdateCompanionBuilder,
      (
        ScheduleOverride,
        BaseReferences<
          _$AppDatabase,
          $ScheduleOverridesTable,
          ScheduleOverride
        >,
      ),
      ScheduleOverride,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$GradeSnapshotsTableTableManager get gradeSnapshots =>
      $$GradeSnapshotsTableTableManager(_db, _db.gradeSnapshots);
  $$RemoteCacheEntriesTableTableManager get remoteCacheEntries =>
      $$RemoteCacheEntriesTableTableManager(_db, _db.remoteCacheEntries);
  $$AppFlagsTableTableManager get appFlags =>
      $$AppFlagsTableTableManager(_db, _db.appFlags);
  $$SubjectPreferencesTableTableManager get subjectPreferences =>
      $$SubjectPreferencesTableTableManager(_db, _db.subjectPreferences);
  $$ScheduleOverridesTableTableManager get scheduleOverrides =>
      $$ScheduleOverridesTableTableManager(_db, _db.scheduleOverrides);
}

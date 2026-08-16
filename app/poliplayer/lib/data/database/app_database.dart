import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_flags_table.dart';
import 'tables/grade_snapshots_table.dart';
import 'tables/remote_cache_table.dart';
import 'tables/schedule_overrides_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Tasks,
  GradeSnapshots,
  RemoteCacheEntries,
  AppFlags,
  SubjectPreferences,
  ScheduleOverrides,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(gradeSnapshots);
          if (from < 3) await m.createTable(remoteCacheEntries);
          if (from < 4) await m.createTable(appFlags);
          if (from < 5) {
            await m.createTable(subjectPreferences);
            await m.createTable(scheduleOverrides);
            await m.addColumn(tasks, tasks.type);
            await m.addColumn(tasks, tasks.iconKey);
            await m.addColumn(tasks, tasks.alarmEnabled);
            await m.addColumn(tasks, tasks.subject);
          }
        },
      );

  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  Future<int> deleteTask(int id) => (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Lee una respuesta cacheada del SAES. `null` si nunca se guardó.
  Future<({dynamic payload, DateTime fetchedAt})?> loadRemoteCache(String key) async {
    final row = await (select(remoteCacheEntries)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return (payload: jsonDecode(row.payloadJson), fetchedAt: row.fetchedAt);
  }

  Future<void> saveRemoteCache(String key, Object payload) async {
    await into(remoteCacheEntries).insertOnConflictUpdate(
      RemoteCacheEntriesCompanion.insert(
        cacheKey: key,
        payloadJson: jsonEncode(payload),
        fetchedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearRemoteCache() => delete(remoteCacheEntries).go();

  /// Borra sólo una entrada de caché — usado por `SchoolCycleLifecycleService`
  /// para limpiar `schedule`/`grades` al cerrar el ciclo sin tocar `kardex`
  /// (historial acumulado, no dato del ciclo actual).
  Future<void> clearRemoteCacheKey(String key) =>
      (delete(remoteCacheEntries)..where((t) => t.cacheKey.equals(key))).go();

  Future<String?> readFlag(String key) async {
    final row = await (select(appFlags)..where((t) => t.flagKey.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeFlag(String key, String value) async {
    await into(appFlags).insertOnConflictUpdate(
      AppFlagsCompanion.insert(flagKey: key, value: value),
    );
  }

  Future<Map<String, String>> loadGradeSnapshots() async {
    final rows = await select(gradeSnapshots).get();
    return {for (final row in rows) row.subjectKey: row.finalGrade};
  }

  Future<void> saveGradeSnapshots(Map<String, String> snapshots) async {
    await batch((b) {
      b.deleteAll(gradeSnapshots);
      b.insertAll(
        gradeSnapshots,
        snapshots.entries.map(
          (e) => GradeSnapshotsCompanion.insert(subjectKey: e.key, finalGrade: e.value),
        ),
      );
    });
  }

  Stream<List<SubjectPreference>> watchSubjectPreferences() =>
      select(subjectPreferences).watch();

  Future<void> setSubjectColor(String subjectKey, int? colorValue) async {
    await into(subjectPreferences).insertOnConflictUpdate(
      SubjectPreferencesCompanion.insert(
        subjectKey: subjectKey,
        colorValue: Value(colorValue),
      ),
    );
  }

  Stream<List<ScheduleOverride>> watchScheduleOverrides() => select(scheduleOverrides).watch();

  Future<void> setScheduleOverride({
    required String subjectKey,
    required String day,
    String? building,
    String? classroom,
  }) async {
    await into(scheduleOverrides).insertOnConflictUpdate(
      ScheduleOverridesCompanion.insert(
        subjectKey: subjectKey,
        day: day,
        building: Value(building),
        classroom: Value(classroom),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'polinexu.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

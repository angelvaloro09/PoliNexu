import 'dart:async';

import '../../domain/repositories/schedule_overrides_repository.dart';
import '../database/app_database.dart';

class ScheduleOverridesRepositoryImpl implements ScheduleOverridesRepository {
  final AppDatabase _db;

  ScheduleOverridesRepositoryImpl(this._db);

  @override
  Stream<ScheduleOverridesSnapshot> watchOverrides() {
    // Sin rxdart en el proyecto: combineLatest manual de las dos tablas
    // (colores por materia + overrides de sesión) en un solo snapshot.
    late StreamController<ScheduleOverridesSnapshot> controller;
    StreamSubscription? colorsSub;
    StreamSubscription? sessionsSub;
    Map<String, int> latestColors = const {};
    Map<(String, String), ({String? building, String? classroom})> latestSessions = const {};

    void emitSnapshot() {
      controller.add(ScheduleOverridesSnapshot(
        subjectColors: latestColors,
        sessionOverrides: latestSessions,
      ));
    }

    controller = StreamController<ScheduleOverridesSnapshot>.broadcast(
      onListen: () {
        colorsSub = _db.watchSubjectPreferences().listen((rows) {
          latestColors = {
            for (final row in rows)
              if (row.colorValue != null) row.subjectKey: row.colorValue!,
          };
          emitSnapshot();
        });
        sessionsSub = _db.watchScheduleOverrides().listen((rows) {
          latestSessions = {
            for (final row in rows)
              (row.subjectKey, row.day): (building: row.building, classroom: row.classroom),
          };
          emitSnapshot();
        });
      },
      onCancel: () {
        colorsSub?.cancel();
        sessionsSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> setSubjectColor(String subject, int? colorValue) =>
      _db.setSubjectColor(subject, colorValue);

  @override
  Future<void> setSessionOverride({
    required String subject,
    required String day,
    String? building,
    String? classroom,
  }) =>
      _db.setScheduleOverride(
        subjectKey: subject,
        day: day,
        building: building,
        classroom: classroom,
      );
}

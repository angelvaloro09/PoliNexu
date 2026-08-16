import '../../core/utils/school_cycle.dart';
import '../../domain/models/academic_calendar_event.dart';
import '../../domain/repositories/school_cycle_gate.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';

/// Ciclo de vida de Horario/Calificaciones: se limpian al terminar el periodo
/// escolar y se repueblan solos cuando concluye la cita de reinscripción del
/// alumno. Kárdex queda fuera a propósito — es el historial acumulado de
/// todos los semestres, no un dato "del ciclo actual".
///
/// El cierre lo dispara el calendario institucional (`applyClosingGate`,
/// desde `CalendarCubit`); la reapertura la dispara la cita personal del
/// alumno (`applyReopeningGate`, desde `ReinscriptionCubit`) — cada uno mira
/// sólo su propia fuente de datos, sin necesidad de una fecha "ancla"
/// intermedia: basta un flag `open`/`closed`.
///
/// Sólo toca `AppDatabase` (flag + caché) a propósito: `ScheduleRepositoryImpl`
/// y `GradesRepositoryImpl` ya consultan el flag en cada `getSchedule()`/
/// `getGrades()`, así que basta con que este servicio cambie el flag y borre
/// la caché para que el próximo `loadX()` de esos Cubits (natural o forzado
/// por pull-to-refresh) refleje el cierre/reapertura — no hace falta que este
/// servicio conozca los Cubits (`data/` no debe importar `presentation/`).
class SchoolCycleLifecycleService implements SchoolCycleGate {
  final AppDatabase _db;

  SchoolCycleLifecycleService(this._db);

  @override
  Future<void> applyClosingGate(List<AcademicCalendarEvent> events) async {
    final gate = await _db.readFlag(CycleFlags.gate);
    if (gate == 'closed') return;

    final today = DateTime.now();
    final ranges = schoolCycleRanges(events);
    if (ranges.isEmpty) return;

    // "hoy" ya pasó el fin de todos los ciclos conocidos (no está dentro de
    // ninguno) — se cierra la ventana.
    final stillActive = ranges.any((r) => !today.isBefore(r.$1) && !today.isAfter(r.$2));
    if (stillActive) return;

    final pastAnyEnd = ranges.any((r) => today.isAfter(r.$2));
    if (!pastAnyEnd) return;

    await _db.writeFlag(CycleFlags.gate, 'closed');
    await _db.clearRemoteCacheKey(RemoteCacheKeys.schedule);
    await _db.clearRemoteCacheKey(RemoteCacheKeys.grades);
  }

  @override
  Future<void> applyReopeningGate(DateTime? citaFin) async {
    if (citaFin == null) return;

    final gate = await _db.readFlag(CycleFlags.gate);
    if (gate != 'closed') return;
    if (DateTime.now().isBefore(citaFin)) return;

    await _db.writeFlag(CycleFlags.gate, 'open');
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/grade_entry.dart';
import '../../../domain/models/session_required_exception.dart';
import '../../../domain/repositories/grades_repository.dart';
import '../../../domain/repositories/notification_service.dart';
import 'grades_state.dart';

class GradesCubit extends Cubit<GradesState> {
  final GradesRepository _repository;
  final NotificationService _notificationService;

  GradesCubit(this._repository, this._notificationService) : super(const GradesInitial());

  Future<void> loadGrades({bool force = false}) async {
    // Cubit singleton compartido entre pantallas: sin esta guarda cada
    // reconstrucción de la pantalla repetiría el fetch. `force` lo usan
    // pull-to-refresh y "reintentar".
    if (!force && state is GradesLoaded) return;

    final cachedState = state;
    if (cachedState is! GradesLoaded) {
      final cached = await _repository.getCachedOnly();
      if (cached != null) {
        emit(GradesLoaded(cached.value, fetchedAt: cached.fetchedAt, fromCache: true));
      } else {
        emit(const GradesLoading());
      }
    }

    try {
      final data = await _repository.getGrades();

      // Sólo con datos frescos: comparar la caché contra sí misma no puede
      // producir una calificación "nueva", pero sí ruido si algo cambiara.
      if (!data.fromCache) {
        await _checkForNewGrades(data.value);
      }

      emit(GradesLoaded(
        data.value,
        fetchedAt: data.fetchedAt,
        fromCache: data.fromCache,
        sessionExpired: data.sessionExpired,
      ));
    } catch (e) {
      if (state is! GradesLoaded) {
        emit(GradesError(e.toString(), sessionRequired: e is SessionRequiredException));
      }
    }
  }

  /// Compara contra la última "foto" guardada localmente y notifica
  /// cualquier materia cuya calificación final apareció o cambió. No
  /// notifica nada la primera vez que se corre (no hay foto previa con la
  /// que comparar) para no generar avisos falsos de "nuevo" sobre notas
  /// que ya existían.
  Future<void> _checkForNewGrades(List<GradeEntry> entries) async {
    final cached = await _repository.loadCachedGrades();
    final isFirstRun = cached.isEmpty;
    final updated = <String, String>{};

    for (final entry in entries) {
      final key = '${entry.group}|${entry.subject}';
      updated[key] = entry.final_;

      if (!isFirstRun) {
        final previous = cached[key];
        if (previous != null && previous != entry.final_ && entry.final_ != '-') {
          await _notificationService.notifyNewGrade(subject: entry.subject, grade: entry.final_);
        }
      }
    }

    await _repository.saveCachedGrades(updated);
  }
}

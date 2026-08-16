import '../../domain/models/academic_calendar_event.dart';
import '../../domain/models/remote_data.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../database/app_database.dart';
import '../database/tables/remote_cache_table.dart';
import '../remote/backend_client.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final BackendClient _client;
  final AppDatabase _db;

  CalendarRepositoryImpl(this._client, this._db);

  @override
  Future<RemoteData<List<AcademicCalendarEvent>>> getAcademicCalendar() async {
    try {
      final dtos = await _client.getAcademicCalendar();
      await _db.saveRemoteCache(
        RemoteCacheKeys.academicCalendar,
        dtos.map((e) => e.toJson()).toList(),
      );
      return RemoteData.fresh(_toDomain(dtos));
    } on BackendException {
      final cached = await _db.loadRemoteCache(RemoteCacheKeys.academicCalendar);
      if (cached == null) rethrow;

      final dtos = (cached.payload as List)
          .map((e) => AcademicCalendarEventDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return RemoteData(
        value: _toDomain(dtos),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  List<AcademicCalendarEvent> _toDomain(List<AcademicCalendarEventDto> dtos) => dtos
      .map((e) => AcademicCalendarEvent(
            id: e.id,
            title: e.title,
            category: AcademicCalendarCategory.fromBackendValue(e.category),
            startDate: DateTime.parse(e.startDate),
            endDate: DateTime.parse(e.endDate),
          ))
      .toList();
}

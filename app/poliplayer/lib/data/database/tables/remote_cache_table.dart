import 'package:drift/drift.dart';

/// Última respuesta conocida de cada endpoint del SAES, en crudo (JSON).
///
/// Sirve para que la app abra con datos aunque la sesión esté muerta o no haya
/// red. Se guarda el JSON tal cual en vez de modelar tres esquemas: los datos
/// sólo se leen para pintarlos, nunca se consultan por campo.
///
/// Claves usadas: `schedule`, `grades`, `kardex` (ver `RemoteCacheKeys`).
class RemoteCacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

abstract final class RemoteCacheKeys {
  static const schedule = 'schedule';
  static const grades = 'grades';
  static const kardex = 'kardex';
}

import 'package:drift/drift.dart';

/// Ajustes y banderas locales de la app (clave → valor).
///
/// Va en Drift y no en `flutter_secure_storage` porque nada de esto es un
/// secreto: el almacén seguro se reserva para el token de sesión y el
/// `accountId`, que sí lo son.
class AppFlags extends Table {
  TextColumn get flagKey => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {flagKey};
}

abstract final class AppFlagKeys {
  /// El usuario ya vio el onboarding de bienvenida.
  static const onboardingSeen = 'onboarding_seen';
}

/// Preferencias locales no sensibles de la app.
///
/// Separado de `SessionStore` a propósito: aquello guarda credenciales de
/// sesión en el almacén seguro del sistema; esto son banderas de UI que viven
/// en la base local.
abstract class AppPreferences {
  /// `true` si el usuario ya completó (o saltó) el onboarding.
  Future<bool> hasSeenOnboarding();

  Future<void> markOnboardingSeen();
}

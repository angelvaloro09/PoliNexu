/// Almacenamiento persistente y seguro de la identidad de sesión.
///
/// Guarda dos cosas, ambas opacas (nunca credenciales — la boleta y la
/// contraseña viven cifradas en el backend, ver `backend/services/credentials_store.py`):
///
/// - `sessionToken`: la sesión SAES viva; permite reabrir la app sin login.
/// - `accountId`: la cuenta recordada; permite re-autenticar tecleando sólo
///   el CAPTCHA cuando el SAES mata la sesión del lado del servidor.
abstract class SessionStore {
  Future<String?> readSessionToken();
  Future<void> writeSessionToken(String token);
  Future<void> clearSessionToken();

  Future<String?> readAccountId();
  Future<void> writeAccountId(String accountId);

  /// Borra todo (cierre de sesión real).
  Future<void> clear();
}

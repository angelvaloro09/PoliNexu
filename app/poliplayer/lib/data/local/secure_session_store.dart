import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/session_store.dart';

/// [SessionStore] respaldado por `flutter_secure_storage` (Keystore en Android).
class SecureSessionStore implements SessionStore {
  static const _sessionTokenKey = 'saes_session_token';
  static const _accountIdKey = 'saes_account_id';

  final FlutterSecureStorage _storage;

  // Sin opciones a propósito: desde flutter_secure_storage 10 el constructor
  // por defecto de `AndroidOptions` ya cifra con AES-GCM y envoltura de clave
  // RSA en el Keystore, y `encryptedSharedPreferences` quedó deprecado.
  //
  // La versión está fijada en ^10.3.1 y **no** debe subirse a 11 sin más: esa
  // rama compila contra `compileSdk = 37`, que es un SDK preview y no viene
  // instalado con el toolchain estable (el build falla con
  // "Failed to install ... platforms;android-37.0").
  SecureSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readSessionToken() => _storage.read(key: _sessionTokenKey);

  @override
  Future<void> writeSessionToken(String token) =>
      _storage.write(key: _sessionTokenKey, value: token);

  @override
  Future<void> clearSessionToken() => _storage.delete(key: _sessionTokenKey);

  @override
  Future<String?> readAccountId() => _storage.read(key: _accountIdKey);

  @override
  Future<void> writeAccountId(String accountId) =>
      _storage.write(key: _accountIdKey, value: accountId);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _sessionTokenKey);
    await _storage.delete(key: _accountIdKey);
  }
}

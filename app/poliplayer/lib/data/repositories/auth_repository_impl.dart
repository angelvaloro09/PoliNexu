import 'dart:convert';
import 'dart:typed_data';
import '../../core/constants/saes_schools.dart';
import '../../domain/models/auth_login_result.dart';
import '../../domain/models/session_restore_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_store.dart';
import '../remote/backend_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BackendClient _client;
  final SessionStore _sessionStore;

  String? _sessionToken;
  String? _accountId;

  AuthRepositoryImpl(this._client, this._sessionStore);

  @override
  String? get currentSessionToken => _sessionToken;

  @override
  String? get currentAccountId => _accountId;

  @override
  Future<SessionRestoreResult> restoreSession() async {
    _accountId = await _sessionStore.readAccountId();
    final token = await _sessionStore.readSessionToken();

    if (token == null) {
      return _accountId == null
          ? SessionRestoreResult.loginRequired
          : SessionRestoreResult.reauthRequired;
    }

    final SessionStatusDto status;
    try {
      status = await _client.getAuthStatus(token);
    } on BackendException {
      // Backend o SAES inalcanzables: no se puede afirmar que la sesión murió.
      // Se conserva el token y la app arranca en modo caché.
      _sessionToken = token;
      return SessionRestoreResult.offline;
    }

    if (status.accountId != null) {
      _accountId = status.accountId;
      await _sessionStore.writeAccountId(status.accountId!);
    }

    if (status.valid && status.authenticated) {
      _sessionToken = token;
      return SessionRestoreResult.authenticated;
    }

    // El token guardado ya no sirve: fuera, para no reintentarlo en cada arranque.
    _sessionToken = null;
    await _sessionStore.clearSessionToken();
    return _accountId == null
        ? SessionRestoreResult.loginRequired
        : SessionRestoreResult.reauthRequired;
  }

  @override
  Future<Uint8List> requestCaptcha(IpnSchool school) async {
    final response = await _client.createSession(school.id);
    _sessionToken = response.sessionToken;
    return base64Decode(response.captchaBase64);
  }

  @override
  Future<Uint8List> requestReauthCaptcha() async {
    final accountId = _accountId ?? await _sessionStore.readAccountId();
    if (accountId == null) {
      throw BackendException('No hay una cuenta guardada. Inicia sesión de nuevo.');
    }
    _accountId = accountId;

    final response = await _client.createReauthSession(accountId);
    _sessionToken = response.sessionToken;
    return base64Decode(response.captchaBase64);
  }

  @override
  Future<Uint8List> reloadCaptcha() async {
    final token = _sessionToken;
    if (token == null) {
      throw BackendException('No hay una sesión activa. Selecciona una escuela primero.');
    }
    final response = await _client.reloadCaptcha(token);
    return base64Decode(response.captchaBase64);
  }

  @override
  Future<AuthLoginResult> login({
    required String boleta,
    required String password,
    required String captchaText,
  }) async {
    final token = _sessionToken;
    if (token == null) {
      return const AuthLoginResult(
        success: false,
        errorMessage: 'No hay una sesión activa. Selecciona una escuela primero.',
      );
    }

    final response = await _client.login(
      sessionToken: token,
      boleta: boleta,
      password: password,
      captchaText: captchaText,
    );

    if (response.success) {
      await _persistSession(token, response.accountId);
    }

    return AuthLoginResult(success: response.success, errorMessage: response.message);
  }

  @override
  Future<AuthLoginResult> reauth({required String captchaText}) async {
    final token = _sessionToken;
    final accountId = _accountId;
    if (token == null || accountId == null) {
      return const AuthLoginResult(
        success: false,
        errorMessage: 'No hay una sesión de re-login activa.',
      );
    }

    final response = await _client.reauth(
      sessionToken: token,
      accountId: accountId,
      captchaText: captchaText,
    );

    if (response.success) {
      await _persistSession(token, response.accountId ?? accountId);
    }

    return AuthLoginResult(success: response.success, errorMessage: response.message);
  }

  @override
  Future<bool> keepAlive() async {
    final token = _sessionToken;
    if (token == null) return false;

    try {
      final status = await _client.keepAlive(token);
      if (!status.valid || !status.authenticated) {
        _sessionToken = null;
        await _sessionStore.clearSessionToken();
        return false;
      }
      return true;
    } on BackendException {
      // Sin red no se puede concluir nada: se conserva la sesión.
      return true;
    }
  }

  @override
  Future<void> logout({bool forgetAccount = false}) async {
    final token = _sessionToken;
    if (token != null) {
      try {
        await _client.logout(
          sessionToken: token,
          accountId: forgetAccount ? _accountId : null,
        );
      } on BackendException {
        // Cerrar sesión local no puede fallar por culpa de la red.
      }
    }

    _sessionToken = null;
    if (forgetAccount) {
      _accountId = null;
      await _sessionStore.clear();
    } else {
      await _sessionStore.clearSessionToken();
    }
  }

  Future<void> _persistSession(String token, String? accountId) async {
    _sessionToken = token;
    await _sessionStore.writeSessionToken(token);
    if (accountId != null) {
      _accountId = accountId;
      await _sessionStore.writeAccountId(accountId);
    }
  }
}

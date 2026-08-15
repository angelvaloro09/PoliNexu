import 'dart:typed_data';
import '../../core/constants/saes_schools.dart';
import '../models/auth_login_result.dart';
import '../models/session_restore_result.dart';

abstract class AuthRepository {
  /// Token de la sesión SAES activa (`null` si no hay sesión iniciada).
  /// Lo usan otros repositorios (Horario, Calificaciones, ...) para llamar
  /// endpoints autenticados del backend.
  String? get currentSessionToken;

  /// Cuenta recordada (credenciales cifradas en el backend), si la hay.
  /// Es lo que permite re-autenticar tecleando sólo el CAPTCHA.
  String? get currentAccountId;

  /// Reanuda la sesión guardada al arrancar la app.
  Future<SessionRestoreResult> restoreSession();

  /// Inicia una sesión SAES para [school] y retorna la imagen del CAPTCHA.
  Future<Uint8List> requestCaptcha(IpnSchool school);

  /// Pide sesión + CAPTCHA para el re-login de la cuenta recordada (la escuela
  /// la resuelve el backend a partir del `accountId`).
  Future<Uint8List> requestReauthCaptcha();

  /// Recarga el CAPTCHA de la sesión activa (creada por [requestCaptcha]).
  Future<Uint8List> reloadCaptcha();

  Future<AuthLoginResult> login({
    required String boleta,
    required String password,
    required String captchaText,
  });

  /// Re-login con las credenciales guardadas en el backend.
  Future<AuthLoginResult> reauth({required String captchaText});

  /// Ping que resetea el sliding timeout de la sesión en el SAES.
  /// `false` si la sesión ya no sirve.
  Future<bool> keepAlive();

  /// Cierra la sesión. [forgetAccount] además borra las credenciales
  /// guardadas en el backend.
  Future<void> logout({bool forgetAccount = false});
}

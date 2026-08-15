import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/saes_schools.dart';
import '../../../domain/models/session_restore_result.dart';
import '../../../domain/repositories/app_preferences.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final AppPreferences _preferences;

  AuthCubit(this._authRepository, this._preferences) : super(AuthInitial());

  /// Reanuda la sesión guardada al arrancar la app. Decide entre entrar
  /// directo, pedir sólo el CAPTCHA, o mandar al login completo.
  Future<void> restoreSession() async {
    emit(AuthRestoring());

    // La bienvenida va antes que cualquier comprobación de sesión: en un
    // primer arranque no hay nada guardado que comprobar.
    if (!await _preferences.hasSeenOnboarding()) {
      emit(AuthOnboardingRequired());
      return;
    }

    final SessionRestoreResult result;
    try {
      result = await _authRepository.restoreSession();
    } catch (_) {
      emit(AuthLoginRequired());
      return;
    }

    switch (result) {
      case SessionRestoreResult.authenticated:
        emit(const AuthSessionRestored());
      case SessionRestoreResult.offline:
        emit(const AuthSessionRestored(offline: true));
      case SessionRestoreResult.reauthRequired:
        await startReauth();
      case SessionRestoreResult.loginRequired:
        emit(AuthLoginRequired());
    }
  }

  /// Marca el onboarding como visto. Quien lo llama vuelve a `/`, y el splash
  /// reanuda desde ahí el flujo normal de sesión.
  Future<void> markOnboardingSeen() => _preferences.markOnboardingSeen();

  /// Pide un CAPTCHA nuevo para re-loguear con las credenciales guardadas.
  Future<void> startReauth() async {
    emit(AuthReauthCaptchaLoading());
    try {
      final bytes = await _authRepository.requestReauthCaptcha();
      emit(AuthReauthCaptchaLoaded(bytes));
    } catch (e) {
      emit(AuthReauthFailure(e.toString(), null));
    }
  }

  /// Re-login: el backend pone boleta y contraseña, el usuario sólo el CAPTCHA.
  Future<void> reauth(String captchaText) async {
    final currentState = state;
    final captchaBytes = switch (currentState) {
      AuthReauthCaptchaLoaded(:final captchaBytes) => captchaBytes,
      AuthReauthFailure(:final captchaBytes) => captchaBytes,
      _ => null,
    };
    if (captchaBytes == null) return;

    emit(AuthReauthLoading(captchaBytes));

    try {
      final result = await _authRepository.reauth(captchaText: captchaText);
      if (result.success) {
        emit(const AuthSessionRestored());
        return;
      }
      // El CAPTCHA fallido queda quemado en el servidor: hay que pedir uno nuevo.
      emit(AuthReauthFailure(
        result.errorMessage ?? 'Error desconocido',
        await _tryReloadReauthCaptcha(),
      ));
    } catch (e) {
      emit(AuthReauthFailure(e.toString(), await _tryReloadReauthCaptcha()));
    }
  }

  /// Ping al volver a primer plano. Devuelve `false` si la sesión ya no sirve;
  /// en ese caso deja emitido el estado al que la UI debe navegar
  /// ([AuthReauthCaptchaLoading] o [AuthLoginRequired]).
  Future<bool> keepAliveOrReauth() async {
    if (await _authRepository.keepAlive()) return true;

    if (_authRepository.currentAccountId == null) {
      emit(AuthLoginRequired());
    } else {
      await startReauth();
    }
    return false;
  }

  /// Abandona el re-login y vuelve al login completo (p. ej. si el usuario
  /// quiere entrar con otra cuenta).
  Future<void> cancelReauth({bool forgetAccount = true}) async {
    await _authRepository.logout(forgetAccount: forgetAccount);
    emit(AuthInitial());
  }

  Future<void> logout() async {
    await _authRepository.logout(forgetAccount: true);
    emit(AuthInitial());
  }

  Future<Uint8List?> _tryReloadReauthCaptcha() async {
    try {
      return await _authRepository.requestReauthCaptcha();
    } catch (_) {
      return null;
    }
  }

  /// Selecciona una escuela, inicia sesión en el backend y descarga el CAPTCHA
  Future<void> fetchCaptchaForSchool(IpnSchool school) async {
    emit(AuthCaptchaLoading(school));
    try {
      final bytes = await _authRepository.requestCaptcha(school);
      emit(AuthCaptchaLoaded(school, bytes));
    } catch (e) {
      emit(AuthCaptchaError(e.toString()));
    }
  }

  /// Recarga solo la imagen del CAPTCHA manteniendo la sesión
  Future<void> reloadCaptcha() async {
    final school = _schoolFrom(state);
    if (school == null) return;

    emit(AuthCaptchaLoading(school));
    try {
      final bytes = await _authRepository.reloadCaptcha();
      emit(AuthCaptchaLoaded(school, bytes));
    } catch (e) {
      emit(AuthCaptchaError(e.toString()));
    }
  }

  /// Realiza la petición de inicio de sesión
  Future<void> login({
    required String boleta,
    required String password,
    required String captchaText,
  }) async {
    final currentState = state;
    if (currentState is! AuthCaptchaLoaded && currentState is! AuthLoginFailure) {
      return;
    }

    final school = currentState is AuthCaptchaLoaded
        ? currentState.selectedSchool
        : (currentState as AuthLoginFailure).selectedSchool;

    final captchaBytes = currentState is AuthCaptchaLoaded
        ? currentState.captchaBytes
        : (currentState as AuthLoginFailure).captchaBytes;

    emit(AuthLoginLoading(school, captchaBytes));

    final result = await _authRepository.login(
      boleta: boleta,
      password: password,
      captchaText: captchaText,
    );

    if (result.success) {
      emit(AuthLoginSuccess());
    } else {
      // Si falla, el CAPTCHA se invalida en el servidor. Lo recargamos automáticamente.
      try {
        final newBytes = await _authRepository.reloadCaptcha();
        emit(AuthLoginFailure(result.errorMessage ?? 'Error desconocido', school, newBytes));
      } catch (e) {
        emit(AuthLoginFailure(result.errorMessage ?? 'Error desconocido', school, captchaBytes));
      }
    }
  }

  IpnSchool? _schoolFrom(AuthState state) {
    if (state is AuthCaptchaLoaded) return state.selectedSchool;
    if (state is AuthLoginFailure) return state.selectedSchool;
    return null;
  }
}

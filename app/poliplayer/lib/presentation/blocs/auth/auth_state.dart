import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import '../../../core/constants/saes_schools.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

/// Arranque: comprobando contra el backend si la sesión guardada sigue viva.
class AuthRestoring extends AuthState {}

/// Primer arranque: hay que mostrar la bienvenida antes de pedir nada.
class AuthOnboardingRequired extends AuthState {}

/// Hay sesión utilizable; la app entra directo sin login.
/// [offline] = no se pudo contactar al backend, se entra con datos en caché.
class AuthSessionRestored extends AuthState {
  final bool offline;
  const AuthSessionRestored({this.offline = false});

  @override
  List<Object?> get props => [offline];
}

/// La sesión murió pero el backend tiene las credenciales cifradas:
/// sólo falta el CAPTCHA.
class AuthReauthCaptchaLoading extends AuthState {}

class AuthReauthCaptchaLoaded extends AuthState {
  final Uint8List captchaBytes;
  const AuthReauthCaptchaLoaded(this.captchaBytes);

  @override
  List<Object?> get props => [captchaBytes];
}

class AuthReauthLoading extends AuthState {
  final Uint8List captchaBytes;
  const AuthReauthLoading(this.captchaBytes);

  @override
  List<Object?> get props => [captchaBytes];
}

class AuthReauthFailure extends AuthState {
  final String error;

  /// `null` si tampoco se pudo recargar el CAPTCHA (error de red).
  final Uint8List? captchaBytes;

  const AuthReauthFailure(this.error, this.captchaBytes);

  @override
  List<Object?> get props => [error, captchaBytes];
}

/// No hay nada reutilizable: login completo.
class AuthLoginRequired extends AuthState {}

class AuthCaptchaLoading extends AuthState {
  final IpnSchool selectedSchool;
  const AuthCaptchaLoading(this.selectedSchool);

  @override
  List<Object?> get props => [selectedSchool];
}

class AuthCaptchaLoaded extends AuthState {
  final IpnSchool selectedSchool;
  final Uint8List captchaBytes;

  const AuthCaptchaLoaded(this.selectedSchool, this.captchaBytes);

  @override
  List<Object?> get props => [selectedSchool, captchaBytes];
}

class AuthCaptchaError extends AuthState {
  final String message;
  const AuthCaptchaError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthLoginLoading extends AuthState {
  final IpnSchool selectedSchool;
  final Uint8List captchaBytes;

  const AuthLoginLoading(this.selectedSchool, this.captchaBytes);

  @override
  List<Object?> get props => [selectedSchool, captchaBytes];
}

class AuthLoginSuccess extends AuthState {}

class AuthLoginFailure extends AuthState {
  final String error;
  final IpnSchool selectedSchool;
  final Uint8List captchaBytes;

  const AuthLoginFailure(this.error, this.selectedSchool, this.captchaBytes);

  @override
  List<Object?> get props => [error, selectedSchool, captchaBytes];
}

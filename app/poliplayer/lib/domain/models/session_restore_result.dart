/// Resultado de intentar reanudar la sesión al arrancar la app.
enum SessionRestoreResult {
  /// Hay sesión viva en el SAES: entrar directo.
  authenticated,

  /// La sesión murió pero el backend tiene las credenciales: basta el CAPTCHA.
  reauthRequired,

  /// No hay nada guardado (o ya no sirve): login completo.
  loginRequired,

  /// No se pudo contactar al backend. La sesión podría seguir viva; la app
  /// muestra lo que tenga en caché en vez de mandar al login.
  offline,
}

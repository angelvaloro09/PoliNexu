/// La sesión del SAES murió y no hay caché local con la que seguir
/// mostrando algo — a diferencia de [RemoteData.sessionExpired] (que se usa
/// cuando sí hay caché), este caso necesita que la UI pida login explícito.
///
/// Vive en `domain/` a propósito: los repositorios lo lanzan en vez de dejar
/// escapar `SessionExpiredException` de `data/remote/backend_client.dart`,
/// que las capas de presentación no deben importar.
class SessionRequiredException implements Exception {
  final String message;
  const SessionRequiredException(this.message);

  @override
  String toString() => message;
}

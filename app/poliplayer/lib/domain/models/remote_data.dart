/// Datos del SAES junto con su procedencia.
///
/// Los repositorios que hablan con el backend devuelven esto para que la UI
/// pueda distinguir "recién bajado" de "lo último que teníamos guardado" —
/// y para que los efectos secundarios (reprogramar alarmas, notificar
/// calificaciones nuevas) sólo corran con datos frescos.
class RemoteData<T> {
  final T value;

  /// Cuándo se bajó del SAES (no cuándo se leyó de la caché).
  final DateTime fetchedAt;

  /// `true` si viene de la caché local porque la red o la sesión fallaron.
  final bool fromCache;

  /// `true` si específicamente la sesión del SAES expiró (vs. cualquier otro
  /// fallo de red) — la UI usa esto para ofrecer re-login en vez de un
  /// "reintentar" genérico.
  final bool sessionExpired;

  const RemoteData({
    required this.value,
    required this.fetchedAt,
    required this.fromCache,
    this.sessionExpired = false,
  });

  RemoteData.fresh(this.value)
      : fetchedAt = DateTime.now(),
        fromCache = false,
        sessionExpired = false;
}

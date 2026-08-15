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

  const RemoteData({
    required this.value,
    required this.fetchedAt,
    required this.fromCache,
  });

  RemoteData.fresh(this.value)
      : fetchedAt = DateTime.now(),
        fromCache = false;
}

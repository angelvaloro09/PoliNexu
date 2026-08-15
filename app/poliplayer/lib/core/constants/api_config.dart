/// Configuración del backend FastAPI (`backend/`).
///
/// El cliente Flutter corre en un dispositivo Android físico
/// (`flutter run -d <device>`), por lo que `localhost` no sirve como base URL
/// — debe apuntar a la IP LAN de la PC donde corre `uvicorn` (con
/// `--host 0.0.0.0`). Configúrala en tiempo de build sin tocar código:
///
/// ```bash
/// flutter run -d <device> --dart-define=BACKEND_BASE_URL=http://192.168.1.50:8000
/// ```
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://192.168.1.100:8000',
  );
}

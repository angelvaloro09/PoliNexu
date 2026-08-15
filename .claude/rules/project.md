# PoliNexu — Reglas del Proyecto para Claude Code

## 1. Estructura de Archivos — CRÍTICO

- **Toda la GUI y lógica de interfaz de Flutter** vive **exclusivamente** en `app/poliplayer/lib/`.
  Nunca crees archivos de UI fuera de esa ruta.
- **El backend Python/FastAPI** vive en `backend/`. Nunca mezcles código Python con Flutter.
- **El plan activo** es `plans/plan_polinexu.md`. Márcalo con `[x]` cuando completes un ítem.
  **Nunca des una tarea por terminada sin actualizar ese archivo.**

## 2. Comandos de Build — NO ejecutar automáticamente

El usuario ejecuta él mismo los comandos de compilación, construcción y despliegue.
Sugiere el comando exacto pero **no lo ejecutes sin permiso explícito**.

```bash
# Flutter (desde app/poliplayer/)
flutter pub get
flutter run -d <device>
flutter analyze
dart run build_runner build --delete-conflicting-outputs

# Backend (desde backend/)
.\venv\Scripts\activate          # Windows
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

## 3. Gestión de Estado — BLoC/Cubit

- Usa **Cubit** para flujos simples, **BLoC** cuando haya múltiples eventos complejos.
- Los estados son clases que extienden una clase base sellada (o con `sealed`).
- **Cubits y BLoCs son puros**: no hacen HTTP ni I/O directamente. Delegan a Repositories.
- Estructura obligatoria por feature:
  ```
  presentation/blocs/<feature>/
    <feature>_cubit.dart
    <feature>_state.dart      ← sealed class / abstract class
  ```

## 4. Arquitectura en Capas — Flujo Unidireccional

```
presentation → domain → data
```

- `presentation/` importa de `domain/` y de sí misma. Nunca importa de `data/` directamente.
- `domain/` es puro Dart. No importa de `data/`, `presentation/`, ni paquetes externos de IO.
- `data/` implementa las interfaces definidas en `domain/repositories/`.
- `core/` (tema, constantes, extensiones) puede ser importado por cualquier capa.

## 5. SAES — Reglas Críticas

- **Nunca hardcodees URLs del SAES.** Toda URL/subdomain va en
  `lib/core/constants/saes_schools.dart` (enum `IpnSchool`).
- Antes de cualquier POST de login, SIEMPRE extrae `__VIEWSTATE`, `__VIEWSTATEGENERATOR`
  y `__EVENTVALIDATION` del HTML de la página de login. Sin ellos el POST falla.
- **Un redirect HTTP 302** en la respuesta del login = éxito.
  **Un HTTP 200** = el formulario se re-renderizó = credenciales o CAPTCHA incorrectos.
- El CAPTCHA y el login **deben compartir la misma sesión HTTP** (cookie `ASP.NET_SessionId`).
  Nunca recargues el CAPTCHA con una instancia de Dio/requests diferente.
- En **Flutter Web** (`kIsWeb == true`): no inicialices `CookieManager` — el navegador
  gestiona las cookies. Usa siempre el guard `if (!kIsWeb)` antes de añadir el interceptor.

## 6. Backend vs. Scraping Directo

La **arquitectura objetivo** delega todo el scraping al **backend FastAPI** en Python.
El `SaesClient` Dart actual es provisional. Antes de agregar parsers en Dart,
confirma si el usuario quiere migrar al backend o continuar con scraping directo.

## 7. Android — Build Config

- `minSdk` no debe bajar de **21**.
- `coreLibraryDesugaring` **siempre activo** con `desugar_jdk_libs >= 2.1.4`
  (requerido por `flutter_local_notifications`). Configura en `android/app/build.gradle.kts`:
  ```kotlin
  compileOptions { isCoreLibraryDesugaringEnabled = true }
  dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
  ```
- Nunca hardcodees `compileSdkVersion` — usa `flutter.compileSdkVersion`.

## 8. Convenciones de Código

### Dart/Flutter
- Sigue `flutter_lints`. Corre `flutter analyze` antes de considerar un cambio listo.
- Prefiere `final` y `const` siempre que sea posible.
- Documenta métodos y clases públicas con `///` (DartDoc).
- No uses `print()` — usa `debugPrint()`.
- Nombres de archivos: `snake_case.dart`. Clases: `PascalCase`. Variables: `camelCase`.

### Python/FastAPI
- Sigue PEP8. Líneas máx. 100 caracteres.
- Tipado explícito en todas las funciones públicas con `typing`.
- Todos los schemas de request/response son modelos **Pydantic v2** (`BaseModel`).
- Rutas organizadas por feature en `backend/routers/<feature>.py`.
- Nunca expongas credenciales en el código. Usa variables de entorno con `python-dotenv`.

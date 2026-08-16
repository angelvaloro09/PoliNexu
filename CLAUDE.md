# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**PoliNexu** is a personal Android app for IPN (Instituto Politécnico Nacional) students.
It combines three functional pillars:

1. **Schedule, task and activity manager** — visual calendar with priorities.
2. **SAES connector** — multi-school access to grades, class schedules, kardex,
   student data and GPA simulation. SAES is IPN's student portal (ASP.NET WebForms,
   no official API — everything is scraped).
3. **Notification and alarm system** — reminders for tasks and alarms for classes.

**Full plan with phase checklist:** `plans/plan_polinexu.md` (Spanish).
**Architecture decisions:** see "Architecture" section below and `.claude/rules/project.md`.

---

## Repo Layout

```
PoliNexu/
├── app/poliplayer/          ← Flutter app. ALL GUI/client code lives here.
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart         ← MaterialApp.router + theme + go_router
│   │   ├── core/            ← theme, constants, di/ (get_it)
│   │   ├── data/            ← remote/ (backend client), repositories/, database/ (Drift)
│   │   ├── domain/          ← repositories/ (interfaces), models/ (pure Dart, e.g. AuthLoginResult)
│   │   └── presentation/    ← router/ (go_router), blocs (Cubits), screens, widgets
│   ├── android/
│   │   └── app/
│   │       └── build.gradle.kts  ← see "Android Config" for required desugaring
│   └── pubspec.yaml
│
├── backend/                 ← Python/FastAPI SAES scraper server
│   ├── main.py               ← FastAPI app, CORS, /health, /schools
│   ├── core/                 ← config.py (pydantic-settings), schools.py (school catalog)
│   ├── services/              ← saes_scraper.py (BotDetect-aware), session_manager.py (in-memory + SQLite)
│   │   └── parsers/           ← horario_parser.py, grades_parser.py (HTML → dict)
│   ├── routers/auth.py       ← POST /auth/session, GET /auth/captcha, POST /auth/login, POST /auth/logout
│   ├── routers/saes.py       ← GET /saes/schedule, GET /saes/grades (requiere sesión autenticada)
│   ├── models/schemas.py     ← Pydantic v2 request/response schemas
│   ├── database/             ← SQLAlchemy engine + SaesSessionRecord model
│   ├── requirements.txt
│   └── venv/                 ← standard CPython (see "Backend Env Gotcha" below)
│
├── plans/
│   └── plan_polinexu.md    ← living implementation plan with phase checkboxes
│
├── .claude/
│   ├── rules/
│   │   └── project.md      ← project rules for Claude Code
│   └── skills/
│       ├── flutter/
│       │   ├── design_system.md     ← UI design guide (Gemini/Google style)
│       │   └── bloc_architecture.md ← BLoC/Cubit patterns, Drift, go_router
│       └── fastapi/
│           └── saes_backend.md      ← FastAPI + scraper patterns
│
└── CLAUDE.md               ← this file
```

---

## Commands

### Flutter app (`app/poliplayer/`)
Run all Flutter commands from `app/poliplayer/`.

```bash
flutter pub get                                             # install / sync deps
flutter run -d <device_id>                                  # run on device/emulator
flutter run -d V2247 --debug                                # run on Xiaomi V2247
flutter analyze                                             # static analysis
flutter test                                                # run tests
dart run build_runner build --delete-conflicting-outputs    # regen Drift code
```

### Backend (`backend/`)
```bash
cd backend
.\venv\Scripts\activate        # Windows
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

**Backend Env Gotcha:** the venv **must** be created from a standard CPython
(`py -3.x -m venv venv`), not a MSYS2/MinGW Python — a MinGW-built interpreter
reports platform tag `mingw_x86_64_msvcrt_gnu`, which never matches PyPI's
`win_amd64` wheels, forcing every C-extension dependency (`pydantic-core`,
`sqlalchemy`, `greenlet`) to compile from source, which then fails (MinGW/MSVC
linker mismatch). If `pip install` starts invoking `cargo`/`maturin`/`rustc`,
the venv's Python is wrong — recreate it with `py -3.14 -m venv venv` (check
`py -0` for available standard interpreters) and reinstall. Also keep
`pydantic`/`pydantic-core`/`fastapi`/`uvicorn`/`SQLAlchemy` versions current
enough to have prebuilt wheels for the venv's exact Python version — pin bumps
here are about wheel availability, not just features.

---

## Architecture

### Current State vs. Planned

The plan calls for **FastAPI backend** to own all SAES scraping, with the Flutter app
consuming it over REST. Both sides are now migrated and verified:
- Backend (`backend/`) implements this end-to-end against real SAES sites (login page
  fetch, CAPTCHA, POST login) — see `routers/auth.py`.
- Flutter (`app/poliplayer/lib/`) consumes it via `data/remote/backend_client.dart`
  (Dio wrapper) → `data/repositories/auth_repository_impl.dart` → `domain/repositories/auth_repository.dart`,
  wired with `get_it` in `core/di/injection.dart`. `AuthCubit` now only depends on
  `AuthRepository` — no `dio`/`html` imports, no direct I/O (satisfies the "pure Cubit" rule).

The old `lib/data/saes/saes_client.dart`/`saes_session.dart` (direct Dart→SAES scraping,
provisional since Phase 2) have been **deleted** — behavior parity with the backend was
confirmed extensively (login, Horario, Calificaciones, Kárdex all verified against real
data). Don't resurrect that direct-scraping pattern in new code; it also used the broken
static CAPTCHA URL described below.

**Running against the backend:** the app needs `BACKEND_BASE_URL` pointed at the
backend's LAN IP (`lib/core/constants/api_config.dart`, default is a placeholder):
```bash
flutter run -d <device> --dart-define=BACKEND_BASE_URL=http://<PC_LAN_IP>:8000
```

### SAES Scraping Details

SAES is classic ASP.NET WebForms. Key mechanics:

- **Login flow:**
  1. `GET` the login page → extract `__VIEWSTATE`, `__VIEWSTATEGENERATOR`, `__EVENTVALIDATION`.
  2. `GET` CAPTCHA image **with the same session** (same `ASP.NET_SessionId` cookie).
  3. `POST` form-encoded login data with those tokens + ASP.NET field names
     (`ctl00$leftColumn$LoginUser$...`).
  4. **HTTP 302** = login success. **HTTP 200** = form re-rendered = wrong credentials/CAPTCHA.

- **CAPTCHA is dynamic, not a static URL.** SAES uses the **BotDetect** ASP.NET
  component (`/BotDetectCaptcha.ashx?get=image&c=<id>&t=<token>`) — the `c`/`t` pair
  is generated fresh on every login-page load and embedded in
  `<img class="LBD_CaptchaImage" src="...">`. It must be parsed out of the HTML on
  every fetch (`backend/services/saes_scraper.py::extract_aspnet_tokens`); it cannot
  be derived from a fixed suffix. `IpnSchool.captchaUrl` in `saes_schools.dart`
  (`'$baseUrl/c_default_CaptchaImage.aspx'`) is a leftover stale/wrong constant from
  before the backend migration — confirmed broken against real SAES (404). It's unused
  now (nothing calls it) but hasn't been deleted from the enum; don't copy that pattern
  into new code.
  "Reloading" the CAPTCHA means re-fetching the whole login page (new tokens +
  new CAPTCHA `c`/`t`), not re-requesting the same image URL — the backend's
  `GET /auth/captcha` does this.

- **BotDetect requires its hidden fields in the login POST too.** Beyond the
  `c`/`t` pair in the image URL, the login form carries `LBD_VCID_<captchaId>`
  and `LBD_BackWorkaround_<captchaId>` hidden inputs (name varies per captcha
  instance — extract by `name` prefix `LBD_`, don't hardcode). Omitting these
  makes the server reject the CAPTCHA as wrong **even when the typed text is
  correct** — this was a real bug that made login always fail; fixed in
  `extract_aspnet_tokens`/`login` (`AspNetTokens.captcha_fields`).

- **Encoding: always decode via `saes_scraper.decode_html(response)`, never
  `response.text` directly.** SAES pages don't reliably declare `charset` in
  the `Content-Type` header, so `requests` falls back to ISO-8859-1 per RFC 2616
  even though the real content is UTF-8 — corrupts accented characters (á, é,
  í, ó, ú, ñ) silently. `decode_html()` forces `response.apparent_encoding`
  instead. This bit both login error messages and the Horario/Calificaciones
  parsers; apply it to any new authenticated-page fetch.

- **Authenticated page paths are shared across schools** (same DAE-IPN product
  per campus, only `base_url` differs) — collected in `backend/core/saes_pages.py`
  (`SCHEDULE_PATH`, `GRADES_PATH`, `KARDEX_PATH`), found by navigating the
  "Alumnos" menu of a real authenticated session. Verified against UPIICSA only
  so far — if a new school's parser comes back empty, check whether its path differs
  before assuming the parser itself is broken.

- **Not every SAES page is a clean GridView.** Horario/Calificaciones are
  ASP.NET GridViews with stable `id`s (`ctl00_mainCopy_GV_Horario`,
  `ctl00_mainCopy_GV_Calif`) — straightforward to parse by id. Kárdex instead
  renders as raw concatenated HTML tables (`<table class="bottomBorder">`, one
  per semester) inside a single `<span id="ctl00_mainCopy_Lbl_Kardex">`, no
  GridView ids at all — parse by structure/position, not by id, when you hit
  this pattern (`kardex_parser.py`).

- **Detecting an expired SAES session on an authenticated GET:** if the response
  HTML contains `CaptchaCodeTextBox`, the SAES silently redirected back to the
  login form instead of erroring — treat it as session-expired (destroy the
  session, return 401), don't let it parse into an empty/wrong result silently.
  See `routers/saes.py::_fetch_authenticated_page`.

- **Session lifetime: the auth cookies are session cookies, none of them persistent.**
  Measured on a real authenticated session (`scripts/probe_session.py`): login yields
  `ASP.NET_SessionId`, `AspxAutoDetectCookieSupport` and **`.ASPXFORMSAUTH`** (ASP.NET
  forms auth, non-`secure`, `path=/`). The login form has **no "Recordarme" checkbox**,
  so none of the three carries an `expires` — they are all session cookies that a
  browser drops on close (which is why the reference app needs a WebView with a
  persistent `CookieManager`). PoliNexu keeps them alive by persisting the whole
  cookiejar server-side in `saes_sessions`. Note the cookie set is *not* visible on the
  pre-login page — only `ASP.NET_SessionId` appears there, so don't conclude anything
  about auth from an unauthenticated fetch.
  Two independent server-side timeouts gate access (forms-auth ticket and Session
  state, both sliding), so keeping a session usable means *touching* it periodically
  (`backend/services/keepalive.py`, worker started from `main.py`'s `lifespan`, pings
  `KEEPALIVE_PATH` with `allow_redirects=False` — a 302 to `Default.aspx?ReturnUrl=`
  means the session is dead). An IIS app-pool recycle kills InProc Sessions regardless,
  which is what `/auth/reauth` exists for.

- **The CAPTCHA text cannot be obtained programmatically.** BotDetect keeps it in the
  server's ASP.NET Session keyed by `LBD_VCID_*`; the client only ever gets pixels.
  Probed every handler mode: `get=sound` → `400 Sound disabled` (audio CAPTCHA is off,
  so the usual ASR shortcut is unavailable), `get=p|script|validationScript` → 400.
  Also: **two `get=image` requests with the same `t` return different codes** — the
  image must be fetched exactly once per login-page load, so never retry/preload it or
  the code the user is typing gets invalidated.

- **Credentials are stored encrypted in the backend** (`saes_accounts`, Fernet via
  `backend/services/credentials_store.py`) so re-login only needs the CAPTCHA. The key
  lives in `credentials_key` in `backend/.env` — never commit it; if it's empty the
  "remember" feature degrades cleanly (login still works, `account_id` comes back
  `null`). Changing the key makes existing rows undecryptable: `/auth/reauth` deletes
  the account and returns 404 so the client falls back to full login.

- **Schema changes on the backend DB:** there is no Alembic. `main.py` runs
  `Base.metadata.create_all()` (new tables only) plus `database/db.py::ensure_schema()`,
  which `ALTER TABLE ... ADD COLUMN`s the entries listed in `_ADDED_COLUMNS`. Add new
  columns there too, or delete `polinexu_backend.db` in dev.

- **Datetimes are naive UTC everywhere in the backend** (`database/models.py::utcnow`).
  SQLite drops the offset, so an aware datetime written via `DateTime` comes back naive
  and comparing the two raises `TypeError`.

- **School catalog:** each IPN school has its own SAES subdomain. Flutter side:
  `lib/core/constants/saes_schools.dart` (`IpnSchool` enum). Backend side:
  `backend/core/schools.py` (`SCHOOLS` dict) — **kept in manual parity**, no
  single source of truth between Dart/Python; update both when adding a school.
  **Never hardcode SAES URLs** outside those two files.

### App Layer Structure

```
presentation → domain → data
```

- `core/` — theme (Material 3, Gemini style), constants, extensions. Importable by all layers.
- `data/` — `remote/` (`BackendClient`), `repositories/` (impls), `database/` (Drift/SQLite).
- `domain/` — pure Dart: entities, repository interfaces, use cases. No IO, no framework deps.
- `presentation/` — `blocs/` (Cubits), `screens/`, `widgets/`. Imports only `domain/`.

### State Management

- **BLoC/Cubit** via `flutter_bloc`. All business logic in Cubits, never in widgets.
- DI via `get_it` (`lib/core/di/injection.dart`, `configureDependencies()` called once
  in `main.dart`). Repositories are lazy singletons; Cubits are factories (new instance
  per `BlocProvider`). Follow this pattern for new features instead of manual wiring.

### Local Persistence

- **Drift** (SQLite) for tasks, calendar, and offline cache. Implemented:
  `lib/data/database/tables/tasks_table.dart` + `app_database.dart` (`AppDatabase`,
  native SQLite via `path_provider` for the file path — see `_openConnection()`).
- After schema changes run: `dart run build_runner build --delete-conflicting-outputs`
  (regenerates `app_database.g.dart`).
- `TaskRepository.watchTasks()` returns a reactive `Stream` (Drift's `.watch()`), not a
  one-shot fetch — `TasksCubit` subscribes to it directly in its constructor instead of
  exposing a `loadX()` method like the HTTP-backed cubits. Follow this pattern for other
  Drift-backed features; it means the UI updates automatically on any local DB write,
  no manual refresh needed.
- **`flutter test` cannot open a real (or even in-memory) `NativeDatabase`** — there's no
  native `sqlite3` binding available in that host environment, and trying to hangs the
  test process indefinitely instead of failing fast. Don't attempt
  `NativeDatabase.memory()` in widget tests; override `TaskRepository` with a fake
  in-memory implementation instead (same pattern as `_FakeAuthRepository` in
  `test/widget_test.dart`) so Drift is never touched during tests.
- **If a hung `flutter test` gets killed, check for orphaned `flutter_tester.exe` /
  `dart.exe` processes before rerunning** — a leftover process can hold
  `build\native_assets\windows\sqlite3.dll` locked, making the next `flutter test`
  fail immediately with a file-delete permission error that has nothing to do with
  your code. `Get-CimInstance Win32_Process` (filter by PID) to confirm they're
  test-related before killing.

### Session Persistence (client side)

- `SessionStore` (`domain/repositories/session_store.dart`) + `SecureSessionStore`
  (`data/local/secure_session_store.dart`, `flutter_secure_storage` with
  `encryptedSharedPreferences: true`) persist **only** two opaque values: the SAES
  `sessionToken` and the `accountId`. Credentials never leave the backend.
- App startup goes through `/` (`SplashScreen`) → `AuthCubit.restoreSession()` →
  `GET /auth/status`, which routes to `/home`, `/reauth` (CAPTCHA-only re-login) or
  `/login`. `MainShell` pings `/auth/keepalive` on `AppLifecycleState.resumed`.
- `BackendClient` maps HTTP 401 to `SessionExpiredException` (a `BackendException`
  subclass) so the UI can tell "session died" from "network broke".
- **Offline cache:** `RemoteCacheEntries` (Drift, key → raw JSON + `fetchedAt`) holds the
  last `schedule`/`grades`/`kardex` response. The three repositories return
  `RemoteData<T>` (`value`, `fetchedAt`, `fromCache`) and fall back to cache on any
  `BackendException`, rethrowing only when there is no cache. Side effects
  (`scheduleClassAlarms`, new-grade notifications) run **only** when `fromCache` is
  false — cached data would re-fire the same batch on every launch.
- Tests must fake `SessionStore` *and* the three SAES repositories: they now touch Drift
  for the cache, and a real `NativeDatabase` hangs `flutter test` (see the Drift note
  above).

### Navigation

- **`go_router`** is wired: `lib/presentation/router/app_router.dart` exposes
  `buildAppRouter()` (factory — use this in tests, each test needs its own instance,
  never reuse the app singleton across `pumpWidget` calls) and `appRouter` (the
  singleton the real app uses, `= buildAppRouter()`).
- Routes: `/login` and `/kardex` (top-level, no shell/bottom-nav — `/kardex` is pushed via
  `context.push()` from Grades' AppBar, not a tab) and a `ShellRoute` wrapping `/home`,
  `/schedule`, `/grades`, `/tasks` behind `MainShell` (`presentation/widgets/main_shell.dart`,
  Material 3 `NavigationBar`). `PoliNexuApp` takes an optional `router` param for testability.
- `/tasks` itself has two sub-views behind an internal `TabBar` (Lista/Calendario) —
  don't add a new bottom-nav destination for something that's really a facet of an
  existing tab; a `TabBar` inside the screen is the right tool once you're at 4/5 nav items.
- Successful login (`AuthLoginSuccess`) navigates to `/home` via `context.go()` in
  `login_screen.dart`'s `BlocConsumer` listener.

### Notifications/Alarms

Implemented via `NotificationService` (`domain/repositories/notification_service.dart` +
`data/services/notification_service_impl.dart`), backed by `flutter_local_notifications`
only — **no `android_alarm_manager_plus`** (removed from `pubspec.yaml`; it was in the
original plan but required a background-isolate callback with manually-persisted metadata
just to reproduce what `zonedSchedule(matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime)`
already does natively for weekly recurrence — decided against it in conversation).

- **All notification title/body text is plain text, no emojis** — explicit user
  requirement. The visual signal is the notification icon (`@mipmap/ic_launcher` for
  every channel), not an emoji character in the copy. Keep this when adding new
  notification types.
- **flutter_local_notifications 22.x uses all-named parameters** (`initialize(settings: ...)`,
  `zonedSchedule(id: ..., scheduledDate: ..., notificationDetails: ..., ...)`,
  `cancel(id: ...)`, `show(id: ..., notificationDetails: ..., ...)`) — this is a real API
  surface change from older versions/tutorials that use positional args; check the
  installed package source (`flutter_local_notifications_plugin.dart` in pub cache) before
  assuming a signature, don't trust memory/older examples here.
- **`flutter_timezone`'s `getLocalTimezone()` returns a `TimezoneInfo` object**, not a
  `String` — use `.identifier`. `tz.setLocalLocation()` must be called (with
  `timezone`'s `tzdata.initializeTimeZones()` run first) before any `zonedSchedule` call,
  or scheduling silently uses UTC instead of the device's real timezone.
- **Notification ID ranges** (single flat namespace across all notification types, so
  they can't collide): task reminders `1000 + task.id`, class alarms `2000..2999`
  (reassigned sequentially every time `scheduleClassAlarms` reprograms the full batch —
  cancels `2000..2999` first, so stale alarms from a shrunk schedule don't linger), grade
  notifications `3000 + subject.hashCode.abs() % 1000`.
- **Task reminders**: scheduled/cancelled by `TasksCubit` (not `TaskRepository` — keeps
  persistence and side effects separate) on every add/update/toggle/delete, always via
  `NotificationService.scheduleTaskReminder()` which internally cancels-then-maybe-reschedules
  (handles the "task got marked completed" case by simply not rescheduling). Fires at
  9:00 a.m. on the due date; does nothing if the task has no due date, is completed, or
  the date already passed.
- **Class alarms**: scheduled/cancelled by `ScheduleCubit.loadSchedule()` — every
  successful fetch replaces the whole batch (cancel all `2000..2999`, then reschedule from
  the fresh `ScheduleEntry` list). Fires `_classAlarmLeadMinutes` (10) before each class
  session's start time, recurring weekly.
- **New-grade detection**: `GradesCubit.loadGrades()` compares each fetch against a
  cached snapshot (`GradeSnapshots` Drift table, via `GradesRepository.loadCachedGrades()`/
  `saveCachedGrades()`) keyed by `group|subject`. Only notifies when a subject's `final`
  grade changed to something other than `-`, and **never on the very first run** (empty
  cache) — otherwise every already-graded subject would trigger a false "new grade" the
  first time a fresh install fetches Calificaciones.
- **Android manifest**: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`,
  `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK` permissions added in
  `android/app/src/main/AndroidManifest.xml`. Runtime permission requests
  (`requestNotificationsPermission()`, `requestExactAlarmsPermission()`) happen once in
  `main.dart` after `NotificationService.initialize()`.
- **Tests**: never let a real `NotificationService` touch the platform channel in
  `flutter test` — override with a fake (see `_FakeNotificationService` in
  `test/widget_test.dart`), same reasoning as the fake `AuthRepository`/`TaskRepository`.

---

## Android Config

**Required in `android/app/build.gradle.kts`** (already applied):

```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true   // required by flutter_local_notifications
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

Do not touch `compileSdkVersion` or `ndkVersion` — use `flutter.compileSdkVersion`.

**Required in `android/app/src/main/AndroidManifest.xml`** (already applied, for
notifications/alarms — Phase 5):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

---

## Design System — Gemini / Material You

PoliNexu's visual language is **inspired by Google's modern Android apps**,
specifically the **Gemini app for Android** and Material You principles.

### Core Principles

- **Soft surfaces:** elements are differentiated by subtle surface color shifts, not hard shadows.
- **Generous roundness:** 24–32dp border radius on all interactive controls (`FilledButton`, inputs, cards).
- **Breathing space:** generous padding inside fields and buttons. No stacked elements without whitespace.
- **Clean typography:** `Plus Jakarta Sans` via `google_fonts` — closest OFL-licensed
  alternative to Google Sans/Product Sans. Real Google Sans is proprietary and not on
  Google Fonts; don't try to source/bundle it unless the user supplies files they
  legitimately obtained themselves (e.g. extracted from their own device) — that would
  go in as local `pubspec.yaml` fonts, not via `google_fonts`.
  Weights: 400 body, 500 actions/labels, 600 headings.
- **Material Symbols icons:** use `Symbols.xxx_rounded` from the `material_symbols_icons`
  package, **not** `Icons.xxx_outlined` (classic Material Icons font) — confirmed against
  real Gemini/NotebookLM screenshots that Google's current apps use Material Symbols
  Rounded (thinner stroke, rounded terminals), not the classic Material Icons outlined
  glyphs Flutter ships by default. Icons default to unfilled (`fill: 0`); for an
  active/selected state, reuse the **same** glyph with `fill: 1` instead of swapping to
  a different pictogram (see `NavigationDestination` in `main_shell.dart`).
- **Flat depth:** `elevation: 0` on cards and AppBar. Hierarchy via surface color, not shadows.
  `scrolledUnderElevation: 0` — no line on scroll.

### Design Tokens

- **Spacing:** `lib/core/theme/app_spacing.dart` — `AppSpacing.{xs,sm,md,lg,xl,xxl}`
  (8dp grid: 4/8/16/24/32/48). Use these instead of loose `SizedBox`/`EdgeInsets` values.
- **Radius:** `lib/core/theme/app_radius.dart` — `AppRadius.{sm 8, md 16, lg 24, xl 28, pill}`
  plus `AppIconSize.{sm 18, md 24, lg 48}`. There used to be five untokenized radii scattered
  across theme and screens; don't reintroduce loose numbers.
- **Motion:** `lib/core/theme/app_motion.dart` — `AppMotion.{fast, normal, slow, intro}` and the
  M3 emphasized curves. Material 3 uses asymmetric (fast-in, slow-out) curves, not `easeInOut`;
  every transition in the app comes from here.
- **Typography:** `lib/core/theme/app_text_styles.dart` — `TextTheme` extension
  (`textTheme.heroTitle`, `.sectionTitle`, `.cardTitle`, `.actionLabel`, `.body`,
  `.bodySecondary`, `.meta`) applies the weight scale below without repeating
  `.copyWith(fontWeight: ...)` in every screen.
- **Component themes:** `AppTheme` also defines `filledButtonTheme` (primary CTA,
  32dp radius), `outlinedButtonTheme` (secondary, 24dp), `chipTheme`,
  `navigationBarTheme` (for the Phase D shell), and explicit disabled/error states
  on buttons and `inputDecorationTheme` — don't override these inline in new screens,
  extend the theme instead.

### Color Tokens (never hardcode hex in widgets — use ColorScheme)

| Mode | `surface` | `surfaceContainerHighest` | primary seed |
|---|---|---|---|
| Light | `#F8F9FA` | `#E8EAED` | `#1E63D1` |
| Dark | `#131314` | `#282A2C` | `#A8C7FA` |

### Primary Button Pattern (CTA)
```dart
FilledButton(
  style: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
  ),
)
```

### Input Field Pattern
```dart
InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide.none,
  ),
  filled: true,
  fillColor: colorScheme.surfaceContainerHighest,
  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
)
```

### Shared UI Widgets (`lib/presentation/widgets/`)

Reach for these before writing a one-off:

| Widget | Replaces |
|---|---|
| `StatusView` / `InlineStatus` | error + empty states (there is no `ErrorView` anymore) |
| `SectionHeader` | "title + optional action" row |
| `AppCard` | `Card` + `Padding`, with optional accent bar and `emphasized` surface |
| `AppListRow` | raw `ListTile` (whose fixed 16dp padding fights the 24dp card radius) |
| `SkeletonBox` / `SkeletonList` | inline `CircularProgressIndicator` in lists |
| `AppSnack` | hand-built `SnackBar`s; includes `AppSnack.undo` |
| `PriorityFlag` / `priorityColor` | per-screen copies of the task priority colors |
| `NexusMark` / `NexusHero` / `NexusWordmark` | the brand; geometry lives in `NexusGeometry` |

### Brand & App Icon

- The mark is one geometry (`NexusGeometry` in `nexus_mark.dart`) rendered two ways:
  `NexusMark` (static) and `NexusHero` (animated pulses + breathing nodes). The brand
  gradient is `AppTheme.brandGradient(brightness)` — **two tones of the same blue**, not
  `colorScheme.tertiary`, which for this seed is teal and pulls the identity off-brand.
- `tool/render_icon.py` (Pillow) redraws that same geometry to `assets/branding/*.png`,
  which feed `flutter_launcher_icons` and `flutter_native_splash` (both configured in
  `pubspec.yaml`). **The geometry is duplicated in Dart and Python on purpose** — a
  `CustomPainter` can't be reused from a build script — so change both together, then:
  ```bash
  python tool/render_icon.py
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```
- A vertex-up triangle centered on its centroid reads as sitting too high; both renderers
  shift it down by a quarter radius to center the box it actually occupies.

### Fonts & Localization

- Plus Jakarta Sans is **bundled** in `assets/fonts` and declared in `pubspec.yaml`
  (`fontFamily: 'PlusJakartaSans'`). `google_fonts` was removed: it fetched the font over
  the network at runtime, so a first launch offline silently fell back to Roboto.
- `app.dart` sets `localizationsDelegates` + `supportedLocales: es_MX`. Without them
  `showDatePicker` and the `TableCalendar` chrome render in English.

### First-Run Flow

`/` (`SplashScreen`) → `AuthCubit.restoreSession()` decides: onboarding not seen →
`/onboarding`; else session state → `/home`, `/reauth` or `/login`. The onboarding flag is
an `AppFlags` row in Drift via `AppPreferences` (not secure storage — it isn't a secret).
The splash holds for `AppMotion.intro` before navigating so the mark doesn't flash.

**Full design guide:** `.claude/skills/flutter/design_system.md`

---

## Key Files

| File | Purpose |
|---|---|
| `plans/plan_polinexu.md` | Living plan — update checkboxes when completing items |
| `lib/core/theme/app_theme.dart` | Material 3 theme (light + dark, Gemini style, Plus Jakarta Sans) |
| `lib/core/constants/saes_schools.dart` | `IpnSchool` enum — all SAES URLs live here |
| `lib/data/remote/backend_client.dart` | Dio client for the FastAPI backend |
| `lib/data/repositories/auth_repository_impl.dart` | `AuthRepository` impl, holds session token |
| `lib/domain/repositories/auth_repository.dart` | Auth repository interface (pure Dart) |
| `lib/core/di/injection.dart` | `get_it` DI setup |
| `lib/core/constants/api_config.dart` | Backend base URL (`--dart-define=BACKEND_BASE_URL`) |
| `lib/presentation/blocs/auth/auth_cubit.dart` | Login + CAPTCHA state machine (pure, delegates to repo) |
| `lib/presentation/screens/login/login_screen.dart` | Login UI (Gemini-style, `NexusHero`, animated states) |
| `lib/presentation/widgets/nexus_mark.dart` | Brand geometry (`NexusGeometry`) + static mark |
| `lib/presentation/widgets/nexus_hero.dart` | Animated brand (pulses + breathing nodes) |
| `tool/render_icon.py` | Redraws the mark to PNG for launcher icon + native splash |
| `lib/presentation/screens/onboarding/` | First-run welcome (3 pages, `CustomPainter` art) |
| `lib/presentation/widgets/captcha_widget.dart` | CAPTCHA image widget with reload, `AnimatedSwitcher` states |
| `lib/core/theme/app_spacing.dart` | 8dp spacing grid constants |
| `lib/core/theme/app_radius.dart` | Corner-radius + icon-size scale |
| `lib/core/theme/app_motion.dart` | Durations + M3 emphasized curves |
| `lib/core/theme/app_text_styles.dart` | `TextTheme` extension applying the type-weight scale |
| `lib/presentation/router/app_router.dart` | `go_router` config — `buildAppRouter()` factory + `appRouter` singleton |
| `lib/presentation/widgets/main_shell.dart` | Bottom `NavigationBar` shell for `/home`, `/schedule`, `/grades`, `/tasks` |
| `lib/presentation/screens/schedule/schedule_screen.dart` | Horario screen — Semana (day-chip selector) / Calendario toggle, subject color+room override editing |
| `lib/presentation/screens/schedule/schedule_calendar_view.dart` | Calendario view — unifies Horario (recurring by weekday) + task due dates + IPN calendar |
| `lib/presentation/screens/schedule/schedule_override_sheet.dart` | Bottom sheet: per-subject color + per-(subject,day) building/classroom override |
| `lib/domain/repositories/schedule_overrides_repository.dart` + impl | Local-only (Drift) subject color/room overrides, no backend |
| `lib/presentation/screens/grades/grades_screen.dart` | Real Calificaciones screen (parciales + final per subject) — GPA simulator removed |
| `lib/presentation/screens/kardex/kardex_screen.dart` | Kárdex screen (career/plan/average + semesters) — pushed from Grades' AppBar, not a bottom-nav tab |
| `lib/presentation/widgets/status_view.dart` | Shared error/empty states (`StatusView`, `InlineStatus`) |
| `lib/presentation/screens/tasks/tasks_screen.dart` | Tasks screen — list only (calendar moved to Horario) |
| `lib/presentation/screens/tasks/task_form_sheet.dart` | Add/edit task bottom sheet — type (tarea/examen/evento), icon picker, subject autocomplete, alarm toggle |
| `lib/core/constants/task_icons.dart` | Curated icon set (key → `Symbols.*`) tasks/events can choose from |
| `lib/data/database/app_database.dart` | Drift `AppDatabase` (native SQLite) |
| `lib/presentation/blocs/tasks/tasks_cubit.dart` | Stream-driven Cubit (subscribes to `watchTasks()`, no `loadX()`) |
| `lib/presentation/screens/home/home_screen.dart` | Home dashboard — today's classes + pending tasks |
| `lib/core/utils/weekday.dart` | `spanishWeekdayLabel()` / `weekdayFromSpanishLabel()` — shared between Home, Calendar tab, and class alarms |
| `lib/domain/repositories/notification_service.dart` | Notification/alarm interface (task reminders, class alarms, grade alerts) |
| `lib/data/services/notification_service_impl.dart` | `flutter_local_notifications`-backed implementation — see "Notifications/Alarms" gotchas above |
| `android/app/build.gradle.kts` | Android build config (desugaring already enabled) |
| `backend/main.py` | FastAPI entrypoint, CORS, `/health`, `/schools` |
| `backend/services/saes_scraper.py` | SAES scraping logic (BotDetect CAPTCHA-aware, `decode_html()` encoding fix) |
| `backend/services/session_manager.py` | In-memory + SQLite-persisted SAES session pool |
| `backend/services/parsers/horario_parser.py` | Parses the Horario GridView into schedule entries |
| `backend/services/parsers/grades_parser.py` | Parses the Calificaciones GridView into grade entries |
| `backend/services/parsers/kardex_parser.py` | Parses the Kárdex raw HTML tables (no GridView ids) into semesters |
| `backend/routers/auth.py` | `/auth/session`, `/auth/captcha`, `/auth/login`, `/auth/reauth[/session]`, `/auth/status`, `/auth/keepalive`, `/auth/logout` |
| `backend/services/keepalive.py` | Worker que mantiene viva la Session del SAES (`lifespan` en `main.py`) |
| `backend/services/credentials_store.py` | Credenciales SAES cifradas con Fernet (`credentials_key` en `.env`) |
| `backend/scripts/probe_session.py` | Sonda manual: mide el timeout real del SAES y calibra `KEEPALIVE_PATH` |
| `lib/data/local/secure_session_store.dart` | `SessionStore` sobre `flutter_secure_storage` (token + accountId) |
| `lib/presentation/screens/splash/splash_screen.dart` | Arranque: reanuda sesión y enruta a `/home`, `/reauth` o `/login` |
| `lib/presentation/screens/login/reauth_screen.dart` | Re-login sólo-CAPTCHA con credenciales guardadas |
| `lib/data/database/tables/remote_cache_table.dart` | Caché offline de Horario/Calificaciones/Kárdex (JSON crudo) |
| `backend/routers/saes.py` | `/saes/schedule`, `/saes/grades`, `/saes/kardex` (authenticated) |
| `backend/core/schools.py` | School catalog (Python mirror of `saes_schools.dart`) |
| `backend/core/saes_pages.py` | Relative paths of authenticated SAES pages (shared across schools) |
| `backend/requirements.txt` | FastAPI backend dependencies |

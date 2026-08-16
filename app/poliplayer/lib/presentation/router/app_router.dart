import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../screens/academic_status/academic_status_screen.dart';
import '../screens/grades/grades_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/kardex/kardex_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/reauth_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../widgets/main_shell.dart';

/// Orden de las tabs del shell (mismo orden que `_destinations` en
/// `main_shell.dart`) — determina la dirección del slide entre tabs.
const _tabOrder = ['/home', '/schedule', '/grades', '/tasks', '/profile'];

int _tabIndexForPath(String path) {
  final index = _tabOrder.indexWhere((p) => path.startsWith(p));
  return index == -1 ? 0 : index;
}

// Última tab activa, para poder calcular la dirección del slide en la
// siguiente navegación — go_router no expone la ruta "de origen" en
// `pageBuilder`, así que se rastrea aquí. Se actualiza como efecto lateral
// de construir la página, no es elegante pero es el gancho disponible sin
// añadir un ChangeNotifier/state adicional sólo para esto.
int _lastTabIndex = 0;

/// Transición *fade through* (Material 3) para cambios entre pestañas: la
/// saliente se desvanece, la entrante aparece con una escala mínima, más un
/// slide horizontal sutil cuya dirección sigue el orden de las tabs
/// (Inicio→Perfil = derecha a izquierda) — refuerza el sentido de
/// "izquierda/derecha" del bottom nav sin abandonar el fade/scale ya pulido.
CustomTransitionPage<void> _fadeThroughPage(LocalKey key, Widget child, String path) {
  final newIndex = _tabIndexForPath(path);
  final direction = (newIndex - _lastTabIndex).sign;
  _lastTabIndex = newIndex;

  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.05 * direction, 0),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Para rutas que "profundizan" desde el shell (Kárdex/Estado General, ambas
/// alcanzables desde Notas/Perfil): slide-up sutil + fade, más lento que el
/// cambio de tab, para que se sienta como abrir un detalle y no como un
/// cambio de pestaña hermana.
CustomTransitionPage<void> _deepPushPage(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Para rutas que ya traen su propio `Hero('nexus-mark')` desde Splash
/// (Onboarding/Login/Reauth): sólo fade, sin slide ni scale — cualquier
/// transición de página adicional compite visualmente con el vuelo del Hero,
/// que es la señal de movimiento que debe dominar en esa navegación.
CustomTransitionPage<void> _heroSafePage(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppMotion.emphasized),
        child: child,
      );
    },
  );
}

/// Construye una instancia nueva del router. Úsalo en tests (cada test debe
/// tener su propio `GoRouter` — reutilizar uno entre distintos `pumpWidget`
/// deja referencias a elementos ya desmontados). En la app usa [appRouter].
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Arranque: decide entre onboarding, entrar directo, re-login
      // sólo-CAPTCHA o login completo según el estado guardado.
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _heroSafePage(state.pageKey, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _heroSafePage(state.pageKey, const LoginScreen()),
      ),
      GoRoute(
        path: '/reauth',
        pageBuilder: (context, state) => _heroSafePage(state.pageKey, const ReauthScreen()),
      ),
      GoRoute(
        path: '/kardex',
        pageBuilder: (context, state) => _deepPushPage(state.pageKey, const KardexScreen()),
      ),
      GoRoute(
        path: '/academic-status',
        pageBuilder: (context, state) =>
            _deepPushPage(state.pageKey, const AcademicStatusScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const HomeScreen(), state.uri.path),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const ScheduleScreen(), state.uri.path),
          ),
          GoRoute(
            path: '/grades',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const GradesScreen(), state.uri.path),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const TasksScreen(), state.uri.path),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const ProfileScreen(), state.uri.path),
          ),
        ],
      ),
    ],
  );
}

final appRouter = buildAppRouter();

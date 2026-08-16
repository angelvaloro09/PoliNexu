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
import '../screens/schedule/schedule_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../widgets/main_shell.dart';

/// Transición *fade through* (Material 3) para cambios entre pestañas: la
/// saliente se desvanece, la entrante aparece con una escala mínima. Sin
/// desplazamiento lateral, porque entre pestañas hermanas no hay jerarquía.
///
/// Va como `pageBuilder` de cada ruta y no como un `AnimatedSwitcher` alrededor
/// del `child` del shell: envolverlo mantiene vivo el hijo saliente mientras
/// go_router reutiliza su `GlobalKey`, lo que revienta con "Duplicate
/// GlobalKey detected in widget tree".
CustomTransitionPage<void> _fadeThroughPage(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
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
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/reauth',
        builder: (context, state) => const ReauthScreen(),
      ),
      GoRoute(
        path: '/kardex',
        builder: (context, state) => const KardexScreen(),
      ),
      GoRoute(
        path: '/academic-status',
        builder: (context, state) => const AcademicStatusScreen(),
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
                _fadeThroughPage(state.pageKey, const HomeScreen()),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const ScheduleScreen()),
          ),
          GoRoute(
            path: '/grades',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const GradesScreen()),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) =>
                _fadeThroughPage(state.pageKey, const TasksScreen()),
          ),
        ],
      ),
    ],
  );
}

final appRouter = buildAppRouter();

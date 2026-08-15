import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/nexus_hero.dart';
import '../../widgets/nexus_wordmark.dart';

/// Arranque de la app: la marca se dibuja mientras por debajo se decide a
/// dónde ir (onboarding, sesión viva, re-login sólo-CAPTCHA o login completo).
///
/// La animación **es** el indicador de carga: no hay spinner. Y se garantiza un
/// tiempo mínimo en pantalla para que, cuando la sesión resuelve en 100 ms, la
/// marca no parpadee.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: AppMotion.intro,
  );

  /// El logo entra con fade y una escala mínima.
  late final Animation<double> _markIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.45, curve: AppMotion.emphasized),
  );

  /// Las aristas se trazan después de que aparecen los nodos.
  late final Animation<double> _edges = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.25, 0.75, curve: Curves.easeInOut),
  );

  /// El nombre entra al final, desplazándose un poco hacia arriba.
  late final Animation<double> _wordmarkIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.55, 1, curve: AppMotion.emphasized),
  );

  /// Se resuelve cuando la animación ya corrió lo suficiente como para no
  /// verse cortada. La navegación espera a esto.
  Future<void>? _minimumDisplay;

  @override
  void initState() {
    super.initState();
    _minimumDisplay = _intro.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().restoreSession();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _goWhenReady(String location) async {
    await _minimumDisplay;
    if (mounted) context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          switch (state) {
            case AuthOnboardingRequired():
              _goWhenReady('/onboarding');
            // El aviso de "sin conexión" lo da Home con su banner de datos en
            // caché: mostrarlo aquí lo dejaba flotando sobre la pantalla
            // siguiente, porque el SnackBar sobrevive a la navegación.
            case AuthSessionRestored():
              _goWhenReady('/home');
            case AuthReauthCaptchaLoading():
            case AuthReauthCaptchaLoaded():
            case AuthReauthFailure():
              _goWhenReady('/reauth');
            case AuthLoginRequired():
              _goWhenReady('/login');
            default:
              break;
          }
        },
        child: Center(
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _markIn.value,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * _markIn.value,
                      // El mismo widget que en login y onboarding, con tag de
                      // Hero para que no se remonte y reinicie entre pantallas.
                      child: Hero(
                        tag: 'nexus-mark',
                        child: NexusHero(size: 140, edgeProgress: _edges.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Opacity(
                    opacity: _wordmarkIn.value,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - _wordmarkIn.value)),
                      child: const NexusWordmark(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

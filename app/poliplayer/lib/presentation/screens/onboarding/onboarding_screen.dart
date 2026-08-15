import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../widgets/nexus_wordmark.dart';
import 'onboarding_art.dart';

class _OnboardingPage {
  final String title;
  final String body;

  const _OnboardingPage({required this.title, required this.body});
}

const _pages = [
  _OnboardingPage(
    title: 'Tu SAES, sin el SAES',
    body: 'Calificaciones, horario y kárdex en un solo lugar, con la sesión '
        'abierta para que no tengas que entrar cada vez.',
  ),
  _OnboardingPage(
    title: 'Tus clases, a tiempo',
    body: 'Tu horario de la semana siempre a la mano y una alarma antes de '
        'cada clase.',
  ),
  _OnboardingPage(
    title: 'Tus tareas, bajo control',
    body: 'Anota entregas con prioridad y fecha. El calendario junta tus '
        'clases y tus tareas en la misma vista.',
  ),
];

/// Bienvenida de primer arranque. Sólo se muestra una vez: el flag vive en la
/// base local (`AppFlagKeys.onboardingSeen`) y lo marca [AuthCubit].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();

  /// Posición continua (no entera) del PageView: permite que la ilustración
  /// reaccione al arrastre y no sólo al cambio de página.
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _index => _page.round();
  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(duration: AppMotion.slow, curve: AppMotion.emphasized);
  }

  void _skip() => _finish();

  /// Marca la bandera y devuelve el control al splash, que decide a dónde ir
  /// según el estado de la sesión.
  Future<void> _finish() async {
    await context.read<AuthCubit>().markOnboardingSeen();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  const NexusWordmark(fontSize: 20, textAlign: TextAlign.left),
                  const Spacer(),
                  // En la última página ya no hay nada que saltar.
                  AnimatedOpacity(
                    duration: AppMotion.normal,
                    opacity: _isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: _isLast ? null : _skip,
                      child: const Text('Saltar'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  // Cuánto de "esta" página se ve: 1 centrada, 0 fuera.
                  final visibility = (1 - (_page - index).abs()).clamp(0.0, 1.0);
                  return _OnboardingPageView(
                    page: _pages[index],
                    index: index,
                    visibility: visibility,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: AppMotion.normal,
                          curve: AppMotion.emphasized,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          // El punto activo se alarga en vez de sólo cambiar
                          // de color: se ve el avance de un vistazo.
                          width: i == _index ? 24 : 6,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: AnimatedSwitcher(
                        duration: AppMotion.normal,
                        child: Text(
                          _isLast ? 'Comenzar' : 'Siguiente',
                          key: ValueKey(_isLast),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final int index;
  final double visibility;

  const _OnboardingPageView({
    required this.page,
    required this.index,
    required this.visibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // La ilustración se mide contra el espacio real: con un tamaño fijo
        // desbordaba la columna en pantallas cortas.
        final artSize = [
          220.0,
          constraints.maxWidth * 0.6,
          constraints.maxHeight * 0.42,
        ].reduce((a, b) => a < b ? a : b);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // La ilustración se dibuja conforme la página entra en pantalla.
                OnboardingArt(page: index, size: artSize, progress: visibility),
                const SizedBox(height: AppSpacing.xl),
                // El texto entra desde abajo, desfasado de la ilustración.
                Opacity(
                  opacity: visibility,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - visibility)),
                    child: Column(
                      children: [
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.heroTitle?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.body?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

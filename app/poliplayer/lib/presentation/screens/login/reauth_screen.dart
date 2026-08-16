import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/captcha_widget.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/nexus_hero.dart';

/// Re-login cuando el SAES mató la sesión: boleta y contraseña las pone el
/// backend (guardadas cifradas), el usuario sólo teclea el CAPTCHA.
///
/// El CAPTCHA no se puede evitar: BotDetect guarda el texto en la Session de
/// ASP.NET del servidor y nunca lo manda al cliente.
class ReauthScreen extends StatefulWidget {
  const ReauthScreen({super.key});

  @override
  State<ReauthScreen> createState() => _ReauthScreenState();
}

class _ReauthScreenState extends State<ReauthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captchaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Si se llegó aquí sin CAPTCHA cargado (p. ej. navegación directa),
      // pedirlo ahora.
      final state = context.read<AuthCubit>().state;
      if (state is! AuthReauthCaptchaLoaded && state is! AuthReauthCaptchaLoading) {
        context.read<AuthCubit>().startReauth();
      }
    });
  }

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().reauth(_captchaController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthSessionRestored) {
                  context.go('/home');
                } else if (state is AuthReauthFailure) {
                  AppSnack.error(context, state.error);
                  _captchaController.clear();
                } else if (state is AuthInitial) {
                  context.go('/login');
                }
              },
              builder: (context, state) {
                final captchaBytes = switch (state) {
                  AuthReauthCaptchaLoaded(:final captchaBytes) => captchaBytes,
                  AuthReauthLoading(:final captchaBytes) => captchaBytes,
                  AuthReauthFailure(:final captchaBytes) => captchaBytes,
                  _ => null,
                };
                final isCaptchaLoading = state is AuthReauthCaptchaLoading;
                final isSubmitting = state is AuthReauthLoading;

                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Hero(tag: 'nexus-mark', child: NexusHero(size: 110)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Bienvenido de nuevo',
                        textAlign: TextAlign.center,
                        style: textTheme.heroTitle?.copyWith(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'El SAES cerró la sesión. Teclea el código para volver a entrar.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySecondary?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CaptchaWidget(
                              imageBytes: captchaBytes,
                              isLoading: isCaptchaLoading,
                              onReload: () => context.read<AuthCubit>().startReauth(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _captchaController,
                              decoration: const InputDecoration(labelText: 'Código'),
                              enabled: !isCaptchaLoading && !isSubmitting,
                              autofocus: true,
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FilledButton(
                        onPressed: (isCaptchaLoading || isSubmitting) ? null : _submit,
                        child: AnimatedSwitcher(
                          duration: AppMotion.normal,
                          switchInCurve: AppMotion.emphasized,
                          switchOutCurve: AppMotion.emphasizedAccelerate,
                          child: isSubmitting
                              ? SizedBox(
                                  key: const ValueKey('loading'),
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Continuar',
                                  key: const ValueKey('label'),
                                  style: textTheme.actionLabel
                                      ?.copyWith(color: colorScheme.onPrimary),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => context.read<AuthCubit>().cancelReauth(),
                        child: const Text('Entrar con otra cuenta'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/constants/saes_schools.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/captcha_widget.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/nexus_hero.dart';
import '../../widgets/nexus_wordmark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _boletaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  IpnSchool _selectedSchool = IpnSchool.upiicsa; // Por defecto UPIICSA
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().fetchCaptchaForSchool(_selectedSchool);
    });
  }

  @override
  void dispose() {
    _boletaController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _onSchoolChanged(IpnSchool? school) {
    if (school != null && school != _selectedSchool) {
      setState(() => _selectedSchool = school);
      _captchaController.clear();
      context.read<AuthCubit>().fetchCaptchaForSchool(school);
    }
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().login(
            boleta: _boletaController.text.trim(),
            password: _passwordController.text,
            captchaText: _captchaController.text.trim(),
          );
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
                if (state is AuthLoginSuccess) {
                  context.go('/home');
                } else if (state is AuthLoginFailure) {
                  AppSnack.error(context, state.error);
                  _captchaController.clear();
                } else if (state is AuthCaptchaError) {
                  AppSnack.error(context, state.message);
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthCaptchaLoading || state is AuthLoginLoading || state is AuthInitial;
                final isLoginLoading = state is AuthLoginLoading;

                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mismo tag que en el splash: el logo viaja entre
                      // pantallas en vez de remontarse y reiniciar su
                      // animación.
                      const Center(
                        child: Hero(tag: 'nexus-mark', child: NexusHero(size: 110)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const NexusWordmark(),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Conéctate a tu SAES',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Dropdown de Escuela
                      DropdownButtonFormField<IpnSchool>(
                        initialValue: _selectedSchool,
                        isExpanded: true,
                        icon: Icon(Symbols.keyboard_arrow_down_rounded, color: colorScheme.primary),
                        decoration: InputDecoration(
                          labelText: 'Plantel',
                          prefixIcon: Icon(Symbols.account_balance_rounded, color: colorScheme.primary),
                        ),
                        items: IpnSchool.values.map((school) {
                          return DropdownMenuItem(
                            value: school,
                            child: Text(
                              school.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: isLoginLoading ? null : _onSchoolChanged,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Campo Boleta
                      TextFormField(
                        controller: _boletaController,
                        decoration: InputDecoration(
                          labelText: 'Boleta',
                          prefixIcon: Icon(Symbols.person_rounded, color: colorScheme.primary),
                        ),
                        keyboardType: TextInputType.text,
                        enabled: !isLoginLoading,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ingresa tu boleta' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Campo Contraseña
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Symbols.lock_rounded, color: colorScheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        enabled: !isLoginLoading,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ingresa tu contraseña' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // CAPTCHA Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CaptchaWidget(
                              imageBytes: (state is AuthCaptchaLoaded)
                                  ? state.captchaBytes
                                  : (state is AuthLoginFailure ? state.captchaBytes : null),
                              isLoading: isLoading && !isLoginLoading,
                              onReload: () => context.read<AuthCubit>().reloadCaptcha(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _captchaController,
                              decoration: const InputDecoration(labelText: 'Código'),
                              enabled: !isLoading,
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Botón Iniciar Sesión estilo Gemini
                      FilledButton(
                        onPressed: isLoading ? null : _submitLogin,
                        child: AnimatedSwitcher(
                          duration: AppMotion.normal,
                          switchInCurve: AppMotion.emphasized,
                          switchOutCurve: AppMotion.emphasizedAccelerate,
                          child: isLoginLoading
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
                                  'Iniciar Sesión',
                                  key: const ValueKey('label'),
                                  style: textTheme.actionLabel?.copyWith(color: colorScheme.onPrimary),
                                ),
                        ),
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

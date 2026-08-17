import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/kardex/kardex_cubit.dart';
import '../../blocs/kardex/kardex_state.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/profile/profile_state.dart';
import '../../blocs/reinscription/reinscription_cubit.dart';
import '../../blocs/reinscription/reinscription_state.dart';
import '../../widgets/animated_entrance.dart';
import '../../widgets/app_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/stale_data_banner.dart';
import '../../widgets/status_view.dart';

String _loginRoute() => getIt<AuthRepository>().currentAccountId != null ? '/reauth' : '/login';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>.value(value: getIt<ProfileCubit>()..loadProfile()),
        // Carrera/promedio y créditos ya se descargan para Kárdex/Estado y
        // reinscripción — Perfil sólo los reutiliza, no pide nada nuevo al
        // SAES. Cargas independientes: si una falla o tarda, no bloquea el
        // resto de la pantalla (cada tarjeta se auto-oculta si su cubit no
        // ha resuelto).
        BlocProvider<KardexCubit>.value(value: getIt<KardexCubit>()..loadKardex()),
        BlocProvider<ReinscriptionCubit>.value(
          value: getIt<ReinscriptionCubit>()..loadReinscription(),
        ),
      ],
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Título fijo — el nombre vive centrado bajo la foto en `_ProfileHeader`,
    // no en el AppBar (la foto debe ser el elemento más predominante).
    final appBar = SliverAppBar.large(
      title: Text('Perfil', style: theme.textTheme.heroTitle),
      backgroundColor: theme.colorScheme.surface,
      scrolledUnderElevation: 0,
    );

    return Scaffold(
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() || ProfileLoading() => CustomScrollView(
                slivers: [
                  appBar,
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: SkeletonList(itemCount: 2),
                    ),
                  ),
                ],
              ),
            ProfileError(:final message, :final sessionRequired) when sessionRequired =>
              CustomScrollView(
                slivers: [
                  appBar,
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: StatusView.error(
                      title: 'Requiere sesión',
                      icon: Symbols.lock_rounded,
                      actionLabel: 'Iniciar sesión',
                      message: message,
                      onRetry: () => context.go(_loginRoute()),
                    ),
                  ),
                ],
              ),
            ProfileError(:final message) => CustomScrollView(
                slivers: [
                  appBar,
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: StatusView.error(
                      message: message,
                      onRetry: () => context.read<ProfileCubit>().loadProfile(force: true),
                    ),
                  ),
                ],
              ),
            ProfileLoaded(:final profile, :final fetchedAt, :final fromCache, :final sessionExpired) =>
              RefreshIndicator(
                onRefresh: () => context.read<ProfileCubit>().loadProfile(force: true),
                child: CustomScrollView(
                  slivers: [
                    appBar,
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (fromCache) ...[
                              StaleDataBanner(
                                fetchedAt: fetchedAt,
                                sessionExpired: sessionExpired,
                                onLoginTap:
                                    sessionExpired ? () => context.go(_loginRoute()) : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            AnimatedEntrance(
                              index: 0,
                              child: _ProfileHeader(profile: profile),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const AnimatedEntrance(index: 1, child: _AcademicCard()),
                            const AnimatedEntrance(index: 2, child: _CreditsProgressCard()),
                            AnimatedEntrance(
                              index: 3,
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InfoRow(label: 'Boleta', value: profile.boleta),
                                    const SizedBox(height: AppSpacing.md),
                                    _InfoRow(label: 'Plantel', value: profile.plantel),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const AnimatedEntrance(index: 4, child: _LogoutButton()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

/// Foto + nombre, centrados — la foto es el elemento predominante (grande,
/// degradado de marca), el nombre va debajo en un peso subordinado a ella
/// (no repite el tamaño del AppBar, que ahora es un título fijo "Perfil").
class _ProfileHeader extends StatelessWidget {
  final Profile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = AppTheme.brandGradient(theme.brightness);
    final initial = profile.nombre.trim().isEmpty ? '' : profile.nombre.trim()[0].toUpperCase();

    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          alignment: Alignment.center,
          child: initial.isEmpty
              ? const Icon(Symbols.person_rounded, size: AppIconSize.lg, color: Colors.white)
              : Text(
                  initial,
                  style: theme.textTheme.heroTitle?.copyWith(
                    color: Colors.white,
                    fontSize: 44,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.nombre,
          textAlign: TextAlign.center,
          style: theme.textTheme.sectionTitle?.copyWith(color: colorScheme.onSurface),
        ),
        if (profile.plantel.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            profile.plantel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Carrera + promedio general — mismo patrón que `_AverageCard` de Notas
/// (número grande animado). No bloquea Perfil: si Kárdex aún no resuelve o
/// falla, la tarjeta simplemente no se muestra en vez de tapar el resto de
/// la pantalla con un error.
class _AcademicCard extends StatelessWidget {
  const _AcademicCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KardexCubit, KardexState>(
      builder: (context, state) {
        if (state is! KardexLoaded) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final average = double.tryParse(state.kardex.average.trim());

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.kardex.career.isEmpty ? 'Promedio general' : state.kardex.career,
                        style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: average ?? 0),
                        duration: AppMotion.slow,
                        curve: AppMotion.emphasized,
                        builder: (context, value, _) => Text(
                          average == null ? '—' : value.toStringAsFixed(2),
                          style: theme.textTheme.metric?.copyWith(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Promedio',
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Barra de progreso de créditos obtenidos vs. totales del plan. No bloquea
/// Perfil: si Reinscripción aún no resuelve o falla, no se muestra.
class _CreditsProgressCard extends StatelessWidget {
  const _CreditsProgressCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReinscriptionCubit, ReinscriptionState>(
      builder: (context, state) {
        if (state is! ReinscriptionLoaded) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final earned = double.tryParse(state.reinscription.creditsEarned.trim());
        final total = double.tryParse(state.reinscription.totalCredits.trim());
        if (earned == null || total == null || total <= 0) return const SizedBox.shrink();

        final progress = (earned / total).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avance de créditos',
                  style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: AppMotion.slow,
                    curve: AppMotion.emphasized,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${state.reinscription.creditsEarned} de ${state.reinscription.totalCredits} créditos',
                  style: theme.textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cierra sesión de verdad (olvida credenciales) — antes no existía ningún
/// botón para esto en toda la app. Confirmación previa: es difícil de
/// deshacer desde la perspectiva del usuario (hay que volver a loguearse).
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error),
      ),
      onPressed: () => _confirmAndLogout(context),
      icon: const Icon(Symbols.logout_rounded, size: AppIconSize.sm),
      label: const Text('Cerrar sesión'),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Vas a salir de tu cuenta del SAES en este dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // `getIt`, no `context.read`: `AuthCubit` es factory (una instancia
    // nueva por flujo de login), Perfil no tiene por qué depender de que
    // esté provisto ambientalmente en su árbol.
    await getIt<AuthCubit>().logout();
    if (context.mounted) context.go('/login');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.trim().isEmpty ? 'Sin especificar' : value,
          style: theme.textTheme.cardTitle,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

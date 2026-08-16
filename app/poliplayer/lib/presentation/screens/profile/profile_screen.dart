import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/profile/profile_state.dart';
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
    return BlocProvider<ProfileCubit>.value(
      value: getIt<ProfileCubit>()..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // El AppBar grande usa el nombre del alumno como título en cuanto se
    // conoce — "Perfil" es sólo el placeholder mientras carga/si falla.
    SliverAppBar appBar(String title) => SliverAppBar.large(
          title: Text(title, style: theme.textTheme.heroTitle),
          backgroundColor: theme.colorScheme.surface,
          scrolledUnderElevation: 0,
        );

    return Scaffold(
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() || ProfileLoading() => CustomScrollView(
                slivers: [
                  appBar('Perfil'),
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
                  appBar('Perfil'),
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
                  appBar('Perfil'),
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
                    appBar(profile.nombre),
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
                            AnimatedEntrance(
                              index: 1,
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

/// Avatar + plantel: el nombre ya vive en el título del AppBar, no se repite
/// al mismo peso aquí.
class _ProfileHeader extends StatelessWidget {
  final Profile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = AppTheme.brandGradient(theme.brightness);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: const Icon(Symbols.person_rounded, size: AppIconSize.lg, color: Colors.white),
        ),
        if (profile.plantel.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
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

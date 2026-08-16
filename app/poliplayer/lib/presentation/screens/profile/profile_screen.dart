import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/profile/profile_cubit.dart';
import '../../blocs/profile/profile_state.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() || ProfileLoading() => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonList(itemCount: 2),
              ),
            ProfileError(:final message, :final sessionRequired) when sessionRequired =>
              StatusView.error(
                title: 'Requiere sesión',
                icon: Symbols.lock_rounded,
                actionLabel: 'Iniciar sesión',
                message: message,
                onRetry: () => context.go(_loginRoute()),
              ),
            ProfileError(:final message) => StatusView.error(
                message: message,
                onRetry: () => context.read<ProfileCubit>().loadProfile(force: true),
              ),
            ProfileLoaded(:final profile, :final fetchedAt, :final fromCache, :final sessionExpired) =>
              RefreshIndicator(
                onRefresh: () => context.read<ProfileCubit>().loadProfile(force: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    if (fromCache) ...[
                      StaleDataBanner(
                        fetchedAt: fetchedAt,
                        sessionExpired: sessionExpired,
                        onLoginTap: sessionExpired ? () => context.go(_loginRoute()) : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _ProfileHeader(profile: profile),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(label: 'Boleta', value: profile.boleta),
                          const SizedBox(height: AppSpacing.md),
                          _InfoRow(label: 'Plantel', value: profile.plantel),
                        ],
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

class _ProfileHeader extends StatelessWidget {
  final Profile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(
            Symbols.person_rounded,
            size: AppIconSize.lg,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.nombre,
          textAlign: TextAlign.center,
          style: theme.textTheme.sectionTitle?.copyWith(color: colorScheme.onSurface),
        ),
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
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

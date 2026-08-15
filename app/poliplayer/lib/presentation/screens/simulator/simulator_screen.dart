import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/grades/grades_cubit.dart';
import '../../blocs/grades/grades_state.dart';
import '../../widgets/status_view.dart';
import 'simulator_form.dart';

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GradesCubit>(
      create: (_) => getIt<GradesCubit>()..loadGrades(),
      child: const _SimulatorView(),
    );
  }
}

class _SimulatorView extends StatelessWidget {
  const _SimulatorView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Simulador de promedio')),
      body: BlocBuilder<GradesCubit, GradesState>(
        builder: (context, state) {
          return switch (state) {
            GradesInitial() || GradesLoading() => const Center(child: CircularProgressIndicator()),
            GradesError(:final message) => StatusView.error(
                message: message,
                onRetry: () => context.read<GradesCubit>().loadGrades(),
              ),
            GradesLoaded(:final entries) when entries.isEmpty => Center(
                child: Text(
                  'No hay materias inscritas para simular.',
                  style: theme.textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            GradesLoaded(:final entries) => SimulatorForm(entries: entries),
          };
        },
      ),
    );
  }
}

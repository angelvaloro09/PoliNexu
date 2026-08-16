import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/task_icons.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_motion.dart';
import '../../../domain/models/task_item.dart';
import '../../blocs/schedule/schedule_cubit.dart';
import '../../blocs/schedule/schedule_state.dart';
import '../../blocs/tasks/tasks_cubit.dart';
import '../../blocs/tasks/tasks_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_list_row.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/priority_flag.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_view.dart';
import '../../widgets/animated_entrance.dart';
import 'task_form_sheet.dart';

List<String> _scheduleSubjects() {
  final state = getIt<ScheduleCubit>().state;
  if (state is! ScheduleLoaded) return const [];
  return state.entries.map((e) => e.subject).toSet().toList()..sort();
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TasksCubit>.value(
      value: getIt<TasksCubit>(),
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatefulWidget {
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  bool _isFabVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: AnimatedSlide(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: () => showTaskFormSheet(
              context,
              cubit: context.read<TasksCubit>(),
              subjectOptions: _scheduleSubjects(),
            ),
            icon: const Icon(Symbols.add_rounded),
            label: const Text('Nueva tarea'),
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            if (!_isFabVisible) setState(() => _isFabVisible = true);
          } else if (notification.direction == ScrollDirection.reverse) {
            if (_isFabVisible) setState(() => _isFabVisible = false);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text('Tareas', style: theme.textTheme.heroTitle),
              backgroundColor: theme.colorScheme.surface,
              scrolledUnderElevation: 0,
            ),
            const SliverToBoxAdapter(
              child: _TaskListView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        return switch (state) {
          TasksInitial() => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SkeletonList(itemCount: 4),
            ),
          TasksError(:final message) => AnimatedEntrance(
              child: StatusView.error(
                message: message,
                onRetry: () => AppSnack.error(context, 'Reinicia la app para continuar.'),
              ),
            ),
          TasksLoaded(:final tasks) when tasks.isEmpty => AnimatedEntrance(
              child: StatusView.empty(
                icon: Symbols.task_alt_rounded,
                title: 'Sin tareas',
                message: 'Anota entregas, exámenes o pendientes y te avisamos a tiempo.',
                actionLabel: 'Crear la primera',
                useBrandMark: true,
                onAction: () => showTaskFormSheet(
                  context,
                  cubit: context.read<TasksCubit>(),
                  subjectOptions: _scheduleSubjects(),
                ),
              ),
            ),
          TasksLoaded(:final tasks) => _TaskList(tasks: _sorted(tasks)),
        };
      },
    );
  }

  List<TaskItem> _sorted(List<TaskItem> tasks) {
    final sorted = [...tasks];
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue == null && bDue == null) return 0;
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });
    return sorted;
  }
}

class _TaskList extends StatelessWidget {
  final List<TaskItem> tasks;

  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.isCompleted).length;
    final theme = Theme.of(context);

    // Ya que usamos SliverToBoxAdapter arriba, podemos usar ListView con
    // shrinkWrap o directamente mapear los elementos a un Column.
    // Como las listas de tareas no suelen ser de miles de items y la
    // animación escalonada funciona mejor rindiéndolos todos a la vez,
    // usaremos Column en vez de ListView dentro de CustomScrollView.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl + AppSpacing.xl, // FAB padding
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedEntrance(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: pending == 0
                  ? Text('Todo al corriente', style: theme.textTheme.sectionTitle)
                  // Mismo patrón de número animado que `_AverageCard` en
                  // Grades: el conteo se vuelve el elemento hero de la
                  // pantalla en vez de texto plano del mismo peso que todo
                  // lo demás.
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pending.toDouble()),
                          duration: AppMotion.slow,
                          curve: AppMotion.emphasized,
                          builder: (context, value, _) => Text(
                            '${value.round()}',
                            style: theme.textTheme.metric?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          pending == 1 ? 'pendiente' : 'pendientes',
                          style: theme.textTheme.bodySecondary?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          for (var i = 0; i < tasks.length; i++) ...[
            AnimatedEntrance(
              index: i + 1,
              child: _TaskTile(task: tasks[i]),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskItem task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<TasksCubit>();

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: AppRadius.lgAll,
        ),
        child: Icon(Symbols.delete_rounded, color: colorScheme.onErrorContainer),
      ),
      onDismissed: (_) {
        cubit.deleteTask(task.id!);
        AppSnack.undo(
          context,
          message: 'Tarea eliminada',
          onUndo: () => cubit.addTask(task),
        );
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => showTaskFormSheet(
          context,
          cubit: cubit,
          task: task,
          subjectOptions: _scheduleSubjects(),
        ),
        child: AppListRow(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => cubit.toggleCompleted(task),
              ),
              Icon(
                resolveTaskIcon(task.iconKey),
                size: AppIconSize.sm,
                color: task.isCompleted
                    ? colorScheme.onSurfaceVariant
                    : priorityColor(colorScheme, task.priority),
              ),
            ],
          ),
          title: task.title,
          strikethrough: task.isCompleted,
          subtitle: _subtitle(context),
          trailing: PriorityFlag(priority: task.priority),
        ),
      ),
    );
  }

  String? _subtitle(BuildContext context) {
    final due = task.dueDate;
    if (due == null) return task.description?.trim().isEmpty ?? true ? null : task.description;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(today).inDays;

    final timeStr = task.hasTime ? DateFormat(" 'a las' h:mm a", 'es_MX').format(due) : '';
    
    final isExamOrEvent = task.type == TaskType.examen || task.type == TaskType.eventoImportante;
    final prefixHoy = isExamOrEvent ? 'Hoy' : 'Vence hoy';
    final prefixManana = isExamOrEvent ? 'Mañana' : 'Vence mañana';
    final prefixAyer = isExamOrEvent ? 'Fue ayer' : 'Venció ayer';
    final prefixPasado = isExamOrEvent ? 'Fue el' : 'Venció el';
    final prefixFuturo = isExamOrEvent ? 'En' : 'Vence en';

    return switch (days) {
      0 => '$prefixHoy$timeStr',
      1 => '$prefixManana$timeStr',
      -1 => '$prefixAyer$timeStr',
      < 0 => '$prefixPasado ${DateFormat("d 'de' MMMM", 'es_MX').format(due)}$timeStr',
      < 7 => '$prefixFuturo $days días$timeStr',
      _ => '${DateFormat("d 'de' MMMM", 'es_MX').format(due)}$timeStr',
    };
  }
}

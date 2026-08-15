import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/task_item.dart';
import '../../blocs/schedule/schedule_cubit.dart';
import '../../blocs/tasks/tasks_cubit.dart';
import '../../blocs/tasks/tasks_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_list_row.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/priority_flag.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_view.dart';
import 'task_calendar_view.dart';
import 'task_form_sheet.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TasksCubit>(create: (_) => getIt<TasksCubit>()),
        // El Horario se usa en la pestaña Calendario para unificar clases + tareas.
        BlocProvider<ScheduleCubit>(create: (_) => getIt<ScheduleCubit>()..loadSchedule()),
      ],
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatelessWidget {
  const _TasksView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tareas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lista'),
              Tab(text: 'Calendario'),
            ],
          ),
        ),
        // Extendido: en la vista de lista el botón principal merece etiqueta,
        // y el ícono solo obligaba a adivinar qué crea.
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showTaskFormSheet(context, cubit: context.read<TasksCubit>()),
          icon: const Icon(Symbols.add_rounded),
          label: const Text('Nueva tarea'),
        ),
        body: const TabBarView(
          children: [
            _TaskListView(),
            TaskCalendarView(),
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
          TasksError(:final message) => StatusView.error(
              message: message,
              // La lista viene de un Stream de Drift: reabrir el formulario no
              // arregla nada, pero volver a la pestaña sí re-suscribe.
              onRetry: () => DefaultTabController.of(context).animateTo(0),
            ),
          TasksLoaded(:final tasks) when tasks.isEmpty => StatusView.empty(
              icon: Symbols.task_alt_rounded,
              title: 'Sin tareas',
              message: 'Anota entregas, exámenes o pendientes y te avisamos a tiempo.',
              actionLabel: 'Crear la primera',
              onAction: () => showTaskFormSheet(context, cubit: context.read<TasksCubit>()),
            ),
          TasksLoaded(:final tasks) => _TaskList(tasks: _sorted(tasks)),
        };
      },
    );
  }

  /// Pendientes primero, luego por prioridad y fecha.
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

  // La lista llega ya ordenada: antes se reordenaba dentro de `itemCount` y
  // otra vez dentro de cada `itemBuilder`, o sea una vez por fila pintada.
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.isCompleted).length;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        // Espacio para que el FAB extendido no tape la última tarjeta.
        AppSpacing.xxl + AppSpacing.xl,
      ),
      itemCount: tasks.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          final theme = Theme.of(context);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              pending == 0
                  ? 'Todo al corriente'
                  : '$pending pendiente${pending == 1 ? '' : 's'}',
              style: theme.textTheme.sectionTitle,
            ),
          );
        }
        return _TaskTile(task: tasks[index - 1]);
      },
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
          // Mismo radio que la tarjeta: con uno menor, el fondo rojo asomaba
          // por las esquinas al deslizar.
          borderRadius: AppRadius.lgAll,
        ),
        child: Icon(Symbols.delete_rounded, color: colorScheme.onErrorContainer),
      ),
      onDismissed: (_) {
        cubit.deleteTask(task.id!);
        // Borrar era inmediato e irreversible; ahora hay ventana para revertir.
        AppSnack.undo(
          context,
          message: 'Tarea eliminada',
          onUndo: () => cubit.addTask(task),
        );
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        child: AppListRow(
          onTap: () => showTaskFormSheet(context, cubit: cubit, task: task),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => cubit.toggleCompleted(task),
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

    // Relativo cuando está cerca, que es cuando importa; fecha si está lejos.
    return switch (days) {
      0 => 'Vence hoy',
      1 => 'Vence mañana',
      -1 => 'Venció ayer',
      < 0 => 'Venció el ${DateFormat("d 'de' MMMM", 'es_MX').format(due)}',
      < 7 => 'Vence en $days días',
      _ => DateFormat("d 'de' MMMM", 'es_MX').format(due),
    };
  }
}

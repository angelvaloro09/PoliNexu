import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../blocs/auth/auth_cubit.dart';

class _ShellDestination {
  final String path;
  final String label;
  final IconData icon;

  const _ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
  });
}

const _destinations = [
  _ShellDestination(path: '/home', label: 'Inicio', icon: Symbols.home_rounded),
  _ShellDestination(path: '/schedule', label: 'Horario', icon: Symbols.calendar_today_rounded),
  _ShellDestination(path: '/grades', label: 'Notas', icon: Symbols.school_rounded),
  _ShellDestination(path: '/tasks', label: 'Tareas', icon: Symbols.checklist_rounded),
];

/// Shell de navegación principal (Material 3 `NavigationBar`) para las
/// rutas envueltas por el `ShellRoute` en `app_router.dart`.
///
/// Los íconos usan Material Symbols (`Symbols.xxx_rounded`) — el mismo glifo
/// se usa sin/con relleno (`fill: 0`/`1`) para el estado normal/seleccionado,
/// igual que en Gemini/NotebookLM, en vez de alternar entre dos pictogramas
/// distintos (`_outlined` vs. sólido) como en Material Icons clásico.
class MainShell extends StatefulWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.child, required this.location});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int get _selectedIndex {
    final index = _destinations.indexWhere((d) => widget.location.startsWith(d.path));
    return index == -1 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver a primer plano se hace ping al SAES: resetea el sliding timeout
  /// de la sesión. Ya no navega automáticamente si murió — modo offline:
  /// Inicio/Horario/Tareas se siguen viendo con lo último en caché; la
  /// notificación de sesión muerta (disparada por el repo en el próximo fetch
  /// fallido) es el aviso, y sólo se pide re-login al entrar a una pantalla
  /// que de verdad lo requiera (Notas/Kárdex).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    context.read<AuthCubit>().keepAliveOrReauth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // La transición entre pestañas la hace el Navigator del ShellRoute
      // (`CustomTransitionPage` en app_router.dart), no un AnimatedSwitcher
      // aquí: envolver `child` mantiene vivo el saliente y go_router reutiliza
      // su GlobalKey → "Duplicate GlobalKey detected in widget tree".
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => context.go(_destinations[index].path),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.icon, fill: 1),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../blocs/auth/auth_cubit.dart';

class _ShellDestination {
  final String path;
  final String label;
  final Widget Function(bool selected) iconBuilder;

  const _ShellDestination({
    required this.path,
    required this.label,
    required this.iconBuilder,
  });
}

const _ipnLogoAsset = 'assets/branding/ipn-logo.png';

final List<_ShellDestination> _destinations = [
  _ShellDestination(
    path: '/home',
    label: 'Inicio',
    iconBuilder: _symbolIcon(Symbols.home_rounded),
  ),
  _ShellDestination(
    path: '/schedule',
    label: 'Horario',
    iconBuilder: _symbolIcon(Symbols.calendar_today_rounded),
  ),
  _ShellDestination(
    path: '/grades',
    label: 'Notas',
    iconBuilder: _ipnLogoIcon,
  ),
  _ShellDestination(
    path: '/tasks',
    label: 'Tareas',
    iconBuilder: _symbolIcon(Symbols.checklist_rounded),
  ),
  _ShellDestination(
    path: '/profile',
    label: 'Perfil',
    iconBuilder: _symbolIcon(Symbols.person_rounded),
  ),
];

/// Fábrica de `iconBuilder` para destinos con Material Symbol: mismo glifo
/// sin/con relleno (`fill: 0`/`1`) según selección, como en Gemini/NotebookLM.
Widget Function(bool selected) _symbolIcon(IconData icon) {
  return (selected) => Icon(icon, fill: selected ? 1 : 0);
}

/// El destino "Notas" usa el escudo del IPN en vez de un Material Symbol —
/// un PNG no tiene el eje de relleno variable, así que no hay variante
/// seleccionada/no seleccionada: el pill/indicador que ya dibuja
/// `NavigationBar` detrás del ícono activo es suficiente señal.
Widget _ipnLogoIcon(bool selected) {
  // El PNG original es guinda — se recolorea a blanco sólido (máscara sobre
  // los píxeles opacos) para que combine con el resto de íconos del navbar
  // en vez de desentonar con el color institucional del IPN.
  return Image.asset(
    _ipnLogoAsset,
    width: 24,
    height: 24,
    color: Colors.white,
    colorBlendMode: BlendMode.srcIn,
  );
}

/// Shell de navegación principal (Material 3 `NavigationBar`) para las
/// rutas envueltas por el `ShellRoute` en `app_router.dart`.
///
/// El navbar es sólo-íconos (`labelBehavior: alwaysHide`) para que quepan
/// 5 destinos sin textos cortados — `label` se conserva en cada
/// `NavigationDestination` únicamente para accesibilidad/tooltip, no se ve.
/// Cada destino resuelve su ícono vía `iconBuilder`: la mayoría son Material
/// Symbols (`Symbols.xxx_rounded`, con el truco de `fill: 0/1` para el estado
/// seleccionado, igual que en Gemini/NotebookLM), salvo "Notas" que usa el
/// escudo del IPN como `Image.asset`.
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
    final selectedIndex = _selectedIndex;
    return Scaffold(
      // La transición entre pestañas la hace el Navigator del ShellRoute
      // (`CustomTransitionPage` en app_router.dart), no un AnimatedSwitcher
      // aquí: envolver `child` mantiene vivo el saliente y go_router reutiliza
      // su GlobalKey → "Duplicate GlobalKey detected in widget tree".
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: (index) => context.go(_destinations[index].path),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: destination.iconBuilder(false),
              selectedIcon: destination.iconBuilder(true),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

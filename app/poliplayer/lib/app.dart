import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_cubit.dart';
import 'presentation/router/app_router.dart';

class PoliNexuApp extends StatelessWidget {
  /// Router a usar; por defecto el singleton de la app. Los tests deben
  /// pasar su propia instancia (ver `buildAppRouter()`).
  final GoRouter? router;

  const PoliNexuApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => getIt<AuthCubit>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'PoliNexu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // Sin esto, los widgets de Material que traen su propio texto
        // (`showDatePicker`, el chrome de `TableCalendar`, los labels de
        // accesibilidad) salen en inglés dentro de una app en español.
        locale: const Locale('es', 'MX'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'MX'),
          Locale('es'),
        ],
        // Limita el escalado de texto del sistema: por encima de 1.3 los
        // layouts de tarjetas con métricas grandes se desbordan.
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: router ?? appRouter,
      ),
    );
  }
}

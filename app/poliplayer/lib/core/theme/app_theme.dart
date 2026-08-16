import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Tema de la app: Material 3, estilo Gemini/Material You.
///
/// Claro y oscuro se construyen con la **misma** función a partir de su
/// `ColorScheme`; no hay dos copias del theme que se puedan desincronizar.
class AppTheme {
  AppTheme._();

  // Semillas de marca. Paleta fija (sin color dinámico) para que la identidad
  // sea la misma en todos los dispositivos, como hace Gemini con su azul.
  static const Color geminiSeedLight = Color(0xFF1E63D1);
  static const Color geminiSeedDark = Color(0xFFA8C7FA);

  /// Degradado de la marca (NexusMark/NexusHero, ícono de launcher).
  ///
  /// Dos tonos del **mismo** azul, no un salto a `tertiary`: el acento
  /// terciario que deriva el algoritmo tonal de esta semilla es turquesa y
  /// desplaza la identidad fuera del azul de marca.
  static const List<Color> brandGradientLight = [Color(0xFF1E63D1), Color(0xFF5B93F5)];
  static const List<Color> brandGradientDark = [Color(0xFFA8C7FA), Color(0xFF7FA8E8)];

  static List<Color> brandGradient(Brightness brightness) =>
      brightness == Brightness.light ? brandGradientLight : brandGradientDark;

  // La rampa de superficies se fija completa a mano. Si sólo se fijan `surface`
  // y `surfaceContainerHighest`, los escalones intermedios los genera el
  // algoritmo tonal a partir de la semilla y no casan con los dos extremos
  // elegidos — las tarjetas quedaban a un salto de color distinto según el rol.
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: geminiSeedLight,
    brightness: Brightness.light,
    surface: const Color(0xFFF8F9FA),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF3F4F6),
    surfaceContainer: const Color(0xFFEDEEF1),
    surfaceContainerHigh: const Color(0xFFE8EAED),
    surfaceContainerHighest: const Color(0xFFE1E4E8),
  );

  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: geminiSeedDark,
    brightness: Brightness.dark,
    surface: const Color(0xFF131314),
    surfaceContainerLowest: const Color(0xFF0E0E0F),
    surfaceContainerLow: const Color(0xFF1B1B1D),
    surfaceContainer: const Color(0xFF1E1F21),
    surfaceContainerHigh: const Color(0xFF232426),
    surfaceContainerHighest: const Color(0xFF282A2C),
  );

  static ThemeData get lightTheme => _build(lightColorScheme);
  static ThemeData get darkTheme => _build(darkColorScheme);

  // Plus Jakarta Sans — alternativa OFL más cercana a Google Sans/Product Sans.
  // Se sirve desde `assets/fonts` (declarada en pubspec.yaml): `google_fonts`
  // la descargaría por red en el primer arranque y sin conexión la app entera
  // caería a Roboto.
  static const String fontFamily = 'PlusJakartaSans';

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    return base.apply(fontFamily: fontFamily);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final textTheme = _textTheme(colorScheme.brightness);
    final isLight = colorScheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      fontFamily: fontFamily,
      splashFactory: InkSparkle.splashFactory,

      // ---- Navegación -----------------------------------------------------
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: AppIconSize.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        height: 72,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.meta?.copyWith(
            color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          // El color del ícono seleccionado debe ser el `on-` del contenedor
          // que se usa como indicador, o el contraste no está garantizado.
          return IconThemeData(
            size: AppIconSize.md,
            color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.actionLabel,
        unselectedLabelStyle: textTheme.actionLabel,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
        ),
        overlayColor: WidgetStatePropertyAll(colorScheme.primary.withValues(alpha: 0.06)),
      ),
      // Transición M3 "fade forwards": la saliente se desvanece hacia atrás
      // mientras la entrante avanza. La app es sólo Android.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      // ---- Botones --------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(style: _filledStyle(colorScheme, textTheme)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _outlinedStyle(colorScheme, textTheme)),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.mdAll)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            return colorScheme.primary;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.actionLabel),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconSize: const WidgetStatePropertyAll(AppIconSize.md),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            return colorScheme.onSurfaceVariant;
          }),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // Elevación 0 como todo lo demás: la jerarquía es por color, no por sombra.
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        extendedTextStyle: textTheme.actionLabel,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.lgAll)),
          side: WidgetStatePropertyAll(BorderSide(color: colorScheme.outlineVariant)),
          textStyle: WidgetStatePropertyAll(textTheme.meta),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.secondaryContainer
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant;
          }),
        ),
      ),

      // ---- Superficies ----------------------------------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.sectionTitle?.copyWith(color: colorScheme.onSurface),
        contentTextStyle: textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: textTheme.cardTitle?.copyWith(color: colorScheme.onSurface),
        subtitleTextStyle: textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
        iconColor: colorScheme.onSurfaceVariant,
        minVerticalPadding: AppSpacing.sm,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: isLight ? 0.6 : 0.4),
        thickness: 1,
        space: 1,
      ),
      // `ExpansionTile` dibuja un borde/divisor propio arriba y abajo por
      // defecto (independiente de `dividerTheme`) — se anula aquí para que
      // se lea como una tarjeta plana más, no como un `ListTile` clásico.
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        collapsedBackgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide.none,
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide.none,
        ),
        iconColor: colorScheme.onSurfaceVariant,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.08),
        labelStyle: textTheme.meta?.copyWith(color: colorScheme.onSurfaceVariant),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      ),

      // ---- Entrada --------------------------------------------------------
      inputDecorationTheme: _inputTheme(colorScheme, textTheme),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: colorScheme.outline, width: 2),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? colorScheme.primary : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.outline;
        }),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        headerBackgroundColor: colorScheme.surfaceContainerHigh,
        headerForegroundColor: colorScheme.onSurface,
        todayBorder: BorderSide(color: colorScheme.primary),
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: _inputTheme(colorScheme, textTheme),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: textTheme.body?.copyWith(color: colorScheme.onSurface),
      ),

      // ---- Feedback -------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodySecondary?.copyWith(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
        strokeWidth: 2.5,
        strokeCap: StrokeCap.round,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: textTheme.meta?.copyWith(color: colorScheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        waitDuration: AppMotion.slow,
      ),
    );
  }

  static ButtonStyle _filledStyle(ColorScheme colorScheme, TextTheme textTheme) {
    return ButtonStyle(
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 20),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.12);
        }
        return colorScheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        return colorScheme.onPrimary;
      }),
      textStyle: WidgetStatePropertyAll(textTheme.actionLabel),
      elevation: const WidgetStatePropertyAll(0),
    );
  }

  static ButtonStyle _outlinedStyle(ColorScheme colorScheme, TextTheme textTheme) {
    return ButtonStyle(
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12));
        }
        return BorderSide(color: colorScheme.outlineVariant);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        return colorScheme.onSurface;
      }),
      textStyle: WidgetStatePropertyAll(textTheme.actionLabel),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme colorScheme, TextTheme textTheme) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: color == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: color, width: 1.5),
        );

    return InputDecorationTheme(
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(colorScheme.primary),
      errorBorder: border(colorScheme.error),
      focusedErrorBorder: border(colorScheme.error),
      disabledBorder: border(Colors.transparent),
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      labelStyle: textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
      hintStyle: textTheme.bodySecondary?.copyWith(color: colorScheme.onSurfaceVariant),
      errorStyle: textTheme.meta?.copyWith(color: colorScheme.error),
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    );
  }
}

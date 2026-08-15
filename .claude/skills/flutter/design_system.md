# Skill: Diseño UI — Estilo Google / Gemini para Android

## Filosofía de Diseño

PoliNexu sigue el lenguaje visual de las **aplicaciones modernas de Google para Android**,
específicamente la app de **Gemini**. El objetivo es que cualquier persona que use Google
One, Gemini o Google Photos se sienta inmediatamente en un entorno familiar.

**Principios clave:**
- **Superficie, no fondo**: Los elementos se diferencian por variaciones sutiles de color
  de superficie, no por sombras fuertes ni bordes.
- **Redondez pronunciada**: Bordes redondeados generosos (24–32dp) en todos los controles
  interactivos, inspirados en Material You.
- **Espacio en blanco generoso**: Padding interno amplio en campos y botones. Nunca elementos
  apilados sin respiración.
- **Tipografía limpia**: Fuente `Plus Jakarta Sans` vía `google_fonts` (alternativa OFL más cercana a Google Sans/Product Sans; ver nota de licencia en `CLAUDE.md`).
  Pesos: Regular (400) para cuerpo, Medium (500) para acciones, SemiBold (600) para títulos.
- **Iconografía Material Symbols**: Usa el paquete `material_symbols_icons`
  (`Symbols.xxx_rounded`), **no** `Icons.xxx_outlined` de Material Icons clásico —
  este último tiene terminaciones más angulosas y no coincide con el trazo redondeado
  que usa Google en Gemini/NotebookLM. Por defecto los íconos van sin relleno
  (`fill: 0`, el default). Para un estado activo/seleccionado, usa el **mismo** glifo
  con `fill: 1` (ver `NavigationDestination` en `main_shell.dart`) en vez de cambiar a
  un pictograma distinto — así es como Google marca selección en sus apps.
- **Micro-interacciones**: Todos los botones tienen estados hover/pressed visibles.
  Usa `AnimatedSwitcher` o `AnimatedContainer` para transiciones de estado suaves.

---

## Paleta de Colores

### Modo Claro
| Token | Hex | Uso |
|---|---|---|
| `surface` | `#F8F9FA` | Fondo de scaffolds y pantallas |
| `surfaceContainerHighest` | `#E8EAED` | Relleno de inputs, chips, tarjetas secundarias |
| `primary` | Derivado de `#1E63D1` (Material seed) | Botones, íconos de acción, FAB |
| `primaryContainer` | Azul muy claro | Fondo de botones secundarios, chips activos |
| `onSurfaceVariant` | Gris medio | Labels, placeholders, subtítulos |

### Modo Oscuro
| Token | Hex | Uso |
|---|---|---|
| `surface` | `#131314` | Fondo principal (negro profundo Gemini) |
| `surfaceContainerHighest` | `#282A2C` | Tarjetas, inputs, superficies elevadas |
| `primary` | Derivado de `#A8C7FA` | Íconos y acentos en oscuro |
| `primaryContainer` | Azul oscuro medio | Botones filled en oscuro |

**Siempre** usa tokens del `ColorScheme` (`colorScheme.primary`, `colorScheme.surface`, etc.).
**Nunca** hardcodees valores hexadecimales en widgets.

La rampa de superficies (`surfaceContainerLowest` → `Highest`) está fijada **completa** a
mano en `app_theme.dart`. Si sólo se fijan los extremos, los escalones intermedios los
genera el algoritmo tonal desde la semilla y no casan con los valores elegidos.

### Tokens (no uses números sueltos)

| Archivo | Qué define |
|---|---|
| `app_spacing.dart` | `AppSpacing.{xs..xxl}` — rejilla de 8dp |
| `app_radius.dart` | `AppRadius.{sm 8, md 16, lg 24, xl 28, pill}`, `AppIconSize.{sm 18, md 24, lg 48}` |
| `app_motion.dart` | `AppMotion.{fast, normal, slow, intro}` + curvas M3 enfatizadas |
| `app_text_styles.dart` | `heroTitle`, `sectionTitle`, `cardTitle`, `metric`, `actionLabel`, `body`, `bodySecondary`, `meta` |

Jerarquía tipográfica: pantalla (`heroTitle`) → sección (`sectionTitle`, 22) →
tarjeta (`cardTitle`, 16). Si una sección compite con el título de la pantalla,
está usando el estilo equivocado.

### Antes de escribir un widget nuevo

Revisa `lib/presentation/widgets/`: `StatusView`/`InlineStatus` (error y vacío),
`SectionHeader`, `AppCard`, `AppListRow`, `SkeletonList`, `AppSnack`, `PriorityFlag`.
Ningún `ListTile` crudo (su padding fijo choca con el radio de la tarjeta), ningún
`SnackBar` a mano, ningún `CircularProgressIndicator` suelto dentro de una lista.

---

## Componentes Estándar

### Botón Principal (CTA)
```dart
FilledButton(
  onPressed: onPressed,
  style: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(32), // Completamente redondeado
    ),
  ),
  child: Text('Acción', style: theme.textTheme.titleMedium),
)
```

### Botón Secundario
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    side: BorderSide(color: colorScheme.outline),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  ),
  ...
)
```

### Campo de Texto
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Etiqueta',
    prefixIcon: Icon(Icons.some_icon_outlined, color: colorScheme.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
)
```

### Tarjeta (Card)
```dart
Card(
  elevation: 0,
  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: ...,
  ),
)
```

### AppBar
```dart
AppBar(
  backgroundColor: colorScheme.surface,
  foregroundColor: colorScheme.onSurface,
  elevation: 0,
  scrolledUnderElevation: 0, // Sin línea al hacer scroll
  centerTitle: false, // Google usa título alineado a la izquierda en pantallas interiores
)
```

---

## Pantalla de Login — Referencia

La pantalla de login (ya implementada) sigue este patrón:
1. **Hero visual**: `NexusHero` (`lib/presentation/widgets/nexus_hero.dart`) — tres
   nodos conectados y animados (`CustomPainter`, sin assets externos) que representan
   los tres pilares de la app (SAES, horario, tareas) unidos en un solo lugar. Reemplaza
   cualquier ícono genérico tipo `auto_awesome`; es la identidad visual de PoliNexu,
   reutilízalo en pantallas de carga/onboarding en vez de crear otro símbolo.
2. **Título**: `textTheme.heroTitle` (displaySmall, peso 600, tracking negativo `-0.5`).
3. **Subtítulo**: `titleMedium`, color `onSurfaceVariant`, peso 400.
4. **Espaciado generoso**: `48dp` entre secciones principales.
5. **Botón de submit**: `FilledButton` a ancho completo, `32dp` de radius, `20dp` vertical padding.

---

## Animaciones y Transiciones

- Usa `AnimatedSwitcher` para cambios de estado en UI (cargando → contenido).
- Duración estándar: `300ms` con curva `Curves.easeInOut`.
- Para listas que cargan: **esqueletos** (`SkeletonList`), no un spinner centrado — evitan
  el salto de layout y dicen *qué* está cargando.
- Nunca bloquees la UI con un overlay opaco — usa estados deshabilitados en los controles.
- Las transiciones entre pantallas ya vienen del theme (`pageTransitionsTheme`) y del
  `pageBuilder` de cada ruta del shell; no las montes a mano por pantalla. Envolver el
  `child` de un `ShellRoute` en un `AnimatedSwitcher` **rompe** con "Duplicate GlobalKey".

---

## Tipografía — Escala de Referencia

| Estilo | Uso típico | Peso |
|---|---|---|
| `displaySmall` | Títulos de pantalla principal | 600 (SemiBold) |
| `headlineMedium` | Títulos de sección | 500 (Medium) |
| `titleLarge` | Títulos de tarjetas | 500 (Medium) |
| `titleMedium` | Labels de botones, subtítulos | 500 (Medium) |
| `bodyLarge` | Cuerpo de texto principal | 400 (Regular) |
| `bodyMedium` | Texto secundario, descripciones | 400 (Regular) |
| `labelMedium` | Chips, badges, meta-info | 500 (Medium) |

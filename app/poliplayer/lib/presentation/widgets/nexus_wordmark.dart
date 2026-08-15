import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// El nombre de la app tratado como marca: "Poli" en el color de texto y
/// "Nexu" en el color de acento, con el tracking negativo de [heroTitle].
///
/// Siempre por este widget y no como un `Text('PoliNexu')` suelto, para que el
/// nombre se vea igual en splash, onboarding y login.
class NexusWordmark extends StatelessWidget {
  final double? fontSize;
  final TextAlign textAlign;

  const NexusWordmark({super.key, this.fontSize, this.textAlign = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final base = theme.textTheme.heroTitle?.copyWith(
      color: colorScheme.onSurface,
      fontSize: fontSize,
    );

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Poli'),
          TextSpan(text: 'Nexu', style: TextStyle(color: colorScheme.primary)),
        ],
      ),
      textAlign: textAlign,
      style: base,
    );
  }
}

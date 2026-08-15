import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Aviso de "esto es lo último que pudimos bajar del SAES".
///
/// Se muestra cuando la pantalla está pintando datos de la caché local porque
/// la sesión murió o no hay red, para que no parezcan datos de ahora mismo.
/// Va en `tertiaryContainer` y no en una superficie neutra: es una advertencia
/// y tiene que leerse como tal sin llegar a ser un error.
class StaleDataBanner extends StatelessWidget {
  final DateTime fetchedAt;

  const StaleDataBanner({super.key, required this.fetchedAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(
            Symbols.cloud_off_rounded,
            size: AppIconSize.sm,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Sin conexión con el SAES · datos del ${_label(fetchedAt)}',
              style: theme.textTheme.meta?.copyWith(color: colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  /// "hoy a las 14:05" pesa menos que una fecha completa cuando el dato es
  /// reciente, que es el caso habitual.
  String _label(DateTime when) {
    final now = DateTime.now();
    final sameDay = when.year == now.year && when.month == now.month && when.day == now.day;
    if (sameDay) return 'hoy a las ${DateFormat('HH:mm').format(when)}';
    return DateFormat("d 'de' MMMM, HH:mm", 'es_MX').format(when);
  }
}

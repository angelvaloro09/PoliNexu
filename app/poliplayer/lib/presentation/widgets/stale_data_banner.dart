import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_motion.dart';
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

  /// `true` cuando específicamente la sesión del SAES expiró (no sólo falta
  /// de red) — cambia el mensaje/ícono y ofrece un botón de login directo en
  /// vez de sólo advertir que el dato es viejo.
  final bool sessionExpired;
  final VoidCallback? onLoginTap;

  const StaleDataBanner({
    super.key,
    required this.fetchedAt,
    this.sessionExpired = false,
    this.onLoginTap,
  });

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
            sessionExpired ? Symbols.lock_clock_rounded : Symbols.cloud_off_rounded,
            size: AppIconSize.sm,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              sessionExpired
                  ? 'Sesión expirada · datos del ${_label(fetchedAt)}'
                  : 'Sin conexión con el SAES · datos del ${_label(fetchedAt)}',
              style: theme.textTheme.meta?.copyWith(color: colorScheme.onTertiaryContainer),
            ),
          ),
          if (sessionExpired && onLoginTap != null)
            TextButton(
              onPressed: onLoginTap,
              child: const Text('Iniciar sesión'),
            ),
        ],
      ),
    )
        // El banner sólo se monta cuando `fromCache` es true (los call-sites
        // lo incluyen condicionalmente en la lista) — animar su entrada aquí
        // adentro basta para que aparezca creciendo en vez de hacer pop,
        // sin tocar los 5 lugares donde se usa.
        .animate()
        .fadeIn(duration: AppMotion.normal, curve: AppMotion.emphasized)
        .scaleXY(begin: 0.96, end: 1, duration: AppMotion.normal, curve: AppMotion.emphasized);
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

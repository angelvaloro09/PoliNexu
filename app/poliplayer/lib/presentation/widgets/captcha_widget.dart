import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Imagen del CAPTCHA con botón de recarga.
///
/// La imagen del SAES es de 100×50, así que el contenedor mantiene esa
/// proporción y ocupa el ancho que le den. Antes tenía `width: 200` fijo
/// dentro de un `Expanded`, y en pantallas angostas la imagen se aplastaba.
class CaptchaWidget extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool isLoading;
  final VoidCallback onReload;

  const CaptchaWidget({
    super.key,
    required this.imageBytes,
    required this.isLoading,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 2, // 100×50, la imagen que sirve BotDetect
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: AppRadius.mdAll,
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedSwitcher(
              duration: AppMotion.normal,
              switchInCurve: AppMotion.emphasized,
              child: _buildContent(context, colorScheme),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Fuera de la imagen: como botón superpuesto tapaba los caracteres
        // justo donde hay que leerlos.
        TextButton.icon(
          onPressed: isLoading ? null : onReload,
          icon: const Icon(Symbols.refresh_rounded, size: AppIconSize.sm),
          label: const Text('Otro código'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    if (isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
      );
    }

    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        key: const ValueKey('image'),
        fit: BoxFit.contain,
        // El CAPTCHA es un mapa de bits pequeño que se escala hacia arriba;
        // sin esto el filtrado lo deja borroso y más difícil de leer.
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => Center(
          key: const ValueKey('broken'),
          child: Icon(Symbols.broken_image_rounded, color: colorScheme.error),
        ),
      );
    }

    return Center(
      key: const ValueKey('empty'),
      child: Text(
        'No se pudo cargar',
        style: Theme.of(context)
            .textTheme
            .meta
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

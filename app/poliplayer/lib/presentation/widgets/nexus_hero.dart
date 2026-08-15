import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'nexus_mark.dart';

/// La marca de PoliNexu, animada: pulsos que viajan por las aristas y nodos
/// que "respiran" desfasados entre sí — sugiere flujo de datos entre los tres
/// pilares.
///
/// La geometría vive en [NexusGeometry] y la comparte con [NexusMark]
/// (estático); aquí sólo se añade el movimiento. Nativo, sin assets: los
/// colores salen del `ColorScheme`, así que funciona en claro y oscuro sin
/// tocar nada.
class NexusHero extends StatefulWidget {
  final double size;

  /// Progreso del trazado de las aristas (0..1). Con `null` las aristas están
  /// completas desde el inicio; el splash lo usa para dibujarlas al entrar.
  final double? edgeProgress;

  const NexusHero({super.key, this.size = 140, this.edgeProgress});

  @override
  State<NexusHero> createState() => _NexusHeroState();
}

class _NexusHeroState extends State<NexusHero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradient = AppTheme.brandGradient(colorScheme.brightness);

    // `TickerMode` está en false cuando la ruta no es visible (p. ej. detrás de
    // otra pantalla), así que el controller se detiene solo y no gasta frames
    // pintando algo que nadie ve.
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _NexusHeroPainter(
              progress: _controller.value,
              edgeProgress: widget.edgeProgress ?? 1,
              primary: gradient.first,
              accent: gradient.last,
              core: colorScheme.surface,
            ),
          );
        },
      ),
    );
  }
}

class _NexusHeroPainter extends CustomPainter {
  final double progress; // 0..1, en loop
  final double edgeProgress; // 0..1, trazado de las aristas
  final Color primary;
  final Color accent;
  final Color core;

  _NexusHeroPainter({
    required this.progress,
    required this.edgeProgress,
    required this.primary,
    required this.accent,
    required this.core,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Aristas y nodos base: exactamente la misma marca estática.
    NexusMarkPainter(
      color: primary,
      accentColor: accent,
      coreColor: core,
      edgeProgress: edgeProgress,
    ).paint(canvas, size);

    // Hasta que las aristas no estén trazadas, no hay por dónde pulsar.
    if (edgeProgress < 1) return;

    final nodes = NexusGeometry.nodes(size);
    final nodeRadius = NexusGeometry.nodeRadius(size.shortestSide);
    final pulseRadius = math.max(2.0, size.shortestSide * 0.022);

    for (var i = 0; i < nodes.length; i++) {
      final j = (i + 1) % nodes.length;
      final t = (progress + i / nodes.length) % 1.0;
      final position = Offset.lerp(nodes[i], nodes[j], t)!;

      // Estela: se desvanece hacia atrás del pulso.
      final tail = (t - 0.06).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset.lerp(nodes[i], nodes[j], tail)!,
        position,
        Paint()
          ..color = accent.withValues(alpha: 0.45)
          ..strokeWidth = pulseRadius
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(position, pulseRadius, Paint()..color = accent);
    }

    // Respiración de los nodos, desfasada para que nunca latan al unísono.
    for (var i = 0; i < nodes.length; i++) {
      final phase = (progress + i / nodes.length) % 1.0;
      final breathe = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);

      canvas.drawCircle(
        nodes[i],
        nodeRadius * (1.6 + breathe * 0.8),
        Paint()
          ..color = primary.withValues(alpha: 0.10 + breathe * 0.12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.shortestSide * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NexusHeroPainter old) =>
      old.progress != progress ||
      old.edgeProgress != edgeProgress ||
      old.primary != primary ||
      old.accent != accent ||
      old.core != core;
}

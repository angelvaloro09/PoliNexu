import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/nexus_mark.dart';

/// Ilustraciones del onboarding, una por pilar de la app.
///
/// Dibujadas con `CustomPainter` y no como imágenes: sin assets que pesen ni
/// que haya que duplicar para modo claro y oscuro — los colores salen del
/// `ColorScheme` activo. Todas reutilizan la retícula de nodos de
/// [NexusGeometry] para que se lean como familia de la marca.
class OnboardingArt extends StatelessWidget {
  final int page;
  final double size;

  /// 0..1 — progreso de entrada; anima el dibujo cuando se llega a la página.
  final double progress;

  const OnboardingArt({
    super.key,
    required this.page,
    this.size = 220,
    this.progress = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradient = AppTheme.brandGradient(colorScheme.brightness);

    final painter = switch (page) {
      0 => _ConnectPainter(
          primary: gradient.first,
          accent: gradient.last,
          surface: colorScheme.surface,
          muted: colorScheme.outlineVariant,
          progress: progress,
        ),
      1 => _SchedulePainter(
          primary: gradient.first,
          accent: gradient.last,
          muted: colorScheme.surfaceContainerHigh,
          progress: progress,
        ),
      _ => _TasksPainter(
          primary: gradient.first,
          accent: gradient.last,
          muted: colorScheme.surfaceContainerHigh,
          progress: progress,
        ),
    };

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

/// Pilar 1 — el SAES: tres fuentes de datos (calificaciones, horario, kárdex)
/// convergiendo en un solo punto.
class _ConnectPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final Color surface;
  final Color muted;
  final double progress;

  _ConnectPainter({
    required this.primary,
    required this.accent,
    required this.surface,
    required this.muted,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;
    final nodes = List.generate(3, (i) {
      final angle = -math.pi / 2 + i * (2 * math.pi / 3);
      return center + Offset(math.cos(angle), math.sin(angle)) * radius;
    });

    // Órbita de fondo: da profundidad sin competir con los nodos.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = muted.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Cada fuente se conecta al centro; el trazo crece con el progreso.
    for (final node in nodes) {
      canvas.drawLine(
        node,
        Offset.lerp(node, center, progress)!,
        Paint()
          ..color = accent.withValues(alpha: 0.55)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(node, 14, Paint()..color = primary);
      canvas.drawCircle(node, 5, Paint()..color = surface);
    }

    // El núcleo: la app misma, donde todo llega junto.
    canvas.drawCircle(
      center,
      18 * progress,
      Paint()
        ..color = primary.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, 12 * progress, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _ConnectPainter old) => old.progress != progress;
}

/// Pilar 2 — horario y clases: una retícula semanal con el bloque de "ahora"
/// destacado.
class _SchedulePainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final Color muted;
  final double progress;

  _SchedulePainter({
    required this.primary,
    required this.accent,
    required this.muted,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const columns = 4;
    const rows = 4;
    final gap = size.width * 0.045;
    final cellWidth = (size.width - gap * (columns - 1)) / columns;
    final cellHeight = (size.height - gap * (rows - 1)) / rows;

    // Bloques "ocupados": un horario tiene huecos, no es una malla completa.
    const filled = {(0, 1), (1, 0), (1, 2), (2, 1), (3, 2), (2, 3)};
    const highlighted = (1, 2);

    for (var col = 0; col < columns; col++) {
      for (var row = 0; row < rows; row++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            col * (cellWidth + gap),
            row * (cellHeight + gap),
            cellWidth,
            cellHeight,
          ),
          const Radius.circular(10),
        );

        final isFilled = filled.contains((col, row));
        final isHighlight = (col, row) == highlighted;

        // Los bloques ocupados aparecen escalonados de izquierda a derecha.
        final appear = ((progress * 2) - col / columns).clamp(0.0, 1.0);

        canvas.drawRRect(
          rect,
          Paint()
            ..color = isHighlight
                ? accent.withValues(alpha: appear)
                : isFilled
                    ? primary.withValues(alpha: 0.75 * appear)
                    : muted.withValues(alpha: 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SchedulePainter old) => old.progress != progress;
}

/// Pilar 3 — tareas: una lista donde las primeras ya están marcadas.
class _TasksPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final Color muted;
  final double progress;

  _TasksPainter({
    required this.primary,
    required this.accent,
    required this.muted,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 4;
    final rowHeight = size.height / (rows + 1);
    final boxSize = rowHeight * 0.52;

    for (var i = 0; i < rows; i++) {
      final top = rowHeight * (i + 0.5);
      final appear = ((progress * 2) - i * 0.25).clamp(0.0, 1.0);
      final done = i < 2;

      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, boxSize, boxSize),
        const Radius.circular(7),
      );

      if (done) {
        canvas.drawRRect(box, Paint()..color = primary.withValues(alpha: appear));
        // Palomita, trazada con el progreso.
        final path = Path()
          ..moveTo(boxSize * 0.26, top + boxSize * 0.52)
          ..lineTo(boxSize * 0.44, top + boxSize * 0.70)
          ..lineTo(boxSize * 0.76, top + boxSize * 0.30);
        canvas.drawPath(
          _partial(path, appear),
          Paint()
            ..color = Colors.white.withValues(alpha: appear)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawRRect(
          box,
          Paint()
            ..color = (i == 2 ? accent : muted).withValues(alpha: appear)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }

      // Línea de texto de la tarea; la última, más corta.
      final lineWidth = (size.width - boxSize * 1.8) * (i == rows - 1 ? 0.6 : 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            boxSize * 1.8,
            top + boxSize * 0.3,
            lineWidth * appear,
            boxSize * 0.4,
          ),
          const Radius.circular(999),
        ),
        Paint()..color = muted.withValues(alpha: done ? 0.5 : 0.9),
      );
    }
  }

  Path _partial(Path path, double t) {
    if (t >= 1) return path;
    final result = Path();
    for (final metric in path.computeMetrics()) {
      result.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _TasksPainter old) => old.progress != progress;
}

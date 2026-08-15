import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Geometría de la marca de PoliNexu: tres nodos en triángulo unidos por un
/// trazo cerrado — los tres pilares de la app (SAES, horario, tareas) en un
/// solo lugar, el "nexus" del nombre.
///
/// Es la **única** fuente de la identidad. `NexusMark` la pinta estática (para
/// AppBars, onboarding y la exportación del ícono de launcher) y `NexusHero`
/// la anima. Antes las aristas eran tres líneas sueltas; ahora es un trazo
/// cerrado con uniones redondeadas, así que se lee como un glifo y no como un
/// diagrama.
class NexusGeometry {
  NexusGeometry._();

  /// Proporción del lado menor que ocupa el radio del triángulo.
  static const double radiusFactor = 0.72;

  /// Centros de los tres nodos, vértice apuntando hacia arriba.
  ///
  /// Un triángulo con el vértice arriba ocupa de `-r` a `+r/2` en vertical, así
  /// que centrarlo en el centroide lo deja visualmente alto: se compensa
  /// bajándolo un cuarto de radio para centrar la caja que realmente ocupa.
  static List<Offset> nodes(Size size) {
    final radius = size.shortestSide / 2 * radiusFactor;
    final center = size.center(Offset(0, radius * 0.25));
    return List.generate(3, (i) {
      final angle = -math.pi / 2 + i * (2 * math.pi / 3);
      return center + Offset(math.cos(angle), math.sin(angle)) * radius;
    });
  }

  /// Trazo cerrado que une los tres nodos.
  static Path edgePath(List<Offset> nodes) {
    return Path()
      ..moveTo(nodes[0].dx, nodes[0].dy)
      ..lineTo(nodes[1].dx, nodes[1].dy)
      ..lineTo(nodes[2].dx, nodes[2].dy)
      ..close();
  }

  /// Todo escala con el tamaño: la marca se ve igual a 24dp que a 140dp.
  static double edgeWidth(double size) => math.max(1.5, size * 0.028);

  /// Opacidad del trazo. Las aristas son soporte del glifo, no protagonistas,
  /// pero por debajo de esto desaparecen a tamaños de ícono.
  static const double edgeAlpha = 0.45;
  static double nodeRadius(double size) => math.max(2.5, size * 0.075);
}

/// La marca, sin animación.
class NexusMark extends StatelessWidget {
  final double size;

  /// Color del trazo y los nodos. Por defecto `colorScheme.primary`.
  final Color? color;

  /// Segundo color del degradado. Por defecto, el segundo tono de marca.
  final Color? accentColor;

  /// Color del núcleo hueco de cada nodo. Por defecto el fondo del scaffold,
  /// para que el hueco se vea recortado y no como un punto de otro color.
  final Color? coreColor;

  /// Nodos macizos, sin núcleo hueco. Es la variante para el ícono de
  /// launcher, donde el hueco se pierde a tamaños pequeños.
  final bool solid;

  const NexusMark({
    super.key,
    this.size = 96,
    this.color,
    this.accentColor,
    this.coreColor,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradient = AppTheme.brandGradient(colorScheme.brightness);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: NexusMarkPainter(
          color: color ?? gradient.first,
          accentColor: accentColor ?? gradient.last,
          coreColor: coreColor ?? colorScheme.surface,
          solid: solid,
        ),
      ),
    );
  }
}

class NexusMarkPainter extends CustomPainter {
  final Color color;

  /// Segundo color del degradado. Con `null` la marca es de un solo tono.
  final Color? accentColor;

  final Color coreColor;
  final bool solid;

  /// 0..1 — cuánto del trazo se ha dibujado. Permite la animación de "trazado"
  /// del splash reutilizando este mismo pintor.
  final double edgeProgress;

  NexusMarkPainter({
    required this.color,
    this.accentColor,
    required this.coreColor,
    this.solid = false,
    this.edgeProgress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = NexusGeometry.nodes(size);
    final edgeWidth = NexusGeometry.edgeWidth(size.shortestSide);
    final nodeRadius = NexusGeometry.nodeRadius(size.shortestSide);

    final rect = Offset.zero & size;
    final accent = accentColor ?? color;

    // Un degradado en diagonal sobre toda la marca: los tres nodos no son
    // idénticos entre sí y el glifo deja de leerse plano.
    Shader shader(double alpha) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: alpha),
            accent.withValues(alpha: alpha),
          ],
        ).createShader(rect);

    final edgePaint = Paint()
      ..shader = shader(NexusGeometry.edgeAlpha)
      ..strokeWidth = edgeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(_edges(size, nodes), edgePaint);

    final nodePaint = Paint()..shader = shader(1);
    for (final node in nodes) {
      canvas.drawCircle(node, nodeRadius, nodePaint);
      if (!solid) {
        canvas.drawCircle(node, nodeRadius * 0.38, Paint()..color = coreColor);
      }
    }
  }

  Path _edges(Size size, List<Offset> nodes) {
    final full = NexusGeometry.edgePath(nodes);
    if (edgeProgress >= 1) return full;

    // Recorta el trazo a un porcentaje de su longitud total para animar el
    // dibujado. Se recorre el contorno completo como una sola curva.
    final path = Path();
    for (final metric in full.computeMetrics()) {
      path.addPath(metric.extractPath(0, metric.length * edgeProgress), Offset.zero);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant NexusMarkPainter old) =>
      old.color != color ||
      old.accentColor != accentColor ||
      old.coreColor != coreColor ||
      old.solid != solid ||
      old.edgeProgress != edgeProgress;
}

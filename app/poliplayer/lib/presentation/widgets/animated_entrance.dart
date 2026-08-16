import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_motion.dart';

/// Un wrapper que anima la entrada de un elemento con un Fade y Slide.
/// Si se provee un [index], la animación tendrá un retraso calculado para
/// lograr un efecto de entrada escalonada (staggered).
///
/// Implementado sobre `flutter_animate` — consume los mismos tokens de
/// `AppMotion` que antes usaba el `AnimationController` a mano, la API
/// externa no cambió (mismos parámetros, mismo comportamiento) para no
/// tocar los call-sites existentes.
class AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration? duration;
  final Duration? delay;
  final Offset beginOffset;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.normal,
    this.delay,
    this.beginOffset = const Offset(0.0, 0.2), // Entra ligeramente desde abajo
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = duration ?? AppMotion.normal;
    final effectiveDelay = delay ?? AppMotion.staggerStep * index;

    return child
        .animate(delay: effectiveDelay)
        .fadeIn(duration: effectiveDuration, curve: AppMotion.emphasized)
        .slide(
          begin: beginOffset,
          end: Offset.zero,
          duration: effectiveDuration,
          curve: AppMotion.emphasized,
        );
  }
}

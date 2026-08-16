import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// Un wrapper que anima la entrada de un elemento con un Fade y Slide.
/// Si se provee un [index], la animación tendrá un retraso calculado para
/// lograr un efecto de entrada escalonada (staggered).
class AnimatedEntrance extends StatefulWidget {
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
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.emphasized,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(curve);

    // Calculamos el delay escalonado
    final effectiveDelay = widget.delay ??
        Duration(
          milliseconds: (widget.index * AppMotion.staggerStep.inMilliseconds),
        );

    if (effectiveDelay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(effectiveDelay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

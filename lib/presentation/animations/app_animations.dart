import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StaggeredEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: (index * 70).ms)
        .fadeIn(duration: duration)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

class PressAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const PressAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<PressAnimation> createState() => _PressAnimationState();
}

class _PressAnimationState extends State<PressAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 100),
      value: 1,
    );
    _scale = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() => _controller.reverse();
  void _release() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _press(),
      onTapUp: widget.onTap == null ? null : (_) => _release(),
      onTapCancel: widget.onTap == null ? null : _release,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Material(
            type: MaterialType.transparency,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class AnimatedCount extends StatelessWidget {
  final int count;

  const AnimatedCount({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Text(
        '$count',
        key: ValueKey(count),
      ),
    );
  }
}

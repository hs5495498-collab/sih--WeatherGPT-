import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps any widget with a satisfying scale-down-on-press, scale-back-on-release
/// interaction plus haptic feedback. Used on buttons, chips, nav items, and cards
/// throughout the app so every tap feels acknowledged, not just functional.
class Bouncy extends StatefulWidget {
  const Bouncy({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.92,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool haptic;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 1.0,
  );
  late final Animation<double> _scale =
      Tween(begin: 1.0, end: widget.scaleDown).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _controller.reverse();
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
      onTapCancel: widget.onTap == null ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

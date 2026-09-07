import 'package:flutter/material.dart';

/// Animates a number counting up from 0 (or from its previous value) to
/// [value] whenever it changes. Makes the dashboard's temperature and stats
/// feel like they're "arriving" rather than just appearing.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text('${animatedValue.round()}$suffix', style: style);
      },
    );
  }
}

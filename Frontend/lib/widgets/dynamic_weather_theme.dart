import 'package:flutter/material.dart';
import '../theme/weather_theme_spec.dart';

/// Smoothly cross-fades EVERY color in a WeatherThemeSpec at once — background
/// gradient, text colors, card colors, accent — whenever the spec changes.
/// This is what makes "ask about a cyclone, watch the screen turn stormy"
/// feel like one cohesive mood shift instead of several components
/// independently snapping to new colors at different times.
class DynamicWeatherTheme extends ImplicitlyAnimatedWidget {
  const DynamicWeatherTheme({
    super.key,
    required this.spec,
    required this.builder,
    Duration duration = const Duration(milliseconds: 900),
  }) : super(duration: duration, curve: Curves.easeInOutCubic);

  final WeatherThemeSpec spec;
  final Widget Function(BuildContext context, WeatherThemeSpec animatedSpec) builder;

  @override
  AnimatedWidgetBaseState<DynamicWeatherTheme> createState() => _DynamicWeatherThemeState();
}

class _DynamicWeatherThemeState extends AnimatedWidgetBaseState<DynamicWeatherTheme> {
  _WeatherThemeSpecTween? _specTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _specTween = visitor(
      _specTween,
      widget.spec,
      (value) => _WeatherThemeSpecTween(begin: value as WeatherThemeSpec),
    ) as _WeatherThemeSpecTween;
  }

  @override
  Widget build(BuildContext context) {
    final animatedSpec = _specTween?.evaluate(animation) ?? widget.spec;
    return widget.builder(context, animatedSpec);
  }
}

class _WeatherThemeSpecTween extends Tween<WeatherThemeSpec> {
  _WeatherThemeSpecTween({super.begin, super.end});

  @override
  WeatherThemeSpec lerp(double t) => WeatherThemeSpec.lerp(begin!, end ?? begin!, t);
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Maps a condition string to an icon + a tasteful looping animation —
/// sun rotates slowly, rain drop bobs, storm bolt flickers, cloud drifts.
class AnimatedWeatherIcon extends StatelessWidget {
  const AnimatedWeatherIcon({
    super.key,
    required this.condition,
    this.size = 56,
    this.color,
  });

  final String condition;
  final double size;
  final Color? color;

  IconData get _icon {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'rainy':
      case 'rain':
        return Icons.water_drop_rounded;
      case 'cloudy':
      case 'clouds':
        return Icons.cloud_rounded;
      case 'storm':
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'hazy':
      case 'fogsmog':
      case 'fog':
        return Icons.foggy;
      case 'dusty':
      case 'sandstorm':
        return Icons.air_rounded;
      case 'windy':
        return Icons.air_rounded;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(_icon, size: size, color: color ?? Colors.white);

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return icon
            .animate(onPlay: (c) => c.repeat())
            .rotate(duration: 8.seconds, curve: Curves.linear);
      case 'rainy':
      case 'rain':
        return icon
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -3, end: 3, duration: 900.ms, curve: Curves.easeInOut);
      case 'storm':
      case 'thunderstorm':
        return icon
            .animate(onPlay: (c) => c.repeat())
            .then(delay: 1200.ms)
            .fade(begin: 1, end: 0.3, duration: 120.ms)
            .then()
            .fade(begin: 0.3, end: 1, duration: 120.ms);
      case 'cloudy':
      case 'clouds':
        return icon
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: -3, end: 3, duration: 2.seconds, curve: Curves.easeInOut);
      case 'hazy':
      case 'fogsmog':
      case 'fog':
        return icon
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 1, end: 0.55, duration: 1600.ms, curve: Curves.easeInOut);
      case 'dusty':
      case 'sandstorm':
      case 'windy':
        return icon
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: -5, end: 5, duration: 500.ms, curve: Curves.easeInOut);
      default:
        return icon;
    }
  }
}

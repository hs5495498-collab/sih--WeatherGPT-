import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/weather_alert.dart';
import '../theme/app_theme.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.alert});

  final WeatherAlert alert;

  Color get _color {
    switch (alert.severity) {
      case AlertSeverity.severe:
      case AlertSeverity.high:
        return AppColors.alertRed;
      case AlertSeverity.medium:
        return AppColors.alertAmber;
      case AlertSeverity.low:
        return AppColors.alertGreen;
    }
  }

  String get _label {
    switch (alert.severity) {
      case AlertSeverity.severe:
        return 'SEVERE';
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.medium:
        return 'MODERATE';
      case AlertSeverity.low:
        return 'ADVISORY';
    }
  }

  bool get _isCritical =>
      alert.severity == AlertSeverity.severe || alert.severity == AlertSeverity.high;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _label,
                      style: TextStyle(
                        color: _color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alert.region,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!_isCritical) return card.animate().fadeIn().slideY(begin: 0.1, end: 0);

    // Severe/high alerts get a subtle attention-pulse. This is two
    // SEPARATE animate() calls on purpose: the first plays the entry
    // fade exactly once, then the second (with its own repeating
    // controller) handles the continuous scale pulse. Chaining the pulse
    // inside the same repeating timeline as the fade would replay the
    // fade-in/out every loop instead of just pulsing — that was a real
    // bug in the previous version.
    return card
        .animate()
        .fadeIn(duration: 300.ms)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .custom(
          duration: 1200.ms,
          builder: (context, value, child) => Transform.scale(
            scale: 1 + (value * 0.015),
            child: child,
          ),
        );
  }
}

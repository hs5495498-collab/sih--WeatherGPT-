import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;
import '../theme/app_theme.dart';

/// The app's actual brand mark — a restrained, geometric weather glyph
/// (a compass-ring with a stylized barometric arc through it), rendered
/// via CustomPainter. Deliberately abstract rather than a character: this
/// is what appears in the AppBar, splash screen, and About header — the
/// mascot (weather_mascot.dart) still exists for onboarding warmth, but
/// this is the mark that represents the product itself.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.color, this.accentColor});

  final double size;
  final Color? color;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AppLogoPainter(
        color: color ?? Colors.white,
        accent: accentColor ?? AppColors.gold,
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  _AppLogoPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring — a thin compass/instrument circle, the "precision" cue.
    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045,
    );

    // Four short tick marks at N/E/S/W — instrument/compass detail.
    for (int i = 0; i < 4; i++) {
      final angle = i * (pi / 2);
      final outer = center + Offset(cos(angle), sin(angle)) * radius * 0.92;
      final inner = center + Offset(cos(angle), sin(angle)) * radius * 0.72;
      canvas.drawLine(
        outer,
        inner,
        Paint()
          ..color = color.withOpacity(0.6)
          ..strokeWidth = size.width * 0.035
          ..strokeCap = StrokeCap.round,
      );
    }

    // A single sweeping arc through the center — the "barometric trace" /
    // signal line, and the one place the accent color appears.
    final arcRect = Rect.fromCenter(center: center, width: radius * 1.05, height: radius * 1.05);
    canvas.drawArc(
      arcRect,
      -2.3,
      2.6,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09
        ..strokeCap = StrokeCap.round,
    );

    // Center dot — the "current point" the arc reads from.
    canvas.drawCircle(center, size.width * 0.05, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}

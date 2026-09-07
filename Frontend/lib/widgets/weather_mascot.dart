import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' show pi;
import '../theme/app_theme.dart';

/// An original, simple friendly cloud character — hand-drawn via
/// CustomPainter, not any existing IP. This is what makes the splash
/// screen, onboarding, empty states, and typing indicator feel like a
/// product with a personality, not a form.
class WeatherMascot extends StatelessWidget {
  const WeatherMascot({
    super.key,
    this.size = 90,
    this.expression = MascotExpression.happy,
    this.bob = true,
  });

  final double size;
  final MascotExpression expression;
  final bool bob;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      size: Size(size, size),
      painter: _MascotPainter(expression: expression),
    );

    if (!bob) return painted;

    return painted
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -4, end: 4, duration: 1800.ms, curve: Curves.easeInOut);
  }
}

enum MascotExpression { happy, thinking, sleepy, alert }

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.expression});

  final MascotExpression expression;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bodyPaint = Paint()..color = Colors.white;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.06);

    // Soft drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.92), width: w * 0.55, height: h * 0.08),
      shadowPaint,
    );

    // Cloud body — three overlapping rounded lobes
    final bodyPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.32, h * 0.55), width: w * 0.42, height: h * 0.4))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.62, h * 0.48), width: w * 0.5, height: h * 0.46))
      ..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.65), width: w * 0.66, height: h * 0.34));
    canvas.drawPath(bodyPath, bodyPaint);

    // Cheeks
    final cheekPaint = Paint()..color = AppColors.sunsetOrange.withOpacity(0.35);
    canvas.drawCircle(Offset(w * 0.32, h * 0.6), w * 0.045, cheekPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.58), w * 0.045, cheekPaint);

    final eyePaint = Paint()..color = AppColors.textPrimary;
    final eyeCenterY = h * 0.5;

    switch (expression) {
      case MascotExpression.happy:
        _eye(canvas, Offset(w * 0.4, eyeCenterY), w * 0.035, eyePaint);
        _eye(canvas, Offset(w * 0.62, eyeCenterY), w * 0.035, eyePaint);
        _smile(canvas, Offset(w * 0.51, h * 0.6), w * 0.09, eyePaint);
        break;
      case MascotExpression.thinking:
        _eye(canvas, Offset(w * 0.4, eyeCenterY), w * 0.03, eyePaint);
        _eye(canvas, Offset(w * 0.62, eyeCenterY - h * 0.02), w * 0.03, eyePaint);
        canvas.drawLine(
          Offset(w * 0.46, h * 0.62),
          Offset(w * 0.58, h * 0.62),
          Paint()
            ..color = eyePaint.color
            ..strokeWidth = w * 0.02
            ..strokeCap = StrokeCap.round,
        );
        break;
      case MascotExpression.sleepy:
        _lash(canvas, Offset(w * 0.4, eyeCenterY), w * 0.03, eyePaint);
        _lash(canvas, Offset(w * 0.62, eyeCenterY), w * 0.03, eyePaint);
        break;
      case MascotExpression.alert:
        _eye(canvas, Offset(w * 0.4, eyeCenterY), w * 0.045, eyePaint);
        _eye(canvas, Offset(w * 0.62, eyeCenterY), w * 0.045, eyePaint);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.51, h * 0.63), width: w * 0.06, height: h * 0.05),
          eyePaint,
        );
        break;
    }
  }

  void _eye(Canvas canvas, Offset center, double r, Paint paint) => canvas.drawCircle(center, r, paint);

  void _lash(Canvas canvas, Offset center, double r, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - r, center.dy),
      Offset(center.dx + r, center.dy),
      paint
        ..strokeWidth = r * 0.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _smile(Canvas canvas, Offset center, double r, Paint paint) {
    final rect = Rect.fromCenter(center: center, width: r * 2, height: r * 1.4);
    canvas.drawArc(rect, 0.2, pi - 0.4, false, Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => oldDelegate.expression != expression;
}

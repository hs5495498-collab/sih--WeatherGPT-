import 'dart:math';
import 'package:flutter/material.dart';

/// A living, condition-aware particle field behind the UI — actual falling
/// rain streaks, drifting snow, rotating sun rays, or drifting cloud shapes,
/// painted every frame via CustomPainter rather than a static gradient.
/// This is the single biggest lever for making the app feel "alive" instead
/// of just skinned.
class WeatherParticleField extends StatefulWidget {
  const WeatherParticleField({super.key, required this.condition, this.opacity = 1.0, this.tint});

  final String condition;
  final double opacity;
  final Color? tint;

  @override
  State<WeatherParticleField> createState() => _WeatherParticleFieldState();
}

class _WeatherParticleFieldState extends State<WeatherParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rand = Random(7);
  List<_Particle> _particles = [];
  String _lastCondition = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
  }

  void _ensureParticles(String condition, Size size) {
    if (condition == _lastCondition && _particles.isNotEmpty) return;
    _lastCondition = condition;

    final count = switch (condition) {
      'rainy' => 70,
      'storm' => 90,
      'snow' => 60,
      'hazy' => 26,
      'dusty' => 55,
      'windy' => 40,
      'sunny' || 'clear' => 10,
      _ => 18, // cloudy / default — a few drifting cloud puffs
    };

    _particles = List.generate(count, (i) {
      return _Particle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: 2 + _rand.nextDouble() * (condition == 'snow' ? 4 : 2),
        speed: 0.3 + _rand.nextDouble() * 0.7,
        drift: (_rand.nextDouble() - 0.5) * 0.3,
        phase: _rand.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureParticles(widget.condition, constraints.biggest);
        return IgnorePointer(
          child: Opacity(
            opacity: widget.opacity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: constraints.biggest,
                painter: _ParticlePainter(
                  particles: _particles,
                  condition: widget.condition,
                  t: _controller.value,
                  tint: widget.tint ?? Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
  });

  final double x, y, size, speed, drift, phase;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.condition, required this.t, required this.tint});

  final List<_Particle> particles;
  final String condition;
  final double t;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    switch (condition) {
      case 'rainy':
        _paintRain(canvas, size, streakLength: 14, color: Colors.white.withOpacity(0.55));
        break;
      case 'storm':
        _paintRain(canvas, size, streakLength: 20, color: Colors.white.withOpacity(0.4));
        _paintLightningFlash(canvas, size);
        break;
      case 'snow':
        _paintSnow(canvas, size);
        break;
      case 'sunny':
      case 'clear':
        _paintSunRays(canvas, size);
        break;
      case 'hazy':
        _paintHaze(canvas, size);
        break;
      case 'dusty':
        _paintDust(canvas, size);
        break;
      case 'windy':
        _paintWindLines(canvas, size);
        break;
      default:
        _paintDriftingClouds(canvas, size);
    }
  }

  void _paintHaze(Canvas canvas, Size size) {
    // Soft, slow-drifting horizontal fog bands — low contrast, unhurried,
    // matching how haze actually reads visually (thick, diffuse, still).
    final paint = Paint()..color = tint.withOpacity(0.16);
    for (final p in particles) {
      final dx = ((p.x + t * p.speed * 0.03) % 1.3) * size.width - size.width * 0.15;
      final dy = p.y * size.height;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(dx, dy), width: 140 + p.size * 20, height: 26),
        paint,
      );
    }
  }

  void _paintDust(Canvas canvas, Size size) {
    // Fast horizontal streaks blown sideways — visually distinct from rain
    // (which falls near-vertically) to read as "wind-driven", not "rain".
    final paint = Paint()
      ..color = tint.withOpacity(0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final p in particles) {
      final progress = (t * p.speed * 30 + p.phase * 30) % 1.3;
      final dx = (progress - 0.15) * size.width * 1.3;
      final dy = p.y * size.height + sin(progress * pi * 2) * 8;
      canvas.drawLine(Offset(dx, dy), Offset(dx - 22, dy + 4), paint);
    }
  }

  void _paintWindLines(Canvas canvas, Size size) {
    // Crisp, fast, mostly-horizontal streak lines — a lighter, faster
    // cousin of the dust effect, evoking a brisk breeze rather than a storm.
    final paint = Paint()
      ..color = tint.withOpacity(0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final p in particles) {
      final progress = (t * p.speed * 40 + p.phase * 40) % 1.4;
      final dx = (progress - 0.2) * size.width * 1.4;
      final dy = p.y * size.height;
      canvas.drawLine(Offset(dx, dy), Offset(dx - 30, dy), paint);
    }
  }

  void _paintRain(Canvas canvas, Size size, {required double streakLength, required Color color}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final p in particles) {
      final progress = (t * p.speed * 20 + p.phase * 20) % 1.2;
      final dy = (p.y + progress) % 1.2 * size.height;
      final dx = p.x * size.width + sin(progress * pi) * 6;
      canvas.drawLine(Offset(dx, dy), Offset(dx - 3, dy + streakLength), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.75);
    for (final p in particles) {
      final progress = (t * p.speed * 6 + p.phase * 6) % 1.15;
      final dy = progress * size.height;
      final sway = sin((t * 6 + p.phase * 10)) * 14;
      final dx = p.x * size.width + sway;
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  void _paintSunRays(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.14);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const rayCount = 10;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * pi + t * 2 * pi * 0.05;
      final inner = center + Offset(cos(angle), sin(angle)) * 46;
      final outer = center + Offset(cos(angle), sin(angle)) * 78;
      canvas.drawLine(inner, outer, paint);
    }
    canvas.drawCircle(center, 34, Paint()..color = Colors.white.withOpacity(0.18));
  }

  void _paintDriftingClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.12);
    for (final p in particles) {
      final dx = ((p.x + t * p.speed * 0.05) % 1.2) * size.width;
      final dy = p.y * size.height * 0.5;
      canvas.drawCircle(Offset(dx, dy), p.size * 6, paint);
      canvas.drawCircle(Offset(dx + p.size * 5, dy + 4), p.size * 4.5, paint);
    }
  }

  void _paintLightningFlash(Canvas canvas, Size size) {
    // A brief, irregular flash — not on every frame, driven by a coarse
    // pseudo-random gate off the shared animation clock so it stays in sync
    // without needing a separate timer.
    final flashWindow = (t * 5) % 1.0;
    if (flashWindow < 0.02) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withOpacity(0.10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.condition != condition;
}

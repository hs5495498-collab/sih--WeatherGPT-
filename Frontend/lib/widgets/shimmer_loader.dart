import 'package:flutter/material.dart';

/// A shimmering placeholder block — built directly with ShaderMask + an
/// AnimationController rather than pulling in a package, so loading states
/// feel intentional instead of a bare spinner.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 + t * 3, 0),
              end: Alignment(t * 3, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ).createShader(rect);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// The full dashboard skeleton shown while the first weather fetch is in flight.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 120, height: 14),
          const SizedBox(height: 8),
          const ShimmerBox(width: 180, height: 26),
          const SizedBox(height: 16),
          ShimmerBox(height: 220, borderRadius: 24),
          const SizedBox(height: 20),
          const ShimmerBox(width: 140, height: 18),
          const SizedBox(height: 10),
          ShimmerBox(height: 70, borderRadius: 18),
          const SizedBox(height: 10),
          ShimmerBox(height: 70, borderRadius: 18),
        ],
      ),
    );
  }
}

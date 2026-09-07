import 'package:flutter/material.dart';

/// Animates its child in (fade + slide) the first time it scrolls into the
/// viewport, then stays visible — the "content reveals as you scroll" effect
/// landing pages use, built directly on Scrollable's position listener
/// rather than pulling in a visibility-detection package.
class ScrollRevealSection extends StatefulWidget {
  const ScrollRevealSection({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideFrom = const Offset(0, 0.12),
  });

  final Widget child;
  final Duration delay;
  final Offset slideFrom;

  @override
  State<ScrollRevealSection> createState() => _ScrollRevealSectionState();
}

class _ScrollRevealSectionState extends State<ScrollRevealSection> with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(begin: widget.slideFrom, end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  ScrollPosition? _position;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && _position != scrollable.position) {
      _position?.removeListener(_checkVisibility);
      _position = scrollable.position;
      _position?.addListener(_checkVisibility);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    }
  }

  void _checkVisibility() {
    if (_revealed || !mounted) return;
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // Reveal once the section's top has scrolled up into the lower 85% of
    // the screen — starts the animation a little before it's fully in view,
    // which reads better than waiting for the exact edge.
    if (position.dy < screenHeight * 0.85) {
      _revealed = true;
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}

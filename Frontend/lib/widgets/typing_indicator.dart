import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Minimal three-dot typing indicator — deliberately restrained (no
/// character/mascot here) to keep the chat interface reading as a
/// professional tool rather than a playful one.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.botBubble,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.slate, shape: BoxShape.circle),
            )
                .animate(onPlay: (c) => c.repeat())
                .moveY(begin: 0, end: -4, duration: 400.ms, delay: (i * 150).ms, curve: Curves.easeInOut)
                .then()
                .moveY(begin: -4, end: 0, duration: 400.ms);
          }),
        ),
      ),
    );
  }
}

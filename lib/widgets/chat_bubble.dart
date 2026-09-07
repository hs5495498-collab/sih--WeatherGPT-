import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import 'alert_banner.dart';
import 'bouncy.dart';
import 'weather_hero_card.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, required this.onSuggestionTap});

  final ChatMessage message;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.userBubble : AppColors.botBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (message.translated)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'Machine-translated',
                style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary.withOpacity(0.7), fontStyle: FontStyle.italic),
              ),
            ),
          if (message.weatherCard != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.82,
                child: WeatherHeroCard(data: message.weatherCard!, compact: true),
              ),
            ),
          if (message.alertCard != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.82,
                child: AlertBanner(alert: message.alertCard!),
              ),
            ),
          if (message.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestions
                    .map((s) => _SuggestionChip(text: s, onTap: () => onSuggestionTap(s)))
                    .toList(),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOut);
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.skyBlueLight.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.skyBlueDeep, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

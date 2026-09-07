import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/languages.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/weather_theme_provider.dart';
import '../services/input_sanitizer.dart';
import '../theme/weather_theme_spec.dart';
import '../widgets/app_logo.dart';
import '../widgets/bouncy.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/dynamic_weather_theme.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/weather_particles.dart';
import 'app_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = text ?? _controller.text;
    if (InputSanitizer.clean(value) == null) return;
    HapticFeedback.lightImpact();
    context.read<ChatProvider>().sendMessage(value);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 160,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _startVoice() {
    context.read<ChatProvider>().startVoiceInput(onFinalText: (text) => _send(text));
  }

  void _clearConversation() {
    context.read<ChatProvider>().clearConversation();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _imagePicker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null || !mounted) return;

    context.read<ChatProvider>().classifyPhoto(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<WeatherThemeProvider>().setCondition(chat.lastCondition),
        );

        if (chat.messages.length != _lastMessageCount) {
          _lastMessageCount = chat.messages.length;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }

        return Consumer<WeatherThemeProvider>(
          builder: (context, themeProvider, _) {
            return DynamicWeatherTheme(
              spec: themeProvider.spec,
              builder: (context, spec) => _ChatScaffold(
                spec: spec,
                chat: chat,
                controller: _controller,
                scrollController: _scrollController,
                onSend: _send,
                onStartVoice: _startVoice,
                onPhotoPick: _pickPhoto,
                onClearConversation: _clearConversation,
              ),
            );
          },
        );
      },
    );
  }
}

class _ChatScaffold extends StatelessWidget {
  const _ChatScaffold({
    required this.spec,
    required this.chat,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onStartVoice,
    required this.onPhotoPick,
    required this.onClearConversation,
  });

  final WeatherThemeSpec spec;
  final ChatProvider chat;
  final TextEditingController controller;
  final ScrollController scrollController;
  final void Function([String?]) onSend;
  final VoidCallback onStartVoice;
  final VoidCallback onPhotoPick;
  final VoidCallback onClearConversation;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: spec.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: spec.backgroundGradient.last,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: InkWell(
            // Tapping the title takes you home from anywhere in the tab set —
            // standard "logo goes home" convention.
            onTap: () => context.read<NavigationProvider>().goHome(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(size: 22, color: spec.textPrimary, accentColor: spec.accent),
                  const SizedBox(width: 9),
                  Text('WeatherGPT', style: TextStyle(color: spec.textPrimary)),
                ],
              ),
            ),
          ),
          iconTheme: IconThemeData(color: spec.textPrimary),
          actions: [
            // Real, on-demand "voice guidance" — speaks a short spoken
            // walkthrough of the mic/photo buttons in whatever language is
            // currently selected. Distinct from "read replies aloud" (which
            // only reads chat answers) — this works even before you've
            // asked anything.
            IconButton(
              tooltip: 'Voice guidance',
              icon: chat.isSpeakingGuidance
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: spec.textPrimary),
                    )
                  : Icon(Icons.volume_up_rounded, color: spec.textPrimary),
              onPressed: chat.isSpeakingGuidance ? null : () => chat.speakVoiceGuidance(),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: spec.textPrimary),
              onSelected: (value) {
                if (value.startsWith('lang_')) {
                  chat.setLanguage(value.substring('lang_'.length));
                  return;
                }
                switch (value) {
                  case 'read_aloud':
                    chat.toggleReadAloud();
                    break;
                  case 'clear':
                    onClearConversation();
                    break;
                }
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: 'read_aloud',
                  checked: chat.readAloudEnabled,
                  child: const Text('Read replies aloud'),
                ),
                const PopupMenuDivider(),
                // One entry per supported language (see core/languages.dart).
                // Native-script label first so it's readable regardless of
                // whether the reader's comfortable language is English.
                for (final lang in kSupportedLanguages)
                  CheckedPopupMenuItem(
                    value: 'lang_${lang.code}',
                    checked: chat.language == lang.code,
                    child: Text(
                      lang.code == 'en' ? lang.nativeLabel : '${lang.nativeLabel} (${lang.label})',
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'clear', child: Text('Clear conversation')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const ConnectivityBanner(),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: spec.backgroundGradient,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: WeatherParticleField(
                        condition: spec.name,
                        opacity: 0.35,
                        tint: spec.particleTint,
                      ),
                    ),
                    ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: chat.messages.length + (chat.isTyping ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == chat.messages.length) {
                          return const TypingIndicator();
                        }
                        final ChatMessage m = chat.messages[i];
                        return ChatBubble(message: m, onSuggestionTap: onSend);
                      },
                    ),
                  ],
                ),
              ),
              _Composer(
                spec: spec,
                controller: controller,
                onSend: onSend,
                onMicTap: chat.isListening
                    ? () => context.read<ChatProvider>().stopVoiceInput()
                    : onStartVoice,
                onPhotoPick: onPhotoPick,
                isListening: chat.isListening,
                disabled: chat.isTyping,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.spec,
    required this.controller,
    required this.onSend,
    required this.onMicTap,
    required this.onPhotoPick,
    required this.isListening,
    required this.disabled,
  });

  final WeatherThemeSpec spec;
  final TextEditingController controller;
  final ValueChanged<String?> onSend;
  final VoidCallback onMicTap;
  final VoidCallback onPhotoPick;
  final bool isListening;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: spec.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Bouncy(
            onTap: disabled ? null : onPhotoPick,
            child: Icon(Icons.camera_alt_outlined, color: spec.accent, size: 22),
          ),
          const SizedBox(width: 10),
          Bouncy(
            onTap: disabled ? null : onMicTap,
            child: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: isListening ? const Color(0xFFB3413B) : spec.accent,
              size: 24,
            )
                .animate(target: isListening ? 1 : 0)
                .scaleXY(begin: 1, end: 1.2, duration: 200.ms)
                .then()
                .scaleXY(begin: 1.2, end: 1, duration: 200.ms),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !disabled,
              maxLength: InputSanitizer.maxLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) => onSend(v),
              style: TextStyle(color: spec.textPrimary),
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                  currentLength > (maxLength ?? 0) * 0.8
                      ? Text('$currentLength/$maxLength',
                          style: TextStyle(fontSize: 10, color: spec.textSecondary))
                      : null,
              decoration: InputDecoration(
                hintText: isListening ? 'Listening…' : 'Ask about weather anywhere in India…',
                hintStyle: TextStyle(color: spec.textSecondary),
                filled: true,
                fillColor: spec.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Bouncy(
            onTap: disabled ? null : () => onSend(null),
            child: Container(
              decoration: BoxDecoration(
                color: disabled ? spec.textSecondary : spec.accent,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(13),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

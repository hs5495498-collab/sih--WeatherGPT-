import 'dart:async' show unawaited;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/languages.dart';
import '../models/chat_message.dart';
import '../services/analytics_service.dart';
import '../services/api_client.dart';
import '../services/input_sanitizer.dart';
import '../services/rate_limiter.dart';
import '../services/vision_inference_service.dart';
import '../services/voice_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ApiClient? apiClient, VoiceService? voiceService, VisionInferenceService? visionService})
      : _api = apiClient ?? ApiClient(),
        _voice = voiceService ?? VoiceService(),
        _vision = visionService ?? VisionInferenceService(),
        _rateLimiter = RateLimiter() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text:
            "Namaste! I'm WeatherGPT 🌦️ — ask me about forecasts, rain, or "
            "severe-weather alerts anywhere in India.",
        sender: Sender.bot,
        suggestions: const [
          'Will it rain in Patna tomorrow evening?',
          'Is there a cyclone alert for coastal Odisha?',
        ],
      ),
    );
    _vision.initialize(); // best-effort — isReady is checked before use, never blocks startup
  }

  final ApiClient _api;
  final VoiceService _voice;
  final VisionInferenceService _vision;
  final RateLimiter _rateLimiter;
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  bool _isListening = false;
  bool readAloudEnabled = false;
  bool isSpeakingGuidance = false;

  /// One of [kSupportedLanguages]' `code` values — drives STT locale, TTS
  /// locale, the voice-guidance script, and the `lang` field sent to the
  /// backend. See core/languages.dart for exactly what is and isn't
  /// translated at each of those layers.
  String language = 'en';
  String lastCondition = 'default';

  /// 0.3 (slow/clear) – 1.0 (natural pace). Kept in sync with
  /// AppSettingsProvider's persisted speech-rate slider by HomeShell.
  double speechRate = 0.48;

  void setSpeechRate(double rate) {
    speechRate = rate.clamp(0.3, 1.0);
    notifyListeners();
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;
  bool get visionReady => _vision.isReady;

  AppLanguage get currentLanguage => languageForCode(language);
  String get _ttsLocale => currentLanguage.ttsLocaleId;
  String get _sttLocale => currentLanguage.sttLocaleId;

  /// Sets the active language for voice input/output, the language picker,
  /// and outgoing chat requests. Accepts any code in [kSupportedLanguages];
  /// unknown codes fall back to English rather than silently doing nothing.
  void setLanguage(String lang) {
    language = languageForCode(lang).code;
    notifyListeners();
  }

  /// Speaks a short, real spoken explanation of how to use the chat screen
  /// in the currently-selected language — a genuine "voice guidance"
  /// feature (not just read-aloud of replies), useful for low-literacy
  /// users and demoable on its own regardless of what the backend returns.
  Future<void> speakVoiceGuidance() async {
    if (isSpeakingGuidance) return;
    isSpeakingGuidance = true;
    notifyListeners();
    await _voice.speak(voiceGuidanceFor(language), languageCode: _ttsLocale, speechRate: speechRate);
    isSpeakingGuidance = false;
    notifyListeners();
  }

  void toggleReadAloud() {
    readAloudEnabled = !readAloudEnabled;
    if (!readAloudEnabled) _voice.stopSpeaking();
    notifyListeners();
  }

  /// Resets the conversation back to just the welcome message — the 3-dot
  /// menu's "Clear conversation" action. Does not touch language/read-aloud
  /// preferences, only the message history.
  void clearConversation() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        id: 'welcome-${DateTime.now().microsecondsSinceEpoch}',
        text: "Namaste! I'm WeatherGPT 🌦️ — ask me about forecasts, rain, or "
            "severe-weather alerts anywhere in India.",
        sender: Sender.bot,
        suggestions: const [
          'Will it rain in Patna tomorrow evening?',
          'Is there a cyclone alert for coastal Odisha?',
        ],
      ),
    );
    lastCondition = 'default';
    notifyListeners();
  }

  /// Guards against the race condition where rapid taps/submits fire
  /// multiple concurrent backend calls and replies can land out of
  /// order. While a request is in flight, further sends are ignored
  /// rather than queued — simplest fix that keeps message ordering
  /// guaranteed to match what the user actually sent.
  Future<void> sendMessage(String rawText) async {
    if (_isTyping) return;

    final cleaned = InputSanitizer.clean(rawText);
    if (cleaned == null) return;

    final limitReason = _rateLimiter.checkAndRecord();
    if (limitReason != null) {
      _messages.add(ChatMessage(
        id: 'rl-${DateTime.now().microsecondsSinceEpoch}',
        text: limitReason,
        sender: Sender.bot,
      ));
      notifyListeners();
      return;
    }

    _messages.add(ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: cleaned,
      sender: Sender.user,
    ));
    _isTyping = true;
    notifyListeners();
    unawaited(AnalyticsService.instance.recordChatMessageSent(languageCode: language));

    final response = await _api.sendChatQuery(cleaned, lang: language);

    await Future.delayed(const Duration(milliseconds: 500));

    if (response.weather != null) lastCondition = response.weather!.condition;
    if (response.alert != null && response.weather == null) {
      lastCondition = 'storm';
    }

    _messages.add(ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-bot',
      text: response.answer,
      sender: Sender.bot,
      weatherCard: response.weather,
      alertCard: response.alert,
      suggestions: response.suggestions,
      translated: response.translated,
    ));
    _isTyping = false;
    notifyListeners();

    if (readAloudEnabled) {
      _voice.speak(response.answer, languageCode: _ttsLocale, speechRate: speechRate);
    }
  }

  Future<void> startVoiceInput({
    required void Function(String finalText) onFinalText,
  }) async {
    if (_isTyping || _isListening) return;
    _isListening = true;
    notifyListeners();

    String lastHeard = '';
    final started = await _voice.startListening(
      localeId: _sttLocale,
      onResult: (text) => lastHeard = text,
      onDone: () {
        _isListening = false;
        notifyListeners();
        if (lastHeard.trim().isNotEmpty) onFinalText(lastHeard.trim());
      },
    );

    if (!started) {
      _isListening = false;
      _messages.add(ChatMessage(
        id: 'voice-unavailable-${DateTime.now().microsecondsSinceEpoch}',
        text: "Voice input isn't available right now — mic access may be "
            "denied, or it's not supported on this device. You can still "
            "type your question.",
        sender: Sender.bot,
      ));
      notifyListeners();
    }
  }

  Future<void> stopVoiceInput() async {
    await _voice.stopListening();
    _isListening = false;
    notifyListeners();
  }

  /// Classifies a user-provided sky/weather photo entirely on-device and
  /// posts the result as a chat message — the integration that connects
  /// Member 4's trained image classifier to the app. Runs fully offline;
  /// no backend call involved.
  Future<void> classifyPhoto(File imageFile) async {
    if (_isTyping) return;

    _messages.add(ChatMessage(
      id: 'photo-${DateTime.now().microsecondsSinceEpoch}',
      text: '📷 Photo attached',
      sender: Sender.user,
    ));
    _isTyping = true;
    notifyListeners();

    if (!_vision.isReady) {
      await Future.delayed(const Duration(milliseconds: 300));
      _messages.add(ChatMessage(
        id: 'vision-unavailable-${DateTime.now().microsecondsSinceEpoch}',
        text: "Photo classification isn't set up in this build yet — the "
            "trained model file needs to be bundled as an app asset. You "
            "can still ask about weather by typing or voice.",
        sender: Sender.bot,
      ));
      _isTyping = false;
      notifyListeners();
      return;
    }

    final result = await _vision.classify(imageFile);
    await Future.delayed(const Duration(milliseconds: 400)); // matches the "thinking" pacing used elsewhere

    if (result == null) {
      _messages.add(ChatMessage(
        id: 'vision-failed-${DateTime.now().microsecondsSinceEpoch}',
        text: "I couldn't read that photo — try a clearer shot of the sky "
            "or a different image.",
        sender: Sender.bot,
      ));
    } else {
      final conditionLabel = _humanizeLabel(result.label);
      final confidencePct = (result.confidence * 100).round();

      lastCondition = _mapToThemeCondition(result.label);

      _messages.add(ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-vision',
        text: confidencePct >= 60
            ? "That looks like $conditionLabel conditions — ${confidencePct}% confidence."
            : "My best guess is $conditionLabel, but I'm not fully sure (${confidencePct}% confidence) — "
                "the photo may be ambiguous.",
        sender: Sender.bot,
      ));
    }

    _isTyping = false;
    notifyListeners();
  }

  String _humanizeLabel(String label) => label.replaceAll('_', ' ');

  /// Maps the vision model's 14 fine-grained classes onto the app's
  /// coarser theme vocabulary (sunny/rainy/cloudy/storm/snow/hazy/dusty/
  /// windy) so a classified photo also drives the dynamic weather theme,
  /// same as a chat answer about real weather data would.
  String _mapToThemeCondition(String visionLabel) {
    switch (visionLabel) {
      case 'shine':
      case 'sunrise':
        return 'sunny';
      case 'rain':
        return 'rainy';
      case 'lightning':
        return 'storm';
      case 'snow':
      case 'frost':
      case 'glaze':
      case 'rime':
        return 'snow';
      case 'fogsmog':
        return 'hazy';
      case 'sandstorm':
        return 'dusty';
      case 'cloudy':
        return 'cloudy';
      default:
        return 'cloudy'; // dew, rainbow, hail — no direct theme match; neutral fallback
    }
  }

  @override
  void dispose() {
    _vision.dispose();
    super.dispose();
  }
}

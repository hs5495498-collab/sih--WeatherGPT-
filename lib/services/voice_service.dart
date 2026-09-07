import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps voice input and read-aloud. Every call is defensive: a missing
/// mic permission, an unsupported platform, or a plugin failure should
/// degrade to "voice just isn't available right now", never crash the
/// chat screen. This matters a lot for a disaster-alert tool used by
/// people who may not be fluent readers, or who need hands-free alerts.
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttReady = false;

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Starts listening; calls [onResult] with partial/final transcripts.
  /// Returns false immediately if permission is denied or init fails.
  Future<bool> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
    String localeId = 'en_IN',
  }) async {
    try {
      if (!await _ensureMicPermission()) return false;

      _sttReady = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') onDone();
        },
        onError: (_) => onDone(),
      );
      if (!_sttReady) return false;

      await _speech.listen(
        onResult: (result) => onResult(result.recognizedWords),
        localeId: localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {
      // no-op — nothing meaningful to recover into
    }
  }

  /// Reads [text] aloud in [languageCode] (e.g. 'en-IN', 'hi-IN') at
  /// [speechRate] (0.3 = slow/clear, 1.0 = natural pace — see Settings'
  /// speech-rate slider, which is the real control surface for this).
  /// Silently no-ops on failure rather than surfacing a TTS error to a
  /// user who's relying on audio because they can't easily read the screen.
  Future<void> speak(String text, {String languageCode = 'en-IN', double speechRate = 0.48}) async {
    try {
      await _tts.setLanguage(languageCode);
      await _tts.setSpeechRate(speechRate.clamp(0.3, 1.0));
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // no-op
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {
      // no-op
    }
  }
}

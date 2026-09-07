/// Central registry of every language WeatherGPT can speak, listen to, and
/// display a language-picker label for.
///
/// Status (kept current — see backend/app/services/translation_service.py):
/// Voice input (STT), voice output (TTS), and the language picker UI are
/// genuinely multilingual using the phone's own on-device speech engines.
/// On top of that, chat replies are now translated too: for any non-English
/// language the backend translates the incoming message to English before
/// the NLU/orchestrator runs, then translates the English reply back to
/// the user's language before returning it (via MyMemory's free translation
/// API). So every language listed below gets real text *and* real voice in
/// that language, not just voice.
///
/// The one honest caveat: machine translation quality varies by language
/// pair and can occasionally mistranslate a weather term. The backend
/// flags this explicitly — every chat response includes a `translated`
/// bool, and the chat bubble shows a small "Machine-translated" caption
/// whenever it's true, so nothing is presented as more authoritative than
/// it is.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.sttLocaleId,
    required this.ttsLocaleId,
    this.backendResponsesSupported = false,
  });

  /// Short code used as ChatProvider.language / sent to the backend as `lang`.
  final String code;

  /// English display name, for contexts where the UI itself is in English.
  final String label;

  /// Name written in the language's own script — always used in the picker.
  final String nativeLabel;

  /// Locale id for `speech_to_text` (usually `xx_IN`).
  final String sttLocaleId;

  /// Locale id for `flutter_tts` (usually `xx-IN`).
  final String ttsLocaleId;

  /// Whether the backend can produce chat text in this language today.
  /// True for every language in [kSupportedLanguages] — English is answered
  /// natively, every other language goes through the translation round-trip
  /// described above. Kept as a field (rather than deleted) so the settings
  /// screen has one obvious place to show a caveat if a language ever needs
  /// one again (e.g. a language MyMemory doesn't support well).
  final bool backendResponsesSupported;
}

/// The 8 Indian languages named in the app's brief, plus English.
/// Order here is the order shown in every picker.
const List<AppLanguage> kSupportedLanguages = [
  AppLanguage(
    code: 'en',
    label: 'English',
    nativeLabel: 'English',
    sttLocaleId: 'en_IN',
    ttsLocaleId: 'en-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'hi',
    label: 'Hindi',
    nativeLabel: 'हिन्दी',
    sttLocaleId: 'hi_IN',
    ttsLocaleId: 'hi-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'mr',
    label: 'Marathi',
    nativeLabel: 'मराठी',
    sttLocaleId: 'mr_IN',
    ttsLocaleId: 'mr-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'bn',
    label: 'Bengali',
    nativeLabel: 'বাংলা',
    sttLocaleId: 'bn_IN',
    ttsLocaleId: 'bn-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'pa',
    label: 'Punjabi',
    nativeLabel: 'ਪੰਜਾਬੀ',
    sttLocaleId: 'pa_IN',
    ttsLocaleId: 'pa-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'ta',
    label: 'Tamil',
    nativeLabel: 'தமிழ்',
    sttLocaleId: 'ta_IN',
    ttsLocaleId: 'ta-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'te',
    label: 'Telugu',
    nativeLabel: 'తెలుగు',
    sttLocaleId: 'te_IN',
    ttsLocaleId: 'te-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'gu',
    label: 'Gujarati',
    nativeLabel: 'ગુજરાતી',
    sttLocaleId: 'gu_IN',
    ttsLocaleId: 'gu-IN',
    backendResponsesSupported: true,
  ),
  AppLanguage(
    code: 'kn',
    label: 'Kannada',
    nativeLabel: 'ಕನ್ನಡ',
    sttLocaleId: 'kn_IN',
    ttsLocaleId: 'kn-IN',
    backendResponsesSupported: true,
  ),
];

AppLanguage languageForCode(String code) {
  return kSupportedLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => kSupportedLanguages.first, // English fallback — never throws on a bad/stale saved code
  );
}

/// Short, hand-written voice-guidance scripts read aloud when the user taps
/// the help/guidance button on the chat screen — one per supported
/// language, so this always feels native rather than routed through
/// machine translation. Any future language added to [kSupportedLanguages]
/// without an entry here falls back to the English script instead of
/// silently doing nothing.
const Map<String, String> kVoiceGuidanceScript = {
  'en': "Tap the microphone and ask a weather question. Tap the camera to "
      "classify a photo of the sky. Your reply will be read aloud if read-aloud is on.",
  'hi': "मौसम पूछने के लिए माइक्रोफ़ोन दबाएँ। आसमान की फ़ोटो पहचानने के लिए कैमरा दबाएँ। "
      "जवाब बोलकर सुनाया जाएगा अगर आवाज़ चालू है।",
  'mr': "हवामानाबद्दल विचारण्यासाठी मायक्रोफोन दाबा. आकाशाचा फोटो ओळखण्यासाठी कॅमेरा दाबा.",
  'bn': "আবহাওয়া জিজ্ঞাসা করতে মাইক্রোফোনে চাপুন। আকাশের ছবি শনাক্ত করতে ক্যামেরায় চাপুন।",
  'pa': "ਮੌਸਮ ਪੁੱਛਣ ਲਈ ਮਾਈਕ੍ਰੋਫ਼ੋਨ ਦਬਾਓ। ਅਸਮਾਨ ਦੀ ਫੋਟੋ ਪਛਾਣਨ ਲਈ ਕੈਮਰਾ ਦਬਾਓ।",
  'ta': "வானிலை கேட்க மைக்ரோஃபோனை அழுத்தவும். வானத்தின் புகைப்படத்தை அடையாளம் காண கேமராவை அழுத்தவும்.",
  'te': "వాతావరణం అడగడానికి మైక్రోఫోన్ నొక్కండి. ఆకాశం ఫోటోను గుర్తించడానికి కెమెరాను నొక్కండి.",
  'gu': "હવામાન પૂછવા માટે માઇક્રોફોન દબાવો. આકાશનો ફોટો ઓળખવા માટે કેમેરા દબાવો.",
  'kn': "ಹವಾಮಾನ ಕೇಳಲು ಮೈಕ್ರೊಫೋನ್ ಒತ್ತಿ. ಆಕಾಶದ ಫೋಟೋ ಗುರುತಿಸಲು ಕ್ಯಾಮೆರಾ ಒತ್ತಿ.",
};

String voiceGuidanceFor(String code) => kVoiceGuidanceScript[code] ?? kVoiceGuidanceScript['en']!;

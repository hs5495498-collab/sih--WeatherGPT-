import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/languages.dart';

/// App-wide settings the user actually controls, persisted across launches.
/// This is distinct from WeatherThemeProvider (which reflects live weather
/// mood in the chat/dashboard content area) — this controls the app's
/// chrome (AppBar, Drawer, Settings, Auth screens): light, dark, or follow
/// system.
class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider() {
    _load();
  }

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _isLoaded = false;

  // App-wide language preference — the default new chats/voice start with.
  // Kept here (rather than only inside ChatProvider) so it survives app
  // restarts and so Settings is a real, single place to change it.
  String _preferredLanguage = 'en';

  // TTS speech rate, 0.3 (slow, clearer) – 1.0 (natural). flutter_tts's own
  // scale tops out effectively around 1.0 for intelligible speech, so the
  // picker exposes 0.3–1.0 rather than the unrealistic 1.5 sometimes quoted.
  double _speechRate = 0.48;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoaded => _isLoaded;
  String get preferredLanguage => _preferredLanguage;
  double get speechRate => _speechRate;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[modeIndex];
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _preferredLanguage = languageForCode(prefs.getString('preferred_language') ?? 'en').code;
    _speechRate = prefs.getDouble('speech_rate') ?? 0.48;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPreferredLanguage(String code) async {
    _preferredLanguage = languageForCode(code).code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', _preferredLanguage);
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.3, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speech_rate', _speechRate);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }
}

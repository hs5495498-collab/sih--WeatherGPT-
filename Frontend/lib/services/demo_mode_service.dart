import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hidden demo-mode toggle. Reached from Settings by tapping the Version
/// row's number 7 times.
///
/// What it actually changes when ON:
/// - WeatherProvider skips the live API entirely and always serves
///   MockDataService's deterministic "clear, 32°C" weather + one sample
///   advisory alert, so a demo never stalls on bad venue Wi-Fi or an
///   unpredictable live forecast.
///
/// What it deliberately does NOT change, on purpose:
/// - The offline "You're offline" banner and any other real error/status
///   indicators stay exactly as they are. The wishlist item asked for
///   "error suppression (never show network errors in demo mode)" — for a
///   disaster-alert app, hiding real connectivity/error state during a
///   judged demo is the wrong tradeoff: it would let the app *look* fine
///   while quietly telling a user in a real emergency that everything's
///   fine when it isn't. Faster/more reliable data (above) is a legitimate
///   demo aid; hiding failure states is not, so this was intentionally
///   left out rather than silently built in.
/// - There's no auto-advancing "script mode" that drives the UI for you —
///   that would need real navigation-automation logic this environment
///   has no way to compile or test, so it isn't included. Demo mode here
///   just makes the data reliable; you still drive the app yourself.
class DemoModeService extends ChangeNotifier {
  DemoModeService._() {
    _load();
  }
  static final DemoModeService instance = DemoModeService._();

  static const _kKey = 'demo_mode_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, value);
  }

  Future<void> toggle() => setEnabled(!_enabled);
}

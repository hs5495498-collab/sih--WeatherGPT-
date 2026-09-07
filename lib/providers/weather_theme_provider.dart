import 'package:flutter/material.dart';
import '../theme/weather_theme_spec.dart';

/// Tracks "what weather condition should the app's mood reflect right now"
/// and exposes the resulting WeatherThemeSpec. Updated by ChatProvider
/// (when a location's weather comes up in conversation) and WeatherProvider
/// (when the dashboard's location changes) — both funnel into this single
/// source of truth so the whole app stays visually consistent rather than
/// each screen deciding its own colors independently.
class WeatherThemeProvider extends ChangeNotifier {
  String _condition = 'default';

  String get condition => _condition;
  WeatherThemeSpec get spec => WeatherThemeSpec.forCondition(_condition);

  void setCondition(String condition) {
    if (condition == _condition) return;
    _condition = condition;
    notifyListeners();
  }
}

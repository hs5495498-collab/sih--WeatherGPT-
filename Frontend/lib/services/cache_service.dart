import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_alert.dart';
import '../models/weather_data.dart';

/// Caches the last successfully-fetched weather + alerts locally.
/// For a disaster-management tool, "show the last known alert when the
/// network drops" is more useful than "show nothing" — this is a safety
/// feature, not just a UX nicety.
class CacheService {
  static const _weatherKey = 'cache_weather_v1';
  static const _alertsKey = 'cache_alerts_v1';
  static const _timestampKey = 'cache_timestamp_v1';

  Future<void> saveWeather(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weatherKey, jsonEncode(_weatherToJson(data)));
      await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
    } catch (_) {
      // Caching is best-effort — never block the UI on a storage failure.
    }
  }

  Future<void> saveAlerts(List<WeatherAlert> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _alertsKey,
        jsonEncode(alerts.map(_alertToJson).toList()),
      );
    } catch (_) {
      // best-effort
    }
  }

  Future<(WeatherData?, DateTime?)> loadWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_weatherKey);
      final ts = prefs.getString(_timestampKey);
      if (raw == null) return (null, null);
      return (
        WeatherData.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        ts != null ? DateTime.tryParse(ts) : null,
      );
    } catch (_) {
      return (null, null);
    }
  }

  Future<List<WeatherAlert>> loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_alertsKey);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(WeatherAlert.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _weatherToJson(WeatherData d) => {
        'location': d.location,
        'temp_c': d.tempC,
        'condition': d.condition,
        'description': d.description,
        'humidity_pct': d.humidityPct,
        'wind_kmh': d.windKmh,
        'forecast': d.forecast
            .map((f) => {
                  'date': f.date.toIso8601String(),
                  'temp_max_c': f.tempMaxC,
                  'temp_min_c': f.tempMinC,
                  'condition': f.condition,
                })
            .toList(),
      };

  Map<String, dynamic> _alertToJson(WeatherAlert a) => {
        'id': a.id,
        'severity': a.severity.name,
        'title': a.title,
        'message': a.message,
        'region': a.region,
        'issued_at': a.issuedAt.toIso8601String(),
        'valid_until': a.validUntil?.toIso8601String(),
      };
}

class ForecastDay {
  final DateTime date;
  final double tempMaxC;
  final double tempMinC;
  final String condition; // sunny | rainy | cloudy | storm | snow

  ForecastDay({
    required this.date,
    required this.tempMaxC,
    required this.tempMinC,
    required this.condition,
  });

  /// Defensive parsing: a malformed or partial forecast entry from the
  /// backend must never crash the chat — fall back to safe defaults and
  /// let the UI render "something" rather than throw mid-conversation.
  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return ForecastDay(
      date: parsedDate,
      tempMaxC: _asDouble(json['temp_max_c'], fallback: 30),
      tempMinC: _asDouble(json['temp_min_c'], fallback: 22),
      condition: _asCondition(json['condition']),
    );
  }
}

class WeatherData {
  final String location;
  final double tempC;
  final String condition;
  final String description;
  final int humidityPct;
  final double windKmh;
  final List<ForecastDay> forecast;

  WeatherData({
    required this.location,
    required this.tempC,
    required this.condition,
    required this.description,
    required this.humidityPct,
    required this.windKmh,
    this.forecast = const [],
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    List<ForecastDay> forecast = const [];
    try {
      forecast = (json['forecast'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ForecastDay.fromJson)
          .toList();
    } catch (_) {
      forecast = const [];
    }

    return WeatherData(
      location: (json['location'] as String?)?.trim().isNotEmpty == true
          ? json['location'] as String
          : 'Unknown location',
      tempC: _asDouble(json['temp_c'], fallback: 25),
      condition: _asCondition(json['condition']),
      description: (json['description'] as String?) ?? '',
      humidityPct: _asInt(json['humidity_pct'], fallback: 50),
      windKmh: _asDouble(json['wind_kmh'], fallback: 10),
      forecast: forecast,
    );
  }
}

/// Only these five values map to known icons/gradients in the UI.
/// Anything else from the backend/ML layer degrades to a neutral look
/// instead of an icon lookup failure.
const _validConditions = {'sunny', 'rainy', 'cloudy', 'storm', 'snow'};

String _asCondition(dynamic value) {
  final s = (value as String?)?.toLowerCase().trim() ?? '';
  return _validConditions.contains(s) ? s : 'cloudy';
}

double _asDouble(dynamic value, {required double fallback}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

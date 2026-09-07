import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/weather_alert.dart';
import 'mock_data_service.dart';

class ChatQueryResponse {
  final String answer;
  final String? language;
  final WeatherData? weather;
  final WeatherAlert? alert;
  final List<String> suggestions;

  /// True only when the backend actually machine-translated [answer] into
  /// [language] (via the free MyMemory API -- see
  /// backend/app/services/translation_service.py). False whenever the
  /// reply is still in English, whether because English was requested or
  /// because translation was attempted and failed. The chat bubble uses
  /// this to show an honest "machine-translated" caption instead of
  /// silently presenting a translation that may not have happened.
  final bool translated;

  ChatQueryResponse({
    required this.answer,
    this.language,
    this.weather,
    this.alert,
    this.suggestions = const [],
    this.translated = false,
  });
}

/// Maps the backend's WMO-derived condition strings (see
/// backend/app/utils/weather_codes.py -- "Clear", "Partly Cloudy", "Rain",
/// "Thunderstorm", "Snow", etc.) onto the app's five-value theme/icon
/// vocabulary (sunny/rainy/cloudy/storm/snow). Kept in one place so every
/// call site (current weather, chat weather cards, forecast strip) stays
/// consistent with the backend's exact wording rather than guessing per call site.
String _normalizeCondition(String? backendCondition) {
  final c = (backendCondition ?? '').toLowerCase();
  if (c.contains('clear')) return 'sunny';
  if (c.contains('thunderstorm')) return 'storm';
  if (c.contains('snow')) return 'snow';
  if (c.contains('rain') || c.contains('drizzle')) return 'rainy';
  if (c.contains('cloud') || c.contains('fog')) return 'cloudy';
  return 'cloudy'; // unknown/default -> neutral, matches WeatherData._asCondition's own fallback
}

/// Maps one alert item as returned by the backend's alert_service
/// (`{type, title, severity, score, message, recommendations,
/// information_class}` -- see backend/app/services/alert_service.py) into
/// the app's WeatherAlert model. The backend is stateless -- alerts are
/// computed fresh from live weather on every request, so it never assigns
/// an id, region, or timestamp the way a stored/pushed alert would. Those
/// are synthesized here rather than left null, since WeatherAlert requires them.
WeatherAlert _alertFromBackendItem(Map<String, dynamic> item, {required String regionLabel}) {
  final title = (item['title'] as String?) ?? 'Weather Alert';
  final recommendations = (item['recommendations'] as List<dynamic>? ?? [])
      .whereType<String>()
      .join(' ');
  final message = [
    if ((item['message'] as String?)?.isNotEmpty == true) item['message'] as String,
    if (recommendations.isNotEmpty) recommendations,
  ].join(' ');

  return WeatherAlert(
    id: 'alert-${item['type'] ?? 'unknown'}-${DateTime.now().microsecondsSinceEpoch}',
    severity: severityFromString(item['severity'] as String?),
    title: title,
    message: message.isNotEmpty ? message : 'Check local conditions.',
    region: regionLabel,
    issuedAt: DateTime.now(),
  );
}

double _asDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Parses a "<lat>,<lon>" string (as produced by WeatherProvider from GPS)
/// into coordinates, or returns null if [location] is a free-text place
/// name instead (e.g. the "New Delhi" default, or a user-typed city).
(double, double)? _parseLatLon(String location) {
  final parts = location.split(',');
  if (parts.length != 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lon = double.tryParse(parts[1].trim());
  if (lat == null || lon == null) return null;
  return (lat, lon);
}

/// Central API client -- speaks the ACTUAL contract of the FastAPI backend
/// in `backend/app/routers/*.py`:
///   POST /api/v1/chat/                                  {message, session_id}
///   GET  /api/v1/weather/current?latitude=&longitude=
///   GET  /api/v1/weather/by-city?city=
///   GET  /api/v1/weather/forecast?latitude=&longitude=&days=
///   GET  /api/v1/alerts/?city=
///
/// IMPORTANT HISTORY NOTE: an earlier version of this file called
/// `/api/chat/query`, `/api/weather/current?location=`, and
/// `/api/alerts?region=` -- a different path AND a different request/response
/// shape than this backend actually implements. Because every method here
/// wraps failures in try/catch and falls back to MockDataService, that
/// mismatch was silent: the app would always look "connected" while
/// actually only ever showing local mock data, even against a live,
/// correctly-deployed backend. This rewrite matches the real contract so a
/// live backend is genuinely reachable; the mock fallback below still
/// exists for real network failures / demo-safety, not to paper over a
/// wrong URL.
///
/// SECURITY NOTES (unchanged from before):
/// - Base URL comes from a compile-time define (`--dart-define=API_BASE_URL=...`),
///   never hardcoded in source.
/// - HTTPS is enforced at runtime; a plain-http backend URL is rejected.
/// - Optional bearer token (`--dart-define=API_AUTH_TOKEN=...`) is attached
///   to every request, for whenever the backend's endpoints start requiring one.
/// - Every call has a timeout + a single retry with backoff.
class ApiClient {
  ApiClient({
    String? baseUrl,
    String? authToken,
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://REPLACE-WITH-BACKEND-URL.example.com',
            ),
        authToken = authToken ??
            const String.fromEnvironment('API_AUTH_TOKEN', defaultValue: '') {
    if (!this.baseUrl.startsWith('https://')) {
      throw ArgumentError(
        'API_BASE_URL must use https:// — refusing to send weather/alert '
        'data over an insecure connection.',
      );
    }
  }

  final String baseUrl;
  final String authToken;
  static const Duration _timeout = Duration(seconds: 6);
  static const int _maxAttempts = 2;

  // Chat session continuity: the backend generates a session_id on the
  // first message and expects it back on subsequent ones to keep history
  // threaded server-side (see ChatRequest/ChatResponse in
  // backend/app/schemas/chat.py). Best-effort only -- if history saving
  // fails server-side, chat itself still works (see history_service.py).
  String? _chatSessionId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      };

  Future<http.Response> _withRetry(Future<http.Response> Function() call) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await call().timeout(_timeout);
      } catch (e) {
        lastError = e;
        if (attempt < _maxAttempts) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        }
      }
    }
    throw lastError ?? Exception('Request failed');
  }

  /// POST /api/v1/chat/
  Future<ChatQueryResponse> sendChatQuery(
    String message, {
    String? lang,
    String? location,
  }) async {
    try {
      final res = await _withRetry(
        () => http.post(
          Uri.parse('$baseUrl/api/v1/chat/'),
          headers: _headers,
          body: jsonEncode({
            'message': message,
            if (_chatSessionId != null) 'session_id': _chatSessionId,
            'lang': lang ?? 'en',
          }),
        ),
      );

      if (res.statusCode == 429) {
        return ChatQueryResponse(
          answer: "The server's getting a lot of requests right now — please "
              "try again in a few seconds.",
        );
      }
      if (res.statusCode != 200) {
        throw Exception('Backend returned ${res.statusCode}');
      }

      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

      if (json['session_id'] is String) _chatSessionId = json['session_id'] as String;

      final success = json['success'] as bool? ?? false;
      final answer = (json['response'] as String?) ??
          (json['message'] as String?) ??
          (success
              ? "I got a response back but couldn't read it properly — could you try rephrasing that?"
              : "I couldn't find that — try naming a specific city, e.g. \"weather in Patna\".");

      final route = json['route'] as String?;
      final locationMap = json['location'] is Map ? json['location'] as Map<String, dynamic> : null;
      final cityLabel = (locationMap?['city'] as String?) ?? (locationMap?['name'] as String?) ?? 'Your area';

      // Only the "weather" route returns a true current-conditions reading
      // (see chat_orchestrator.py). The "forecast" route returns a future
      // day's numbers under a differently-shaped `forecast` key -- building
      // a "current weather" card out of tomorrow's forecast would misrepresent
      // it as live, so that case intentionally falls through to text-only.
      WeatherData? weather;
      if (route == 'weather' && json['weather'] is Map) {
        final w = json['weather'] as Map<String, dynamic>;
        weather = WeatherData(
          location: cityLabel,
          tempC: _asDouble(w['temperature']),
          condition: _normalizeCondition(w['condition'] as String?),
          description: (w['description'] as String?) ?? '',
          humidityPct: _asInt(w['humidity']),
          windKmh: _asDouble(w['wind_speed']),
        );
      }

      WeatherAlert? alert;
      if (route == 'alert' && json['alerts'] is List && (json['alerts'] as List).isNotEmpty) {
        final first = (json['alerts'] as List).first;
        if (first is Map<String, dynamic>) {
          alert = _alertFromBackendItem(first, regionLabel: cityLabel);
        }
      }

      return ChatQueryResponse(
        answer: answer,
        language: lang,
        weather: weather,
        alert: alert,
        // The backend doesn't return follow-up suggestions today (see
        // ChatResponse in backend/app/schemas/chat.py) -- an honest empty
        // list here, rather than fabricating chips that would look
        // server-generated.
        suggestions: const [],
        translated: json['translated'] as bool? ?? false,
      );
    } catch (_) {
      // Backend unreachable / malformed / venue Wi-Fi failed — degrade to
      // local mock rather than showing a dead chat. See risk checklist.
      return MockDataService.answerFor(message);
    }
  }

  /// Resolves current weather + a short forecast for [location], which is
  /// either a free-text place name (e.g. "New Delhi") or a "<lat>,<lon>"
  /// string from GPS (see LocationService/WeatherProvider). Two backend
  /// calls are combined into one WeatherData because the backend splits
  /// "current conditions" and "forecast" across separate endpoints
  /// (GET /weather/current or /weather/by-city, and GET /weather/forecast
  /// -- see backend/app/routers/weather.py).
  Future<WeatherData> getCurrentWeather(String location, {String? displayLabel}) async {
    try {
      final coords = _parseLatLon(location);

      double latitude;
      double longitude;
      String resolvedLabel = location;
      double tempC = 25, windKmh = 10;
      int humidityPct = 50;
      String condition = 'cloudy';
      String description = '';

      if (coords != null) {
        latitude = coords.$1;
        longitude = coords.$2;
        final res = await _withRetry(
          () => http.get(
            Uri.parse('$baseUrl/api/v1/weather/current').replace(queryParameters: {
              'latitude': '$latitude',
              'longitude': '$longitude',
            }),
            headers: _headers,
          ),
        );
        if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');
        final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        tempC = _asDouble(json['temperature'], fallback: tempC);
        humidityPct = _asInt(json['humidity'], fallback: humidityPct);
        windKmh = _asDouble(json['wind_speed'], fallback: windKmh);
        condition = _normalizeCondition(json['weather_condition'] as String?);
        description = (json['description'] as String?) ?? '';
        // Backend only echoes lat/lon back for this endpoint (see
        // CurrentWeatherResponse in backend/app/schemas/weather.py) -- it
        // never resolves a place name from coordinates. Use the
        // caller-supplied reverse-geocoded label when available (see
        // WeatherProvider/GeocodingService.reverseGeocode) so the UI shows
        // a real place name instead of raw digits; fall back to the
        // coordinates only if no label could be resolved.
        resolvedLabel = (displayLabel != null && displayLabel.trim().isNotEmpty)
            ? displayLabel
            : '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
      } else {
        final res = await _withRetry(
          () => http.get(
            Uri.parse('$baseUrl/api/v1/weather/by-city').replace(queryParameters: {'city': location}),
            headers: _headers,
          ),
        );
        if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');
        final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        latitude = _asDouble(json['latitude']);
        longitude = _asDouble(json['longitude']);
        tempC = _asDouble(json['temperature'], fallback: tempC);
        humidityPct = _asInt(json['humidity'], fallback: humidityPct);
        windKmh = _asDouble(json['wind_speed'], fallback: windKmh);
        condition = _normalizeCondition(json['weather_condition'] as String?);
        description = (json['description'] as String?) ?? '';
        resolvedLabel = (json['city'] as String?)?.trim().isNotEmpty == true
            ? json['city'] as String
            : location;
      }

      // Best-effort forecast strip; current conditions above still return
      // even if this second call fails, since it's the less-critical half.
      List<ForecastDay> forecast = const [];
      try {
        final fres = await _withRetry(
          () => http.get(
            Uri.parse('$baseUrl/api/v1/weather/forecast').replace(queryParameters: {
              'latitude': '$latitude',
              'longitude': '$longitude',
              'days': '5',
            }),
            headers: _headers,
          ),
        );
        if (fres.statusCode == 200) {
          final fjson = jsonDecode(utf8.decode(fres.bodyBytes)) as Map<String, dynamic>;
          final days = (fjson['forecast'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
          forecast = days.map((d) {
            DateTime date;
            try {
              date = DateTime.parse(d['date'] as String);
            } catch (_) {
              date = DateTime.now();
            }
            return ForecastDay(
              date: date,
              tempMaxC: _asDouble(d['temperature_max'], fallback: tempC + 2),
              tempMinC: _asDouble(d['temperature_min'], fallback: tempC - 4),
              condition: _normalizeCondition(d['weather_condition'] as String?),
            );
          }).toList();
        }
      } catch (_) {
        // forecast strip is a nice-to-have; current conditions above are
        // still valid and get returned regardless.
      }

      return WeatherData(
        location: resolvedLabel,
        tempC: tempC,
        condition: condition,
        description: description,
        humidityPct: humidityPct,
        windKmh: windKmh,
        forecast: forecast,
      );
    } catch (_) {
      return MockDataService.weatherFor(location);
    }
  }

  /// GET /api/v1/alerts/?city=  -- [region] is really a city/place name
  /// throughout this app (see WeatherProvider.location), matching what the
  /// backend actually expects.
  Future<List<WeatherAlert>> getAlerts(String region) async {
    try {
      final res = await _withRetry(
        () => http.get(
          Uri.parse('$baseUrl/api/v1/alerts/').replace(queryParameters: {'city': region}),
          headers: _headers,
        ),
      );
      if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');

      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final cityLabel = (json['location'] is Map ? (json['location']['city'] as String?) : null) ?? region;

      return (json['alerts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => _alertFromBackendItem(item, regionLabel: cityLabel))
          .toList();
    } catch (_) {
      return MockDataService.alertsFor(region);
    }
  }

  /// GET /api/v1/domain-advisory/?city=&domain=  -- one of "farmer",
  /// "aviation", "marine", "urban" (see backend/app/routers/domain_advisory.py).
  /// Returns the raw advisory lines plus the live weather numbers the
  /// backend based them on, since the persona card wants to show both.
  Future<DomainAdvisoryResult> getDomainAdvisory(String city, String domain) async {
    final res = await _withRetry(
      () => http.get(
        Uri.parse('$baseUrl/api/v1/domain-advisory/').replace(queryParameters: {
          'city': city,
          'domain': domain,
        }),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final wd = json['weather_data'] as Map<String, dynamic>? ?? {};

    return DomainAdvisoryResult(
      city: (json['city'] as String?) ?? city,
      domain: (json['domain'] as String?) ?? domain,
      advisories: (json['advisories'] as List<dynamic>? ?? []).whereType<String>().toList(),
      temperatureC: _asDouble(wd['temperature']),
      humidityPct: _asInt(wd['humidity']),
      windKmh: _asDouble(wd['wind_speed']),
      tomorrowRainProbabilityPct: _asInt(wd['tomorrow_rain_probability']),
    );
  }
}

/// Result of a domain-advisory call -- see ApiClient.getDomainAdvisory.
class DomainAdvisoryResult {
  DomainAdvisoryResult({
    required this.city,
    required this.domain,
    required this.advisories,
    required this.temperatureC,
    required this.humidityPct,
    required this.windKmh,
    required this.tomorrowRainProbabilityPct,
  });

  final String city;
  final String domain;
  final List<String> advisories;
  final double temperatureC;
  final int humidityPct;
  final double windKmh;
  final int tomorrowRainProbabilityPct;
}

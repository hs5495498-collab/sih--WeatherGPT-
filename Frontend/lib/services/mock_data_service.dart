import '../models/weather_alert.dart';
import '../models/weather_data.dart';
import 'api_client.dart';

/// Canned, deterministic responses so the app is fully demo-able before
/// Members 5/6 (backend) and 3/4 (ML) have live endpoints wired up, and
/// as a safety net if the venue Wi-Fi drops mid-demo.
class MockDataService {
  static ChatQueryResponse answerFor(String message) {
    final q = message.toLowerCase();

    if (q.contains('cyclone') || q.contains('odisha')) {
      return ChatQueryResponse(
        answer:
            "There's an active cyclone watch for coastal Odisha this week. "
            "Winds may pick up sharply from Thursday evening — fishing "
            "communities should avoid venturing out from Wednesday night.",
        alert: WeatherAlert(
          id: 'cyc-od-01',
          severity: AlertSeverity.high,
          title: 'Cyclone Watch — Coastal Odisha',
          message:
              'Sustained winds 60-80 km/h expected. Avoid coastal travel.',
          region: 'Coastal Odisha',
          issuedAt: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(days: 3)),
        ),
        suggestions: const [
          'What should fishermen do?',
          'Is Bhubaneswar affected?'
        ],
      );
    }

    if (q.contains('patna')) {
      return ChatQueryResponse(
        answer:
            'Patna looks mostly clear tomorrow evening — light clouds, '
            'around 29°C, with only a 10% chance of a passing shower.',
        weather: WeatherData(
          location: 'Patna',
          tempC: 29,
          condition: 'cloudy',
          description: 'Partly cloudy, light breeze',
          humidityPct: 58,
          windKmh: 12,
          forecast: List.generate(
            5,
            (i) => ForecastDay(
              date: DateTime.now().add(Duration(days: i + 1)),
              tempMaxC: 31 - i * 0.5,
              tempMinC: 24 - i * 0.3,
              condition: i.isEven ? 'cloudy' : 'sunny',
            ),
          ),
        ),
        suggestions: const ['Will it rain this weekend?', 'Show 5-day forecast'],
      );
    }

    if (q.contains('rain')) {
      return ChatQueryResponse(
        answer:
            'Moderate rain is likely in your area over the next 6 hours, '
            'tapering off by tonight. Carry an umbrella if you\'re heading out.',
        weather: weatherFor('Your Area', condition: 'rainy'),
        suggestions: const ['Any alerts nearby?', 'What about tomorrow?'],
      );
    }

    return ChatQueryResponse(
      answer:
          "I can help with forecasts, severe-weather alerts, and climate "
          "info for any location in India — try asking about a city or a "
          "region.",
      suggestions: const [
        'Will it rain in Patna tomorrow evening?',
        'Is there a cyclone alert for coastal Odisha?',
        'What\'s the weather in Mumbai right now?',
      ],
    );
  }

  static WeatherData weatherFor(String location, {String condition = 'sunny'}) {
    return WeatherData(
      location: location,
      tempC: condition == 'rainy' ? 24 : 32,
      condition: condition,
      description: condition == 'rainy'
          ? 'Moderate rain, gusty winds'
          : 'Clear skies, comfortable',
      humidityPct: condition == 'rainy' ? 82 : 45,
      windKmh: condition == 'rainy' ? 22 : 9,
      forecast: List.generate(
        5,
        (i) => ForecastDay(
          date: DateTime.now().add(Duration(days: i + 1)),
          tempMaxC: 33 - i.toDouble(),
          tempMinC: 24 - i.toDouble() * 0.5,
          condition: ['sunny', 'cloudy', 'rainy', 'sunny', 'cloudy'][i],
        ),
      ),
    );
  }

  static List<WeatherAlert> alertsFor(String region) => [
        WeatherAlert(
          id: 'demo-alert-1',
          severity: AlertSeverity.medium,
          title: 'Heavy Rain Advisory',
          message: 'Isolated heavy showers expected in $region this evening.',
          region: region,
          issuedAt: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(hours: 12)),
        ),
      ];
}

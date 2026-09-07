import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resolves a live precipitation-radar tile URL template using RainViewer's
/// public API -- free, no signup, no API key
/// (https://www.rainviewer.com/api.html). This is the honest alternative
/// to the OpenWeatherMap radar tiles some feature lists assume: those
/// require an OpenWeatherMap API key that isn't configured anywhere in
/// this project, whereas RainViewer's weather-maps.json endpoint and tile
/// server are genuinely public.
///
/// RainViewer refreshes its tile set roughly every 10 minutes, so this is
/// re-fetched each time the map screen opens rather than cached long-term.
class RadarTileService {
  static const _mapsEndpoint = 'https://api.rainviewer.com/public/weather-maps.json';

  /// Returns a flutter_map-compatible URL template (with {z}/{x}/{y}
  /// placeholders) for the most recent radar frame, or null if RainViewer
  /// is unreachable -- callers should hide the radar layer entirely rather
  /// than show a broken/blank one when this returns null.
  Future<RadarFrame?> getLatestFrame() async {
    try {
      final res = await http.get(Uri.parse(_mapsEndpoint)).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final host = data['host'] as String?;
      final radar = data['radar'] as Map<String, dynamic>?;
      final past = radar?['past'] as List<dynamic>?;
      if (host == null || past == null || past.isEmpty) return null;

      final latest = past.last as Map<String, dynamic>;
      final path = latest['path'] as String?;
      final time = latest['time'] as int?;
      if (path == null) return null;

      // size=256px tiles, color scheme 2 (universal blue-to-red), options
      // "1_1" = smooth + show snow separately -- RainViewer's documented
      // defaults for a general-purpose precipitation view.
      final urlTemplate = '$host$path/256/{z}/{x}/{y}/2/1_1.png';

      return RadarFrame(
        urlTemplate: urlTemplate,
        observedAt: time != null ? DateTime.fromMillisecondsSinceEpoch(time * 1000, isUtc: true) : null,
      );
    } catch (_) {
      return null;
    }
  }
}

class RadarFrame {
  const RadarFrame({required this.urlTemplate, this.observedAt});
  final String urlTemplate;
  final DateTime? observedAt;
}

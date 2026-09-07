import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodeResult {
  const GeocodeResult({required this.displayName, required this.lat, required this.lon});
  final String displayName;
  final double lat;
  final double lon;
}

/// Free-text place search using OpenStreetMap's Nominatim -- public, no API
/// key. Nominatim's usage policy requires a real identifying User-Agent
/// (not a browser-spoofing one) and asks callers not to hammer it, so this
/// sends an app-identifying header and is only ever called on explicit
/// user search, never polled automatically.
/// https://operations.osmfoundation.org/policies/nominatim/
class GeocodingService {
  static const _endpoint = 'https://nominatim.openstreetmap.org/search';
  static const _reverseEndpoint = 'https://nominatim.openstreetmap.org/reverse';

  Future<List<GeocodeResult>> search(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final uri = Uri.parse(_endpoint).replace(queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'in', // this app is India-focused; drop this line to search globally
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'WeatherGPT-SIH26068/1.0 (weather radar location search)'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return const [];

      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) {
            final lat = double.tryParse(m['lat']?.toString() ?? '');
            final lon = double.tryParse(m['lon']?.toString() ?? '');
            final name = m['display_name'] as String?;
            if (lat == null || lon == null || name == null) return null;
            return GeocodeResult(displayName: name, lat: lat, lon: lon);
          })
          .whereType<GeocodeResult>()
          .toList();
    } catch (_) {
      return const []; // search failing just means an empty results list, never a crash
    }
  }

  /// Resolves GPS coordinates to a short, human-readable place name (e.g.
  /// "Connaught Place" or "Patna"), for display and for anything that
  /// needs a *name* rather than coordinates -- notably the backend's
  /// GET /api/v1/alerts/?city= and /api/v1/domain-advisory/?city=, which
  /// only accept a name and geocode it themselves server-side (see
  /// backend/app/services/location_service.py). Passing a raw "lat,lon"
  /// string to those as the city name silently fails to resolve and the
  /// caller falls back to mock data -- see WeatherProvider for where this
  /// result is actually used.
  ///
  /// Returns null on any failure (offline, rate-limited, unparsable) so
  /// callers can fall back to the raw coordinate string.
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(_reverseEndpoint).replace(queryParameters: {
        'lat': '$lat',
        'lon': '$lon',
        'format': 'jsonv2',
        'zoom': '10', // city/town level, not house-number precision
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'WeatherGPT-SIH26068/1.0 (weather radar location search)'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final address = body['address'] as Map<String, dynamic>?;

      // Prefer the most specific place-ish field available; these are the
      // fields Nominatim actually populates for this zoom level, checked
      // most-specific first.
      final name = (address?['city'] as String?) ??
          (address?['town'] as String?) ??
          (address?['village'] as String?) ??
          (address?['county'] as String?) ??
          (address?['state'] as String?) ??
          (body['display_name'] as String?)?.split(',').first.trim();

      return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
    } catch (_) {
      return null; // reverse-geocoding is best-effort; caller falls back to coordinates
    }
  }
}

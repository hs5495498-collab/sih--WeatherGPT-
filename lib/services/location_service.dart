import 'package:geolocator/geolocator.dart';

/// Auto-detects the user's approximate location for weather lookups.
/// Every failure mode (permission denied, GPS off, plugin error, platform
/// unsupported) falls back to null so callers can use a sensible default
/// city — location access is a nice-to-have here, never a blocker.
class LocationService {
  Future<({double lat, double lon})?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return (lat: position.latitude, lon: position.longitude);
    } catch (_) {
      return null;
    }
  }
}

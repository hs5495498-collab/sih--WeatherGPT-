import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import '../models/weather_alert.dart';
import '../models/weather_data.dart';
import '../services/api_client.dart';
import '../services/cache_service.dart';
import '../services/demo_mode_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/mock_data_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({
    ApiClient? apiClient,
    LocationService? locationService,
    CacheService? cacheService,
    GeocodingService? geocodingService,
  })  : _api = apiClient ?? ApiClient(),
        _locationService = locationService ?? LocationService(),
        _cache = cacheService ?? CacheService(),
        _geocoding = geocodingService ?? GeocodingService() {
    _init();
  }

  final ApiClient _api;
  final LocationService _locationService;
  final CacheService _cache;
  final GeocodingService _geocoding;

  WeatherData? current;
  List<WeatherAlert> alerts = [];
  bool isLoading = false;
  bool isShowingCachedData = false;
  DateTime? cacheTimestamp;
  String location = 'New Delhi';

  // Set only when [location] is a "<lat>,<lon>" GPS string, via best-effort
  // reverse geocoding. The backend's alert/domain-advisory endpoints only
  // accept a place *name* and geocode it themselves (see
  // backend/app/services/location_service.py) -- sending them the raw
  // coordinate string never resolves, so those calls need this label
  // instead of [location]. Null whenever [location] is already a
  // human-typed city name (no reverse geocoding needed) or when reverse
  // geocoding failed/hasn't completed yet, in which case callers fall
  // back to [location] as before.
  String? _resolvedLabel;

  /// A human-readable label for [location] -- the actual city/place name
  /// when GPS-derived, or [location] itself when it's already a typed
  /// city name. Use this (not [location]) for anything shown to the user
  /// or sent to a backend endpoint that expects a city name.
  String get displayLocation => _resolvedLabel ?? location;

  Future<void> _init() async {
    // Try to auto-detect an approximate location first; fall back to the
    // default silently if permission is denied or GPS is off — location
    // is a convenience here, never a blocker for using the app.
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      location = '${position.lat.toStringAsFixed(2)},${position.lon.toStringAsFixed(2)}';
      // Best-effort: resolve a real place name for display and for the
      // city-only backend endpoints (alerts, domain advisory). Failure
      // just leaves _resolvedLabel null -- displayLocation then falls
      // back to the coordinate string, same as before this existed.
      _resolvedLabel = await _geocoding.reverseGeocode(position.lat, position.lon);
    }
    await refresh();
  }

  Future<void> refresh({String? newLocation}) async {
    if (newLocation != null) {
      location = newLocation;
      // A caller-supplied location is a typed city name (e.g. from the
      // search screens), not GPS coordinates -- it's already display-safe
      // and already what the alert/advisory endpoints expect, so any
      // previously-resolved GPS label no longer applies.
      _resolvedLabel = null;
    }
    isLoading = true;
    notifyListeners();

    if (DemoModeService.instance.enabled) {
      // Deliberately bypasses the network entirely — see DemoModeService's
      // doc for why this exists and what it does NOT do (no error hiding).
      await Future.delayed(const Duration(milliseconds: 400)); // keeps the loading state feeling real
      current = MockDataService.weatherFor(location);
      alerts = MockDataService.alertsFor(location);
      isShowingCachedData = false;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final results = await Future.wait([
        _api.getCurrentWeather(location, displayLabel: _resolvedLabel),
        // Alerts only understand place names, not "<lat>,<lon>" -- use the
        // reverse-geocoded label when we have one (see displayLocation).
        _api.getAlerts(displayLocation),
      ]);
      current = results[0] as WeatherData;
      alerts = results[1] as List<WeatherAlert>;
      isShowingCachedData = false;

      // Best-effort cache write for offline fallback.
      unawaited(_cache.saveWeather(current!));
      unawaited(_cache.saveAlerts(alerts));
    } catch (_) {
      // Live fetch failed entirely (including mock fallback somehow
      // failing) — fall back to the last cached snapshot rather than
      // showing an empty dashboard.
      final (cachedWeather, ts) = await _cache.loadWeather();
      final cachedAlerts = await _cache.loadAlerts();
      if (cachedWeather != null) {
        current = cachedWeather;
        alerts = cachedAlerts;
        isShowingCachedData = true;
        cacheTimestamp = ts;
      }
    }

    isLoading = false;
    notifyListeners();
  }
}

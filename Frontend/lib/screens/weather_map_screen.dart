import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/radar_tile_service.dart';
import '../theme/app_theme.dart';

class WeatherMapScreen extends StatefulWidget {
  const WeatherMapScreen({super.key});

  @override
  State<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen> {
  final _mapController = MapController();
  final _geocoding = GeocodingService();
  final _radar = RadarTileService();
  final _location = LocationService();
  final _searchController = TextEditingController();

  LatLng _center = const LatLng(28.6139, 77.2090); // New Delhi -- matches the app's default city
  LatLng? _userLocation;
  RadarFrame? _radarFrame;
  bool _radarOn = true;
  bool _loadingRadar = true;
  List<GeocodeResult> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadRadar();
    _findMe();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRadar() async {
    final frame = await _radar.getLatestFrame();
    if (!mounted) return;
    setState(() {
      _radarFrame = frame;
      _loadingRadar = false;
    });
  }

  Future<void> _findMe() async {
    final pos = await _location.getCurrentPosition();
    if (!mounted || pos == null) return;
    final latLng = LatLng(pos.lat, pos.lon);
    setState(() {
      _userLocation = latLng;
      _center = latLng;
    });
    _mapController.move(latLng, 10);
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final results = await _geocoding.search(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  void _flyTo(GeocodeResult result) {
    final latLng = LatLng(result.lat, result.lon);
    _mapController.move(latLng, 10);
    setState(() {
      _center = latLng;
      _searchResults = [];
      _searchController.text = result.displayName.split(',').first;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _center, initialZoom: 6),
            children: [
              // OpenStreetMap base tiles -- free, no key, standard attribution required (see below).
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.weathergpt.sih26068',
              ),
              if (_radarOn && _radarFrame != null)
                Opacity(
                  opacity: 0.65,
                  child: TileLayer(urlTemplate: _radarFrame!.urlTemplate),
                ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location_rounded, color: AppColors.navyDeep, size: 30),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
                  const TextSourceAttribution('Radar: RainViewer.com'),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(context).pop()),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(hintText: 'Search a place...', border: InputBorder.none),
                            onChanged: _search,
                          ),
                        ),
                        if (_searching) const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                        IconButton(icon: const Icon(Icons.my_location_rounded), onPressed: _findMe),
                      ],
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, i) {
                          final r = _searchResults[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, size: 20),
                            title: Text(r.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                            onTap: () => _flyTo(r),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)]),
              child: Row(
                children: [
                  Icon(Icons.water_drop_rounded, size: 18, color: _radarOn ? AppColors.rainTeal : AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loadingRadar
                          ? 'Loading radar...'
                          : _radarFrame == null
                              ? 'Radar unavailable right now'
                              : _radarFrame!.observedAt != null
                                  ? 'Precipitation radar \u2022 ${DateFormat.jm().format(_radarFrame!.observedAt!.toLocal())}'
                                  : 'Precipitation radar',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  Switch(
                    value: _radarOn,
                    activeColor: AppColors.gold,
                    onChanged: _radarFrame == null ? null : (v) => setState(() => _radarOn = v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

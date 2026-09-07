import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../services/analytics_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class _Persona {
  const _Persona({required this.domain, required this.label, required this.icon});
  final String domain; // matches backend's domain query param exactly
  final String label;
  final IconData icon;
}

const _personas = [
  _Persona(domain: 'farmer', label: 'Farmer', icon: Icons.grass_rounded),
  _Persona(domain: 'marine', label: 'Fisherman', icon: Icons.sailing_rounded),
  _Persona(domain: 'aviation', label: 'Aviation', icon: Icons.flight_rounded),
  _Persona(domain: 'urban', label: 'Citizen', icon: Icons.person_rounded),
];

/// Surfaces a real backend feature that had no UI at all: GET
/// /api/v1/domain-advisory/?city=&domain= (see
/// backend/app/routers/domain_advisory.py) already generates deterministic,
/// weather-grounded advisories for farmer/marine/aviation/urban personas --
/// this screen is just the missing front door to it.
class PersonaAdvisoryScreen extends StatefulWidget {
  const PersonaAdvisoryScreen({super.key});

  @override
  State<PersonaAdvisoryScreen> createState() => _PersonaAdvisoryScreenState();
}

class _PersonaAdvisoryScreenState extends State<PersonaAdvisoryScreen> {
  final _api = ApiClient();
  String _domain = 'farmer';
  late final TextEditingController _cityController;
  DomainAdvisoryResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: context.read<WeatherProvider>().displayLocation);
    _fetch();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getDomainAdvisory(city, _domain);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
      unawaited(AnalyticsService.instance.recordAdvisoryViewed(_domain));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't reach the advisory service for \"$city\" — check the city name and your connection.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persona Advisory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_on_outlined)),
                    onSubmitted: (_) => _fetch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _fetch, icon: const Icon(Icons.search_rounded)),
              ],
            ),
          ),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _personas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final p = _personas[i];
                final selected = p.domain == _domain;
                return GestureDetector(
                  onTap: () {
                    setState(() => _domain = p.domain);
                    _fetch();
                  },
                  child: Container(
                    width: 78,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.navyDeep : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? AppColors.navyDeep : AppColors.slateLight.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.icon, color: selected ? AppColors.gold : AppColors.navyDeep, size: 26),
                        const SizedBox(height: 6),
                        Text(p.label, style: TextStyle(fontSize: 11.5, color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : _result == null
                        ? const SizedBox.shrink()
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppColors.navyDeep, borderRadius: BorderRadius.circular(18)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_result!.city, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_result!.temperatureC.round()}°C \u00b7 ${_result!.humidityPct}% humidity \u00b7 ${_result!.windKmh.round()} km/h wind',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text('${_result!.tomorrowRainProbabilityPct}%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                        const Text('rain tmrw', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Advisory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold)),
                              const SizedBox(height: 8),
                              ..._result!.advisories.map((a) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.slateLight.withOpacity(0.25))),
                                    child: Text(a, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                                  )),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

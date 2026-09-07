import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_alert.dart';
import '../providers/weather_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_banner.dart';

/// Full-screen alerts view. Unlike the dashboard's "Active alerts" section
/// (which only ever shows alerts for WeatherProvider.location), this lets
/// the user check alerts for any city and filter by severity.
///
/// Deliberately NOT hardcoded sample data: every alert shown here comes
/// from the real GET /api/v1/alerts/?city= endpoint (see
/// backend/app/routers/alerts.py), which generates alerts from live
/// weather + risk scoring, not a canned list. If the wishlist doc's
/// "10-15 hardcoded sample alerts for demo" is still wanted for a judge
/// demo where live weather might not cooperate, that's a separate,
/// explicit ask -- this screen won't quietly fabricate danger data.
///
/// "Category" filtering: the backend's Alert model doesn't have a
/// category field (only severity + free-text title/message), so rather
/// than invent a fake taxonomy, filtering here is by severity, which is
/// the one dimension that's actually real.
class AlertsDashboardScreen extends StatefulWidget {
  const AlertsDashboardScreen({super.key});

  @override
  State<AlertsDashboardScreen> createState() => _AlertsDashboardScreenState();
}

class _AlertsDashboardScreenState extends State<AlertsDashboardScreen> {
  final _api = ApiClient();
  late final TextEditingController _cityController;
  List<WeatherAlert>? _cityAlerts; // null = "showing current location's alerts from WeatherProvider"
  bool _loading = false;
  String? _error;
  AlertSeverity? _severityFilter;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: context.read<WeatherProvider>().displayLocation);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _searchCity() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final alerts = await _api.getAlerts(city);
      if (!mounted) return;
      setState(() => _cityAlerts = alerts);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Couldn't fetch alerts for '$city'. Check the spelling or your connection.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WeatherAlert> _applyFilter(List<WeatherAlert> alerts) {
    if (_severityFilter == null) return alerts;
    return alerts.where((a) => a.severity == _severityFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    // Use the searched city's alerts once a search has happened; otherwise
    // fall back to whatever WeatherProvider already has for the current
    // location (no duplicate network call on first open).
    final sourceAlerts = _cityAlerts ?? weather.alerts;
    final alerts = _applyFilter(sourceAlerts);

    final counts = <AlertSeverity, int>{
      for (final s in AlertSeverity.values) s: sourceAlerts.where((a) => a.severity == s).length,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Alerts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Check alerts for a city…',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _searchCity(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _searchCity,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Check'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All (${sourceAlerts.length})',
                  selected: _severityFilter == null,
                  onTap: () => setState(() => _severityFilter = null),
                ),
                const SizedBox(width: 8),
                for (final s in [AlertSeverity.severe, AlertSeverity.high, AlertSeverity.medium, AlertSeverity.low])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: '${_severityLabel(s)} (${counts[s]})',
                      color: _severityColor(s),
                      selected: _severityFilter == s,
                      onTap: () => setState(() => _severityFilter = s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_error!, style: const TextStyle(color: AppColors.alertRed, fontSize: 12.5)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_cityAlerts != null) {
                  await _searchCity();
                } else {
                  await weather.refresh();
                }
              },
              child: alerts.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: const [
                        SizedBox(height: 60),
                        Icon(Icons.verified_outlined, size: 40, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'No alerts match this filter right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: alerts.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AlertBanner(alert: alerts[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _severityLabel(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.severe:
        return 'Severe';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.medium:
        return 'Moderate';
      case AlertSeverity.low:
        return 'Advisory';
    }
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.severe:
      case AlertSeverity.high:
        return AppColors.alertRed;
      case AlertSeverity.medium:
        return AppColors.alertAmber;
      case AlertSeverity.low:
        return AppColors.alertGreen;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.gold;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withOpacity(0.18),
      labelStyle: TextStyle(color: selected ? chipColor : AppColors.textSecondary),
      side: BorderSide(color: selected ? chipColor.withOpacity(0.5) : Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

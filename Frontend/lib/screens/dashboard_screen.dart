import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/weather_theme_provider.dart';
import '../services/demo_mode_service.dart';
import '../theme/app_theme.dart';
import '../theme/weather_theme_spec.dart';
import 'alerts_dashboard_screen.dart';
import '../widgets/alert_banner.dart';
import '../widgets/app_logo.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/dynamic_weather_theme.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/weather_hero_card.dart';
import '../widgets/weather_particles.dart';
import 'app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weather, _) {
        final condition = weather.current?.condition ?? 'default';

        // NOTE: both tabs share one WeatherThemeProvider, so whichever tab's
        // provider last updated "wins" the app-wide mood. For a 2-tab demo
        // app this reads naturally (the mood reflects whatever weather was
        // most recently looked at); if this grows past 2 tabs, gate this by
        // "is this tab currently visible" instead.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<WeatherThemeProvider>().setCondition(condition),
        );

        return Consumer<WeatherThemeProvider>(
          builder: (context, themeProvider, _) {
            return DynamicWeatherTheme(
              spec: themeProvider.spec,
              builder: (context, spec) => _DashboardScaffold(spec: spec, weather: weather),
            );
          },
        );
      },
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({required this.spec, required this.weather});

  final WeatherThemeSpec spec;
  final WeatherProvider weather;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: spec.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: spec.backgroundGradient.last,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: InkWell(
            onTap: () => context.read<NavigationProvider>().goHome(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(size: 20, color: spec.textPrimary, accentColor: spec.accent),
                  const SizedBox(width: 8),
                  Text('Dashboard', style: TextStyle(color: spec.textPrimary)),
                ],
              ),
            ),
          ),
          iconTheme: IconThemeData(color: spec.textPrimary),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: spec.backgroundGradient,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: WeatherParticleField(condition: spec.name, opacity: 0.4, tint: spec.particleTint),
              ),
              if (weather.isLoading && weather.current == null)
                const DashboardSkeleton()
              else
                Column(
                  children: [
                    const ConnectivityBanner(),
                    Consumer<DemoModeService>(
                      builder: (context, demo, _) => demo.enabled
                          ? Container(
                              width: double.infinity,
                              color: AppColors.gold,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: const Center(
                                child: Text(
                                  'DEMO MODE — showing sample data, not live weather',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (weather.isShowingCachedData)
                      _CachedDataNotice(timestamp: weather.cacheTimestamp, spec: spec),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => weather.refresh(),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text('Current location', style: TextStyle(color: spec.textSecondary, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              weather.location,
                              style: TextStyle(color: spec.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 14),
                            if (weather.current != null) WeatherHeroCard(data: weather.current!),
                            const SizedBox(height: 22),
                            if (weather.alerts.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Active alerts',
                                    style: TextStyle(
                                        color: spec.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const AlertsDashboardScreen()),
                                    ),
                                    child: const Text('View all', style: TextStyle(fontSize: 12.5)),
                                  ),
                                ],
                              ).animate().fadeIn(),
                              const SizedBox(height: 10),
                              ...weather.alerts.map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AlertBanner(alert: a),
                                ),
                              ),
                            ] else
                              _NoAlertsCard(spec: spec),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CachedDataNotice extends StatelessWidget {
  const _CachedDataNotice({this.timestamp, required this.spec});

  final DateTime? timestamp;
  final WeatherThemeSpec spec;

  @override
  Widget build(BuildContext context) {
    final label = timestamp != null
        ? 'Last updated ${DateFormat.jm().format(timestamp!)}'
        : 'Last known data';
    return Container(
      width: double.infinity,
      color: spec.textSecondary.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          '⚠ Showing cached data — $label',
          style: TextStyle(fontSize: 11.5, color: spec.textPrimary),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _NoAlertsCard extends StatelessWidget {
  const _NoAlertsCard({required this.spec});

  final WeatherThemeSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: spec.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: spec.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: spec.accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.verified_outlined, color: spec.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All clear — no active severe-weather alerts for your area right now.',
              style: TextStyle(color: spec.textPrimary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

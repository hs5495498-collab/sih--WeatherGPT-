import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/weather_theme_spec.dart';
import '../widgets/app_logo.dart';
import '../widgets/scroll_reveal.dart';
import '../widgets/weather_mascot.dart';
import '../widgets/weather_particles.dart';

class _Feature {
  const _Feature({
    required this.title,
    required this.body,
    required this.icon,
    required this.condition,
  });

  final String title;
  final String body;
  final IconData icon;
  final String condition;
}

const _features = [
  _Feature(
    title: 'Ask anything, any way',
    body: 'A trained NLU model understands weather questions in any phrasing — '
        '8 Indian languages plus English, typed or spoken — not a fixed list of buttons.',
    icon: Icons.chat_bubble_rounded,
    condition: 'sunny',
  ),
  _Feature(
    title: 'Severe weather, taken seriously',
    body: 'Clear, timely alerts for cyclones, floods, and storms — with a screen '
        'that turns genuinely dark and urgent, not just a red banner.',
    icon: Icons.warning_rounded,
    condition: 'storm',
  ),
  _Feature(
    title: 'See the sky, know the weather',
    body: 'Snap a photo and an on-device model classifies the condition instantly — '
        'works even with zero connectivity.',
    icon: Icons.camera_alt_rounded,
    condition: 'cloudy',
  ),
  _Feature(
    title: 'Built for how India actually looks',
    body: 'Haze, dust storms, cold snaps, monsoon downpours — the app\'s entire '
        'mood shifts to match, not just a generic "weather app" skin.',
    icon: Icons.palette_rounded,
    condition: 'dusty',
  ),
  _Feature(
    title: 'Works when the network doesn\'t',
    body: 'Offline caching, on-device photo classification, and graceful '
        'fallbacks — because disaster alerts matter most exactly when '
        'connectivity is worst.',
    icon: Icons.wifi_off_rounded,
    condition: 'windy',
  ),
];

/// A scrolling showcase page — built to double as a demo-day walkthrough:
/// each section uses a different WeatherThemeSpec as its backdrop, so
/// scrolling through it literally demonstrates the dynamic theming system
/// while explaining what the app does.
class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: WeatherThemeSpec.forCondition('default').backgroundGradient.first,
            leading: const BackButton(color: Colors.white),
            expandedHeight: 320,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroSection(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _FeatureSection(feature: _features[i], index: i),
              childCount: _features.length,
            ),
          ),
          const SliverToBoxAdapter(child: _AboutSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(28, 44, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About WeatherGPT', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          const Text(
            'WeatherGPT is a conversational weather assistant built for Smart India '
            'Hackathon 2026, addressing Problem Statement SIH26068 under the Ministry '
            'of Earth Sciences\' Disaster Management theme. The goal is straightforward: '
            'weather and severe-alert information that ordinary citizens can actually '
            'understand and act on — in plain language, in more than one language, and '
            'without requiring a stable internet connection at the exact moment it '
            'matters most.',
            style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Text('How it works', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const _TechRow(
            label: 'Language understanding',
            detail: 'A custom-trained joint intent and slot-extraction model interprets '
                'questions in any phrasing — not a fixed list of buttons — and identifies '
                'location, timing, and what\'s actually being asked.',
          ),
          const _TechRow(
            label: 'Grounded answers',
            detail: 'Responses are generated only from real, freshly-fetched weather data '
                '— the system is deliberately constrained not to invent numbers it wasn\'t '
                'given, which matters a great deal for anything alert-adjacent.',
          ),
          const _TechRow(
            label: 'Vision',
            detail: 'A separately trained image classifier reads sky/weather photos '
                'on-device, working even with no network connection.',
          ),
          const _TechRow(
            label: 'Honest boundaries',
            detail: 'The assistant is scoped to weather — questions outside that scope '
                'are declined clearly rather than answered with a confident guess.',
          ),
          const SizedBox(height: 24),
          Text('A note on scope', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Text(
            'This is a hackathon-stage prototype. Weather data comes from Open-Meteo '
            '(a free, public forecast service) rather than a direct government feed, '
            'and severe-weather alerts are generated from threshold rules on that data '
            'rather than an official NDMA/IMD bulletin integration. Both are documented '
            'design decisions made for a working, honest first version — not gaps we\'re '
            'trying to hide.',
            style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Built for SIH26068 · Ministry of Earth Sciences',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  const _TechRow({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '$label — ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: detail, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spec = WeatherThemeSpec.forCondition('default');
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: spec.backgroundGradient,
            ),
          ),
        ),
        WeatherParticleField(condition: 'cloudy', opacity: 0.4, tint: Colors.white),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 64),
              const SizedBox(height: 18),
              const Text(
                'WeatherGPT',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Weather that speaks your language —\nliterally and visually.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.feature, required this.index});

  final _Feature feature;
  final int index;

  @override
  Widget build(BuildContext context) {
    final spec = WeatherThemeSpec.forCondition(feature.condition);
    final textColor = spec.isDark ? Colors.white : spec.textPrimary;
    final secondaryColor = spec.isDark ? Colors.white70 : spec.textSecondary;
    final reversed = index.isOdd;

    return Container(
      constraints: const BoxConstraints(minHeight: 340),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: spec.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: WeatherParticleField(condition: feature.condition, opacity: 0.5, tint: spec.particleTint),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ScrollRevealSection(
              slideFrom: Offset(reversed ? 0.15 : -0.15, 0),
              child: Row(
                textDirection: reversed ? TextDirection.rtl : TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: spec.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: spec.cardBorder, width: 1.5),
                    ),
                    child: Icon(feature.icon, size: 34, color: spec.accent),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature.body,
                          style: TextStyle(color: secondaryColor, fontSize: 13.5, height: 1.45),
                        ),
                      ],
                    ),
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

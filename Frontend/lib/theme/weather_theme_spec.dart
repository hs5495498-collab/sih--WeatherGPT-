import 'package:flutter/material.dart';

/// A complete visual mood for one weather condition — restrained and
/// professional, not candy-bright: muted tones, a single accent per
/// condition, careful contrast. This is the core of "the app's mood
/// changes with real weather" without reading as a toy.
class WeatherThemeSpec {
  const WeatherThemeSpec({
    required this.name,
    required this.backgroundGradient,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.cardBorder,
    required this.accent,
    required this.particleTint,
    required this.isDark,
  });

  final String name;
  final List<Color> backgroundGradient;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color cardBorder;
  final Color accent;
  final Color particleTint;
  final bool isDark;

  Brightness get statusBarIconBrightness => isDark ? Brightness.light : Brightness.dark;

  static WeatherThemeSpec lerp(WeatherThemeSpec a, WeatherThemeSpec b, double t) {
    List<Color> lerpGradient(List<Color> ga, List<Color> gb) {
      final len = ga.length > gb.length ? ga.length : gb.length;
      return List.generate(len, (i) {
        final ca = ga[i % ga.length];
        final cb = gb[i % gb.length];
        return Color.lerp(ca, cb, t)!;
      });
    }

    return WeatherThemeSpec(
      name: t < 0.5 ? a.name : b.name,
      backgroundGradient: lerpGradient(a.backgroundGradient, b.backgroundGradient),
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      cardColor: Color.lerp(a.cardColor, b.cardColor, t)!,
      cardBorder: Color.lerp(a.cardBorder, b.cardBorder, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      particleTint: Color.lerp(a.particleTint, b.particleTint, t)!,
      isDark: t < 0.5 ? a.isDark : b.isDark,
    );
  }

  static WeatherThemeSpec forCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return const WeatherThemeSpec(
          name: 'sunny',
          backgroundGradient: [Color(0xFFEDE0C8), Color(0xFFDBC298), Color(0xFFC9A876)],
          textPrimary: Color(0xFF33291A),
          textSecondary: Color(0xFF6B5B3F),
          cardColor: Colors.white,
          cardBorder: Color(0xFFDFC9A0),
          accent: Color(0xFF9C7A3F),
          particleTint: Color(0xFFF3E9D2),
          isDark: false,
        );

      case 'rainy':
      case 'rain':
        return const WeatherThemeSpec(
          name: 'rainy',
          backgroundGradient: [Color(0xFF1B2733), Color(0xFF283A48), Color(0xFF3A4E5E)],
          textPrimary: Colors.white,
          textSecondary: Color(0xFFAEBDC9),
          cardColor: Color(0xFF24333F),
          cardBorder: Color(0xFF445A69),
          accent: Color(0xFF7FA7B8),
          particleTint: Colors.white70,
          isDark: true,
        );

      case 'storm':
      case 'thunderstorm':
        return const WeatherThemeSpec(
          name: 'storm',
          backgroundGradient: [Color(0xFF07090D), Color(0xFF161C24), Color(0xFF232B36)],
          textPrimary: Colors.white,
          textSecondary: Color(0xFF97A0AD),
          cardColor: Color(0xFF161C24),
          cardBorder: Color(0xFF39424F),
          accent: Color(0xFFC9A876), // muted gold, not cartoon yellow — reads as urgent+serious, not playful
          particleTint: Colors.white70,
          isDark: true,
        );

      case 'snow':
        return const WeatherThemeSpec(
          name: 'snow',
          backgroundGradient: [Color(0xFFE9EEF1), Color(0xFFD3DEE5), Color(0xFFB9C6D1)],
          textPrimary: Color(0xFF20303B),
          textSecondary: Color(0xFF5B7181),
          cardColor: Colors.white,
          cardBorder: Color(0xFFCBD8DF),
          accent: Color(0xFF4E7690),
          particleTint: Colors.white,
          isDark: false,
        );

      case 'hazy':
      case 'fogsmog':
      case 'fog':
        return const WeatherThemeSpec(
          name: 'hazy',
          backgroundGradient: [Color(0xFFCFCABE), Color(0xFFB7B1A3), Color(0xFF9C978C)],
          textPrimary: Color(0xFF322F27),
          textSecondary: Color(0xFF615D51),
          cardColor: Color(0xFFEAE6DB),
          cardBorder: Color(0xFFA8A395),
          accent: Color(0xFF756F5D),
          particleTint: Color(0xFFEAE6DB),
          isDark: false,
        );

      case 'dusty':
      case 'sandstorm':
        return const WeatherThemeSpec(
          name: 'dusty',
          backgroundGradient: [Color(0xFFD3B583), Color(0xFFB99860), Color(0xFF95713F)],
          textPrimary: Color(0xFF302113),
          textSecondary: Color(0xFF5C4526),
          cardColor: Color(0xFFEDDCB8),
          cardBorder: Color(0xFFB48F55),
          accent: Color(0xFF7A5325),
          particleTint: Color(0xFFA1794A),
          isDark: false,
        );

      case 'windy':
        return const WeatherThemeSpec(
          name: 'windy',
          backgroundGradient: [Color(0xFFC7D6D2), Color(0xFFA4BAB4), Color(0xFF7D9990)],
          textPrimary: Color(0xFF1B2C27),
          textSecondary: Color(0xFF4A5F58),
          cardColor: Colors.white,
          cardBorder: Color(0xFF9BB8AF),
          accent: Color(0xFF3E6459),
          particleTint: Colors.white,
          isDark: false,
        );

      case 'cloudy':
      case 'clouds':
        return const WeatherThemeSpec(
          name: 'cloudy',
          backgroundGradient: [Color(0xFF9AA6AF), Color(0xFF7C8891), Color(0xFF5B6873)],
          textPrimary: Colors.white,
          textSecondary: Color(0xFFD7DCE0),
          cardColor: Color(0xFF6B7680),
          cardBorder: Color(0xFF8B96A1),
          accent: Color(0xFFD8C0A0),
          particleTint: Colors.white,
          isDark: true,
        );

      default:
        // Neutral identity color before any location's weather is known —
        // the app's own navy/gold brand, not a "weather" color at all.
        return const WeatherThemeSpec(
          name: 'default',
          backgroundGradient: [Color(0xFF0D1B2A), Color(0xFF1B2A3D)],
          textPrimary: Colors.white,
          textSecondary: Color(0xFFAEB9C4),
          cardColor: Color(0xFF1B2A3D),
          cardBorder: Color(0xFF3A4A5E),
          accent: Color(0xFFB8925A),
          particleTint: Colors.white70,
          isDark: true,
        );
    }
  }
}

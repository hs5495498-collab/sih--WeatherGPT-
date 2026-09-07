import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WeatherGPT design tokens — "stoic professional" direction: deep navy and
/// charcoal, a single restrained gold accent, muted (not candy-bright)
/// weather colors. Every screen pulls from here, so this file is the one
/// place that sets the whole app's tone.
class AppColors {
  AppColors._();

  // Brand — deep navy + charcoal, one disciplined gold accent used sparingly
  // (for emphasis/CTAs only, never as a base fill) rather than scattered
  // brights. This is the actual mechanism of "professional" here: fewer,
  // more deliberate colors, not just darker ones.
  static const Color navyDeep = Color(0xFF0D1B2A);
  static const Color navy = Color(0xFF1B2A3D);
  static const Color slate = Color(0xFF3A4A5E);
  static const Color slateLight = Color(0xFF6B7B8F);
  static const Color gold = Color(0xFFB8925A);
  static const Color goldMuted = Color(0xFFD8C0A0);

  // Legacy aliases — kept so widgets written against the old names still
  // compile; all now resolve to the new professional palette.
  static const Color skyBlueDeep = navyDeep;
  static const Color skyBlue = slate;
  static const Color skyBlueLight = slateLight;
  static const Color sunsetOrange = gold;
  static const Color sunsetGold = goldMuted;
  static const Color stormGrey = Color(0xFF2A323C);
  static const Color rainTeal = Color(0xFF4A6670);

  static const Color alertRed = Color(0xFFB3413B);
  static const Color alertAmber = Color(0xFFB8925A);
  static const Color alertGreen = Color(0xFF4A7A63);

  static const Color surface = Color(0xFFF6F5F2); // warm off-white, not clinical white
  static const Color surfaceDark = Color(0xFF10161F);
  static const Color textPrimary = Color(0xFF1A2430);
  static const Color textSecondary = Color(0xFF5C6B7A);
  static const Color botBubble = Colors.white;
  static const Color userBubble = navy;

  /// Gradient chosen by current weather condition — muted, not candy-bright.
  /// Used for the animated backdrop and the dashboard hero card.
  static List<Color> gradientFor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return [const Color(0xFFEDE0C8), const Color(0xFFD8B583)];
      case 'rainy':
      case 'rain':
        return [const Color(0xFF1E2B38), const Color(0xFF3A4E5E)];
      case 'cloudy':
      case 'clouds':
        return [const Color(0xFF5B6873), const Color(0xFF8B96A1)];
      case 'storm':
      case 'thunderstorm':
        return [const Color(0xFF0A0E14), const Color(0xFF232B36)];
      case 'snow':
        return [const Color(0xFFE4EAEE), const Color(0xFFB9C6D1)];
      case 'hazy':
      case 'fogsmog':
      case 'fog':
        return [const Color(0xFFCFCABE), const Color(0xFF9C978C)];
      case 'dusty':
      case 'sandstorm':
        return [const Color(0xFFD3B583), const Color(0xFF95713F)];
      case 'windy':
        return [const Color(0xFFC7D6D2), const Color(0xFF7D9990)];
      default:
        return [AppColors.navyDeep, AppColors.navy];
    }
  }
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base, Color primary, Color secondary) {
    return GoogleFonts.interTextTheme(base).copyWith(
      headlineMedium: GoogleFonts.inter(
        fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: primary,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 14.5, color: primary),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: secondary),
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navyDeep,
        secondary: AppColors.gold,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );
    final textTheme = _textTheme(base.textTheme, AppColors.textPrimary, AppColors.textSecondary);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.navyDeep),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slateLight.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slateLight.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDeep,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.slate,
        brightness: Brightness.dark,
        secondary: AppColors.gold,
        surface: AppColors.surfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
    );
    final textTheme = _textTheme(base.textTheme, Colors.white.withOpacity(0.94), Colors.white60);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.navyDeep),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B2530),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyDeep,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
    );
  }
}

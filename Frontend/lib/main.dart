import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'services/analytics_service.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/weather_theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/demo_mode_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A single uncaught error inside a widget must never take the whole
  // disaster-alert app down silently — log it and let the widget's own
  // error boundary render, instead of a blank/frozen screen.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint(details.exceptionAsString());
  };

  // No-op if SUPABASE_URL/SUPABASE_ANON_KEY weren't supplied via
  // --dart-define — see SupabaseService's doc for why that's fine.
  await SupabaseService.initialize();

  unawaited(AnalyticsService.instance.recordAppOpen());

  runApp(const WeatherGptApp());
}

class WeatherGptApp extends StatelessWidget {
  const WeatherGptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider.value(value: DemoModeService.instance),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'WeatherGPT',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

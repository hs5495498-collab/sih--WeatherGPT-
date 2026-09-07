import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/weather_particles.dart';
import 'auth/login_screen.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Decides where to go after onboarding/splash: if Supabase is configured
/// and nobody's signed in, show the login screen; otherwise straight to the
/// app. Guest mode always works — see SupabaseService's class doc for why
/// auth is additive here, never a hard gate on a disaster-alert tool.
Widget nextScreenAfterOnboarding() {
  final needsLogin = SupabaseService.isConfigured && SupabaseService.client.auth.currentUser == null;
  return needsLogin ? const LoginScreen() : const HomeShell();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            onboardingDone ? nextScreenAfterOnboarding() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navyDeep, AppColors.navy],
              ),
            ),
          ),
          const WeatherParticleField(condition: 'default', opacity: 0.3),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 72)
                    .animate()
                    .scale(duration: 550.ms, curve: Curves.easeOutCubic)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 24),
                const Text(
                  'WeatherGPT',
                  style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ).animate().fadeIn(delay: 250.ms, duration: 450.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 6),
                Text(
                  'Weather intelligence for India',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5, letterSpacing: 0.2),
                ).animate().fadeIn(delay: 480.ms, duration: 450.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

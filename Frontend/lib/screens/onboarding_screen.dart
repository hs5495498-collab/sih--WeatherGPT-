import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/weather_theme_spec.dart';
import '../widgets/bouncy.dart';
import '../widgets/weather_mascot.dart';
import '../widgets/weather_particles.dart';
import 'splash_screen.dart' show nextScreenAfterOnboarding;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.mascotExpression,
    required this.condition,
  });

  final String title;
  final String body;
  final MascotExpression mascotExpression;
  final String condition;
}

const _pages = [
  _OnboardingPage(
    title: "Meet WeatherGPT",
    body: "Ask about weather anywhere in India, in your own language — no menus, no guesswork.",
    mascotExpression: MascotExpression.happy,
    condition: 'sunny',
  ),
  _OnboardingPage(
    title: "Stay ahead of severe weather",
    body: "Get clear, timely alerts for cyclones, floods, and storms before they reach you.",
    mascotExpression: MascotExpression.alert,
    condition: 'storm',
  ),
  _OnboardingPage(
    title: "Just ask, however you like",
    body: "Type, speak, or snap a photo of the sky — WeatherGPT understands however you ask.",
    mascotExpression: MascotExpression.thinking,
    condition: 'cloudy',
  ),
  _OnboardingPage(
    title: "A screen that feels the weather",
    body: "Dusty, hazy, windy, or clear — WeatherGPT's whole look shifts to match real conditions, wherever you ask about.",
    mascotExpression: MascotExpression.sleepy,
    condition: 'dusty',
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => nextScreenAfterOnboarding(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    final spec = WeatherThemeSpec.forCondition(page.condition);
    final textColor = spec.isDark ? Colors.white : spec.textPrimary;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: spec.backgroundGradient,
              ),
            ),
          ),
          WeatherParticleField(condition: page.condition, opacity: 0.7, tint: spec.particleTint),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text('Skip', style: TextStyle(color: textColor)),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      final pSpec = WeatherThemeSpec.forCondition(p.condition);
                      final pTextColor = pSpec.isDark ? Colors.white : pSpec.textPrimary;
                      final pSecondaryColor = pSpec.isDark ? Colors.white70 : pSpec.textSecondary;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            WeatherMascot(size: 130, expression: p.mascotExpression)
                                .animate()
                                .scale(duration: 500.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 36),
                            Text(
                              p.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: pTextColor, fontSize: 25, fontWeight: FontWeight.w800),
                            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 14),
                            Text(
                              p.body,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: pSecondaryColor, fontSize: 15, height: 1.4),
                            ).animate().fadeIn(delay: 280.ms),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(active ? 1 : 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Bouncy(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: spec.isDark ? Colors.white : Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: Text(
                          _page == _pages.length - 1 ? "Get started" : "Next",
                          style: TextStyle(
                            color: spec.isDark ? spec.backgroundGradient.first : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';

/// Owns the PageView between the two main tabs. Tab switching is driven by
/// NavigationProvider (set from the Drawer, or from tapping the "WeatherGPT"
/// title on any screen) rather than a bottom nav bar the shell owned itself —
/// this lets any screen trigger navigation, not just a nav bar widget.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _pageController = PageController();

  // Ensures the persisted language/speech-rate preference is pushed into
  // ChatProvider exactly once per app launch — after that, Settings talks
  // to both providers directly on every change (see settings_screen.dart),
  // so this never needs to run again or fight a live user choice.
  bool _syncedPreferencesOnce = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, AppSettingsProvider>(
      builder: (context, nav, settings, _) {
        // React to external tab-change requests (Drawer taps, title taps)
        // by animating the PageView — but only when it's actually different
        // from where the PageView already is, to avoid fighting a user's
        // own swipe gesture.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients &&
              _pageController.page?.round() != nav.tabIndex) {
            _pageController.animateToPage(
              nav.tabIndex,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
            );
          }

          if (!_syncedPreferencesOnce && settings.isLoaded) {
            _syncedPreferencesOnce = true;
            final chat = context.read<ChatProvider>();
            chat.setLanguage(settings.preferredLanguage);
            chat.setSpeechRate(settings.speechRate);
          }
        });

        return PageView(
          controller: _pageController,
          onPageChanged: (i) => nav.goToTab(i),
          children: const [ChatScreen(), DashboardScreen()],
        );
      },
    );
  }
}

import 'package:flutter/foundation.dart';

/// Single source of truth for "which of the two main tabs (Ask / Dashboard)
/// is active" — lets the Drawer and the tappable "WeatherGPT" title switch
/// tabs from anywhere, not just from a nav bar that owned its own state.
class NavigationProvider extends ChangeNotifier {
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void goToTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  void goHome() => goToTab(0);
}

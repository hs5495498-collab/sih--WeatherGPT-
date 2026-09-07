import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();
    });
    Connectivity().checkConnectivity().then((results) {
      isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  bool isOnline = true;
  StreamSubscription? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

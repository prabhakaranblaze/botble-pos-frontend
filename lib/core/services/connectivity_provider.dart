import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _subscription;

  ConnectivityProvider() {
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

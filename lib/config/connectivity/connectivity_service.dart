import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _initialized = false;

  static bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.every((result) => result == ConnectivityResult.none);
  }

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final results = await _connectivity.checkConnectivity();
    isOnline.value = _hasConnection(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      isOnline.value = _hasConnection(results);
    });
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}

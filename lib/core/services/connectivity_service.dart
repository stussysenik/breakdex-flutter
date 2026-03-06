import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors network connectivity and exposes a broadcast [onlineStream].
///
/// Guarded against platform exceptions — on simulator or when the
/// connectivity plugin fails, the stream emits `false` rather than crashing.
class ConnectivityService {
  final _connectivity = Connectivity();
  late final StreamController<bool> _controller;
  StreamSubscription? _sub;

  ConnectivityService() {
    _controller = StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
  }

  Stream<bool> get onlineStream => _controller.stream;

  void _startListening() {
    try {
      _sub = _connectivity.onConnectivityChanged.listen(
        (results) {
          _controller.add(_isOnline(results));
        },
        onError: (Object e) {
          debugPrint('Connectivity stream error: $e');
          if (!_controller.isClosed) _controller.add(false);
        },
      );
      // Emit current state immediately so StreamProvider exits AsyncLoading.
      // connectivity_plus only fires onConnectivityChanged on *changes*, not on
      // initial subscription — without this, the provider stays loading forever
      // if connectivity never changes (common in release mode).
      checkNow().then((online) {
        if (!_controller.isClosed) _controller.add(online);
      });
    } catch (e) {
      debugPrint('Connectivity listen failed: $e');
      if (!_controller.isClosed) _controller.add(false);
    }
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  Future<bool> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOnline(results);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    }
  }

  void dispose() {
    _stopListening();
    _controller.close();
  }
}

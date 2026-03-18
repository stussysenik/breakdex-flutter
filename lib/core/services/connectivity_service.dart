import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Simplified connection type for sync policy decisions.
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
}

/// Monitors network connectivity and exposes a broadcast [onlineStream].
///
/// Guarded against platform exceptions — on simulator or when the
/// connectivity plugin fails, the stream emits `false` rather than crashing.
class ConnectivityService {
  final _connectivity = Connectivity();
  late final StreamController<bool> _controller;
  late final StreamController<ConnectionType> _typeController;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  ConnectionType _currentType = ConnectionType.none;

  ConnectivityService() {
    _controller = StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    _typeController = StreamController<ConnectionType>.broadcast();
  }

  Stream<bool> get onlineStream => _controller.stream;

  /// Stream of connection type changes (wifi, mobile, ethernet, none).
  Stream<ConnectionType> get connectionTypeStream => _typeController.stream;

  /// Current connection type (last known value).
  ConnectionType get currentType => _currentType;

  void _startListening() {
    try {
      _sub = _connectivity.onConnectivityChanged.listen(
        (results) {
          _controller.add(_isOnline(results));
          final type = _resolveType(results);
          _currentType = type;
          if (!_typeController.isClosed) _typeController.add(type);
        },
        onError: (Object e) {
          debugPrint('Connectivity stream error: $e');
          if (!_controller.isClosed) _controller.add(false);
          _currentType = ConnectionType.none;
          if (!_typeController.isClosed) {
            _typeController.add(ConnectionType.none);
          }
        },
      );
      // Emit current state immediately so StreamProvider exits AsyncLoading.
      // connectivity_plus only fires onConnectivityChanged on *changes*, not on
      // initial subscription — without this, the provider stays loading forever
      // if connectivity never changes (common in release mode).
      checkNow().then((online) {
        if (!_controller.isClosed) _controller.add(online);
      });
      checkType().then((type) {
        _currentType = type;
        if (!_typeController.isClosed) _typeController.add(type);
      });
    } catch (e) {
      debugPrint('Connectivity listen failed: $e');
      if (!_controller.isClosed) _controller.add(false);
      _currentType = ConnectionType.none;
      if (!_typeController.isClosed) {
        _typeController.add(ConnectionType.none);
      }
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

  ConnectionType _resolveType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    }
    return ConnectionType.none;
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

  /// Check and return the current connection type.
  Future<ConnectionType> checkType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final type = _resolveType(results);
      _currentType = type;
      return type;
    } catch (e) {
      debugPrint('Connection type check failed: $e');
      return ConnectionType.none;
    }
  }

  void dispose() {
    _stopListening();
    _controller.close();
    _typeController.close();
  }
}

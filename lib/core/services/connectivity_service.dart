import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Simplified connection type for sync policy decisions.
enum ConnectionType { wifi, mobile, ethernet, none }

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
  bool _online = false;
  int _listenerCount = 0;
  bool _disposed = false;
  bool _hasEmittedOnline = false;
  bool _hasEmittedType = false;

  ConnectivityService() {
    _controller = StreamController<bool>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
    _typeController = StreamController<ConnectionType>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
  }

  Stream<bool> get onlineStream => _controller.stream;

  /// Stream of connection type changes (wifi, mobile, ethernet, none).
  Stream<ConnectionType> get connectionTypeStream => _typeController.stream;

  /// Current connection type (last known value).
  ConnectionType get currentType => _currentType;

  void _onListen() {
    _listenerCount += 1;
    if (_listenerCount == 1) {
      _startListening();
    }
  }

  void _onCancel() {
    if (_listenerCount == 0) return;
    _listenerCount -= 1;
    if (_listenerCount == 0) {
      _stopListening();
    }
  }

  void _startListening() {
    if (_disposed || _sub != null) return;

    try {
      _sub = _connectivity.onConnectivityChanged.listen(
        _handleResults,
        onError: (final Object e) {
          debugPrint('Connectivity stream error: $e');
          _emitState(ConnectionType.none);
        },
      );
      // Emit current state immediately so StreamProvider exits AsyncLoading.
      // connectivity_plus only fires onConnectivityChanged on *changes*, not on
      // initial subscription — without this, the provider stays loading forever
      // if connectivity never changes (common in release mode).
      checkType().then((final type) {
        if (_disposed) return;
        _emitState(type);
      });
    } catch (e) {
      debugPrint('Connectivity listen failed: $e');
      _emitState(ConnectionType.none);
    }
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  void _handleResults(final List<ConnectivityResult> results) {
    _emitState(_resolveType(results));
  }

  void _emitState(final ConnectionType type) {
    final isOnline = type != ConnectionType.none;
    final typeChanged = _currentType != type;
    final onlineChanged = _online != isOnline;
    _currentType = type;
    _online = isOnline;

    if ((_hasEmittedOnline == false || onlineChanged) &&
        !_controller.isClosed) {
      _hasEmittedOnline = true;
      _controller.add(isOnline);
    }
    if ((_hasEmittedType == false || typeChanged) &&
        !_typeController.isClosed) {
      _hasEmittedType = true;
      _typeController.add(type);
    }
  }

  ConnectionType _resolveType(final List<ConnectivityResult> results) {
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
      final type = _resolveType(results);
      _emitState(type);
      return type != ConnectionType.none;
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
      _emitState(type);
      return type;
    } catch (e) {
      debugPrint('Connection type check failed: $e');
      return ConnectionType.none;
    }
  }

  void dispose() {
    _disposed = true;
    _stopListening();
    _controller.close();
    _typeController.close();
  }
}

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

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
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_isOnline(results));
    });
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
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  void dispose() {
    _stopListening();
    _controller.close();
  }
}

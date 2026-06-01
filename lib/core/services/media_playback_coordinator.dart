import 'package:flutter/widgets.dart';

/// Global media-focus arbiter for video/audio playback across the app.
///
/// Only one owner may be primary at a time. Route changes and explicit tab
/// switches can broadcast a pause request so covered media stops immediately.
class MediaPlaybackCoordinator extends ChangeNotifier {
  MediaPlaybackCoordinator();

  static final MediaPlaybackCoordinator shared = MediaPlaybackCoordinator();

  final Map<String, VoidCallback> _pauseHandlers = {};
  String? _primaryOwnerId;
  int _pauseGeneration = 0;
  int _suppressedNavigationPauseCount = 0;

  String? get primaryOwnerId => _primaryOwnerId;
  int get pauseGeneration => _pauseGeneration;

  bool isPrimary(final String ownerId) => _primaryOwnerId == ownerId;

  void suppressNextNavigationPause() {
    _suppressedNavigationPauseCount += 1;
  }

  bool consumeNavigationPauseSuppression() {
    if (_suppressedNavigationPauseCount == 0) return false;
    _suppressedNavigationPauseCount -= 1;
    return true;
  }

  void attach({required final String playbackId, required final VoidCallback onPause}) {
    _pauseHandlers[playbackId] = onPause;
  }

  void detach(final String playbackId) {
    release(playbackId);
    _pauseHandlers.remove(playbackId);
  }

  void claimPrimary(final String ownerId) {
    if (_primaryOwnerId == ownerId) return;
    final previousOwnerId = _primaryOwnerId;
    if (previousOwnerId != null && previousOwnerId != ownerId) {
      _pauseHandlers[previousOwnerId]?.call();
    }
    _primaryOwnerId = ownerId;
    notifyListeners();
  }

  void release(final String ownerId) {
    if (_primaryOwnerId != ownerId) return;
    _primaryOwnerId = null;
    notifyListeners();
  }

  void pauseAll() {
    _primaryOwnerId = null;
    _pauseGeneration += 1;
    final handlers = List<VoidCallback>.from(_pauseHandlers.values);
    for (final handler in handlers) {
      handler();
    }
    notifyListeners();
  }
}

/// Navigator observer that pauses active media when a new route covers it.
class MediaPlaybackNavigationObserver extends NavigatorObserver {
  MediaPlaybackNavigationObserver(this._coordinator);

  final MediaPlaybackCoordinator _coordinator;

  @override
  void didPush(final Route<dynamic> route, final Route<dynamic>? previousRoute) {
    if (_coordinator.consumeNavigationPauseSuppression()) {
      super.didPush(route, previousRoute);
      return;
    }
    _coordinator.pauseAll();
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({
    final Route<dynamic>? newRoute,
    final Route<dynamic>? oldRoute,
  }) {
    if (_coordinator.consumeNavigationPauseSuppression()) {
      super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
      return;
    }
    _coordinator.pauseAll();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(final Route<dynamic> route, final Route<dynamic>? previousRoute) {
    _coordinator.pauseAll();
    super.didRemove(route, previousRoute);
  }

  @override
  void didStartUserGesture(final Route<dynamic> route, final Route<dynamic>? previousRoute) {
    _coordinator.pauseAll();
    super.didStartUserGesture(route, previousRoute);
  }
}

final mediaPlaybackCoordinator = MediaPlaybackCoordinator.shared;

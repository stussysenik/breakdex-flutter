import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';

import 'video_service.dart';

/// Priority-queue thumbnail loader with bounded concurrency.
///
/// Grid views can mount dozens of cells at once, each requesting a thumbnail.
/// Without coordination, all of them hit `VideoThumbnail.thumbnailData`
/// concurrently — saturating the platform channel and causing jank.
///
/// The coordinator caps in-flight loads to [_maxConcurrent] and uses a
/// priority queue so cells closest to the viewport center decode first.
/// Duplicate requests for the same [videoPath] are deduplicated.
class ThumbnailLoadCoordinator {
  ThumbnailLoadCoordinator({VideoService? videoService})
      : _videoService = videoService ?? VideoService();

  static const _maxConcurrent = 3;

  final VideoService _videoService;

  /// Priority queue: lower priority value = more urgent (closer to viewport).
  final _queue = SplayTreeMap<int, _PendingLoad>();

  /// Dedup set of video paths currently being generated.
  final _inFlight = <String, Completer<String?>>{};

  /// Monotonic priority counter — callers with lower values load first.
  int _nextPriority = 0;

  /// Maps videoPath → assigned priority key for cancellation.
  final _pathToPriority = <String, int>{};

  /// Request a thumbnail load. Returns a Future that completes with the
  /// cached thumbnail file path (or null on failure).
  ///
  /// [priority] — lower = more urgent. If omitted, uses an auto-incrementing
  /// counter so later requests have lower priority.
  /// [maxWidth] — resolution tier for the thumbnail.
  Future<String?> enqueue(
    String videoPath, {
    int? priority,
    int maxWidth = 200,
  }) {
    // If already in-flight, piggyback on the existing request.
    final existing = _inFlight[videoPath];
    if (existing != null) return existing.future;

    final key = priority ?? _nextPriority++;
    final completer = Completer<String?>();

    _queue[key] = _PendingLoad(
      videoPath: videoPath,
      maxWidth: maxWidth,
      completer: completer,
    );
    _pathToPriority[videoPath] = key;

    _processQueue();
    return completer.future;
  }

  /// Cancel a pending (not yet started) load by videoPath.
  /// If the load is already in-flight, it cannot be cancelled.
  void cancel(String videoPath) {
    final key = _pathToPriority.remove(videoPath);
    if (key == null) return;
    final pending = _queue.remove(key);
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.complete(null);
    }
  }

  /// Process queued loads up to [_maxConcurrent].
  void _processQueue() {
    while (_inFlight.length < _maxConcurrent && _queue.isNotEmpty) {
      final entry = _queue.entries.first;
      _queue.remove(entry.key);
      final load = entry.value;
      _pathToPriority.remove(load.videoPath);

      final completer = Completer<String?>();
      _inFlight[load.videoPath] = completer;

      _runLoad(load).then((path) {
        _inFlight.remove(load.videoPath);
        if (!completer.isCompleted) completer.complete(path);
        if (!load.completer.isCompleted) load.completer.complete(path);
        _processQueue();
      });
    }
  }

  Future<String?> _runLoad(_PendingLoad load) async {
    try {
      return await _videoService.generateThumbnail(
        load.videoPath,
        maxWidth: load.maxWidth,
      );
    } catch (_) {
      return null;
    }
  }
}

class _PendingLoad {
  const _PendingLoad({
    required this.videoPath,
    required this.maxWidth,
    required this.completer,
  });

  final String videoPath;
  final int maxWidth;
  final Completer<String?> completer;
}

/// InheritedWidget that provides a [ThumbnailLoadCoordinator] to descendants.
///
/// Place above the `CustomScrollView` in the arsenal screen so all grid
/// cells share one coordinator instance with bounded concurrency.
class ThumbnailCoordinatorScope extends InheritedWidget {
  const ThumbnailCoordinatorScope({
    super.key,
    required this.coordinator,
    required super.child,
  });

  final ThumbnailLoadCoordinator coordinator;

  static ThumbnailLoadCoordinator? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThumbnailCoordinatorScope>()
        ?.coordinator;
  }

  @override
  bool updateShouldNotify(ThumbnailCoordinatorScope oldWidget) =>
      coordinator != oldWidget.coordinator;
}

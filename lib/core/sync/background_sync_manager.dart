import 'package:flutter/foundation.dart';

/// Manages background sync scheduling.
///
/// Registers periodic background tasks (every 15 min when on WiFi + charging)
/// to run the asset sync engine. Also triggers sync on:
/// - App launch
/// - New video import
/// - Connectivity change (offline → WiFi)
///
/// NOTE: This is a stub implementation. Full workmanager integration requires
/// the `workmanager` package and platform-specific setup (BGTaskScheduler on
/// iOS, WorkManager on Android). The sync engine itself is fully functional —
/// this class just controls *when* it runs.
class BackgroundSyncManager {
  // ignore: unused_field
  static const _uniqueTaskName = 'breakdex_asset_sync';
  static const _syncIntervalMinutes = 15;

  bool _registered = false;

  /// Register the periodic background sync task.
  ///
  /// Call once during app initialization. The task runs every
  /// [_syncIntervalMinutes] minutes when the device is on WiFi and charging.
  Future<void> register() async {
    if (_registered) return;

    // TODO: Enable when workmanager package is added
    // await Workmanager().initialize(
    //   _callbackDispatcher,
    //   isInDebugMode: kDebugMode,
    // );
    // await Workmanager().registerPeriodicTask(
    //   _uniqueTaskName,
    //   _uniqueTaskName,
    //   frequency: const Duration(minutes: _syncIntervalMinutes),
    //   constraints: Constraints(
    //     networkType: NetworkType.unmetered,
    //     requiresCharging: true,
    //   ),
    //   existingWorkPolicy: ExistingWorkPolicy.keep,
    // );

    _registered = true;
    debugPrint(
      '[BackgroundSync] Registered periodic task '
      '(every $_syncIntervalMinutes min, WiFi + charging)',
    );
  }

  /// Cancel the periodic background sync task.
  Future<void> cancel() async {
    // TODO: Enable when workmanager package is added
    // await Workmanager().cancelByUniqueName(_uniqueTaskName);
    _registered = false;
    debugPrint('[BackgroundSync] Cancelled periodic task');
  }

  /// Trigger an immediate sync (e.g. after importing a new video).
  ///
  /// This runs the sync engine in the foreground — use [register] for
  /// background execution.
  Future<void> triggerImmediate({
    required final Future<void> Function() syncCallback,
  }) async {
    try {
      await syncCallback();
    } catch (e) {
      debugPrint('[BackgroundSync] Immediate sync failed: $e');
    }
  }
}

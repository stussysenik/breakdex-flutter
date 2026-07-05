import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/diagnostics.dart';
import 'settings_service.dart' show sharedPreferencesProvider;

/// The critical stages of the application startup sequence.
enum BootGate {
  /// Firebase core initialization.
  firebase,

  /// SharedPreferences loaded.
  preferences,

  /// VideoPathResolver (directory caching).
  videoResolver,

  /// VideoStorageGate (path validation).
  storageGate,

  /// Primary database connection and smoke test.
  database,

  /// Database recovery check and rolling backup.
  recovery,

  /// FSRS data migrations (post-frame).
  migrations,

  /// Video path healing (post-frame).
  healing,

  /// Canonical folder pruning (post-frame).
  pruning,

  /// Legacy asset migration (post-frame).
  legacyMigration,
}

/// Gates that must clear before the UI is shown. The splash progress bar
/// represents *these* — post-frame work (migrations, healing, …) runs after
/// the app is already interactive and must not inflate the splash denominator.
const Set<BootGate> kCoreBootGates = {
  BootGate.firebase,
  BootGate.preferences,
  BootGate.videoResolver,
  BootGate.storageGate,
  BootGate.database,
  BootGate.recovery,
};

/// Represents the current progress of the app's boot sequence.
@immutable
class BootState {
  final Set<BootGate> completedGates;
  final String? currentTask;
  final bool isReadyForUI;
  final bool isComplete;
  final DateTime startTime;

  /// EWMA of how long previous launches took to reach [isReadyForUI], loaded
  /// from persistent storage. Null on first ever launch. Drives smooth
  /// interpolation and ETA so the splash reflects real waiting time.
  final Duration? expectedReady;

  const BootState({
    required this.completedGates,
    this.currentTask,
    this.isReadyForUI = false,
    this.isComplete = false,
    required this.startTime,
    this.expectedReady,
  });

  factory BootState.initial() => BootState(
        completedGates: const {},
        startTime: DateTime.now(),
      );

  int get _completedCoreGates =>
      completedGates.where(kCoreBootGates.contains).length;

  /// Discrete monotonic floor: fraction of core gates cleared. Reaches 1.0
  /// exactly when [isReadyForUI] flips — so the splash never claims more
  /// progress than has truly been made, and never less.
  double get coreFloor =>
      isReadyForUI ? 1.0 : _completedCoreGates / kCoreBootGates.length;

  /// Progress of the post-frame background work (migrations, healing, …),
  /// shown as the thin top bar once the UI is interactive.
  double get postFrameProgress {
    final postFrame =
        BootGate.values.where((final g) => !kCoreBootGates.contains(g));
    final total = postFrame.length;
    if (total == 0) return 1.0;
    final done = postFrame.where(completedGates.contains).length;
    return done / total;
  }

  /// Smoothly-interpolated splash progress. Blends the discrete gate [coreFloor]
  /// (correctness) with elapsed-vs-[expectedReady] time (smoothness), so the bar
  /// advances continuously toward the time the device historically takes,
  /// snapping forward whenever a real gate clears. Capped below 1.0 until the
  /// UI is genuinely ready.
  double interpolatedProgress(final Duration elapsed) {
    if (isReadyForUI) return 1.0;
    final floor = coreFloor;
    final expected = expectedReady;
    if (expected == null || expected.inMilliseconds <= 0) return floor;
    final timeBased =
        (elapsed.inMilliseconds / expected.inMilliseconds).clamp(0.0, 0.95);
    return math.max(floor, timeBased);
  }

  /// Estimated time remaining until [isReadyForUI], or null when unknown or
  /// already ready.
  Duration? eta(final Duration elapsed) {
    if (isReadyForUI) return null;
    final expected = expectedReady;
    if (expected == null) return null;
    final remaining = expected - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  BootState copyWith({
    final Set<BootGate>? completedGates,
    final String? currentTask,
    final bool? isReadyForUI,
    final bool? isComplete,
    final Duration? expectedReady,
  }) {
    return BootState(
      completedGates: completedGates ?? this.completedGates,
      currentTask: currentTask ?? this.currentTask,
      isReadyForUI: isReadyForUI ?? this.isReadyForUI,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime,
      expectedReady: expectedReady ?? this.expectedReady,
    );
  }
}

/// Orchestrates the app launch sequence by tracking specific initialization "gates".
///
/// Replaces arbitrary time-based delays (e.g. `Future.delayed(2s)`) with
/// a deterministic, process-driven flow. Screens can watch this coordinator
/// to show granular loading progress or wait for specific dependencies.
class BootCoordinator extends Notifier<BootState> {
  late final StageLogger _logger;

  static const _expectedReadyKey = 'boot_expected_ready_ms';

  @override
  BootState build() {
    _logger = StageLogger.begin('BootSequence', subsystem: 'Boot');
    Duration? expected;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final ms = prefs.getInt(_expectedReadyKey);
      if (ms != null && ms > 0) expected = Duration(milliseconds: ms);
    } on Object catch (_) {
      // Prefs unavailable (e.g. unit tests) — fall back to discrete progress.
    }
    return BootState.initial().copyWith(expectedReady: expected);
  }

  /// Mark a specific initialization gate as complete.
  void completeGate(final BootGate gate, {final String? detail}) {
    if (state.completedGates.contains(gate)) return;

    final newGates = Set<BootGate>.from(state.completedGates)..add(gate);
    _logger.stage(gate.name, detail != null ? {'detail': detail} : null);

    // UI is considered "ready" once the core persistent stores and database
    // are available. Heavy post-frame migrations don't block the UI gate.
    final isReadyForUI = newGates.containsAll(kCoreBootGates);
    final justBecameReady = isReadyForUI && !state.isReadyForUI;

    final isComplete = newGates.length == BootGate.values.length;

    state = state.copyWith(
      completedGates: newGates,
      isReadyForUI: isReadyForUI,
      isComplete: isComplete,
    );

    if (justBecameReady) _persistReadyDuration();

    if (isComplete) {
      _logger.complete('All gates cleared in ${DateTime.now().difference(state.startTime).inMilliseconds}ms');
    }
  }

  /// Persist an EWMA of the time-to-ready so the next launch's splash can show
  /// a calibrated ETA. Disposable cache (SharedPreferences) — never user data.
  void _persistReadyDuration() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final elapsedMs =
          DateTime.now().difference(state.startTime).inMilliseconds;
      if (elapsedMs <= 0) return;
      final prevMs = prefs.getInt(_expectedReadyKey);
      final blended = prevMs == null
          ? elapsedMs
          : (0.3 * elapsedMs + 0.7 * prevMs).round();
      unawaited(prefs.setInt(_expectedReadyKey, blended));
    } on Object catch (_) {
      // Calibration is best-effort; never block boot on it.
    }
  }

  /// Update the label of the task currently being processed.
  void setTask(final String task) {
    state = state.copyWith(currentTask: task);
  }
}

final bootCoordinatorProvider = NotifierProvider<BootCoordinator, BootState>(
  BootCoordinator.new,
);

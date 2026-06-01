import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/diagnostics.dart';

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

/// Represents the current progress of the app's boot sequence.
@immutable
class BootState {
  final Set<BootGate> completedGates;
  final String? currentTask;
  final bool isReadyForUI;
  final bool isComplete;
  final DateTime startTime;

  const BootState({
    required this.completedGates,
    this.currentTask,
    this.isReadyForUI = false,
    this.isComplete = false,
    required this.startTime,
  });

  factory BootState.initial() => BootState(
        completedGates: const {},
        startTime: DateTime.now(),
      );

  double get progress {
    if (isComplete) return 1.0;
    return completedGates.length / BootGate.values.length;
  }

  BootState copyWith({
    final Set<BootGate>? completedGates,
    final String? currentTask,
    final bool? isReadyForUI,
    final bool? isComplete,
  }) {
    return BootState(
      completedGates: completedGates ?? this.completedGates,
      currentTask: currentTask ?? this.currentTask,
      isReadyForUI: isReadyForUI ?? this.isReadyForUI,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime,
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

  @override
  BootState build() {
    _logger = StageLogger.begin('BootSequence', subsystem: 'Boot');
    return BootState.initial();
  }

  /// Mark a specific initialization gate as complete.
  void completeGate(final BootGate gate, {final String? detail}) {
    if (state.completedGates.contains(gate)) return;

    final newGates = Set<BootGate>.from(state.completedGates)..add(gate);
    _logger.stage(gate.name, detail != null ? {'detail': detail} : null);

    // UI is considered "ready" once the core persistent stores and database
    // are available. Heavy post-frame migrations don't block the UI gate.
    final isReadyForUI = newGates.containsAll({
      BootGate.firebase,
      BootGate.preferences,
      BootGate.videoResolver,
      BootGate.storageGate,
      BootGate.database,
      BootGate.recovery,
    });

    final isComplete = newGates.length == BootGate.values.length;

    state = state.copyWith(
      completedGates: newGates,
      isReadyForUI: isReadyForUI,
      isComplete: isComplete,
    );

    if (isComplete) {
      _logger.complete('All gates cleared in ${DateTime.now().difference(state.startTime).inMilliseconds}ms');
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

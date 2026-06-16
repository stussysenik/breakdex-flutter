import 'package:shared_preferences/shared_preferences.dart';

/// User-tunable FSRS scheduling parameters, persisted in SharedPreferences.
///
/// This is the single source of truth for the values the `fsrs.Scheduler` is
/// constructed with. [defaults] equals the constants that were previously
/// hardcoded in `FsrsService`, so a learner who never opens the controls
/// experiences byte-for-byte identical scheduling.
///
/// Persistence is **prefs-only** — no database table, no migration. Editing a
/// parameter never touches a stored `fsrs_cards` row; the new value only
/// affects the math applied at a card's *next* review.
class FsrsSettings {
  final double desiredRetention;
  final List<Duration> learningSteps;
  final List<Duration> relearningSteps;
  final int maximumInterval;
  final bool enableFuzzing;

  const FsrsSettings({
    required this.desiredRetention,
    required this.learningSteps,
    required this.relearningSteps,
    required this.maximumInterval,
    required this.enableFuzzing,
  });

  /// The prior hardcoded scheduler constants — the behavior-preserving baseline.
  static const FsrsSettings defaults = FsrsSettings(
    desiredRetention: 0.85,
    learningSteps: [Duration(minutes: 10)],
    relearningSteps: [Duration(minutes: 10)],
    maximumInterval: 36500,
    enableFuzzing: true,
  );

  // Safe ranges — values are clamped/validated before persisting or applying,
  // guarding against the `fsrs` package asserting on out-of-range input.
  static const double minRetention = 0.70;
  static const double maxRetention = 0.97;
  static const int minMaximumInterval = 1;

  // Prefs keys (namespaced under `fsrs.`).
  static const _kRetention = 'fsrs.desiredRetention';
  static const _kMaxInterval = 'fsrs.maximumInterval';
  static const _kFuzzing = 'fsrs.enableFuzzing';
  static const _kLearningSteps = 'fsrs.learningSteps';
  static const _kRelearningSteps = 'fsrs.relearningSteps';

  FsrsSettings copyWith({
    final double? desiredRetention,
    final List<Duration>? learningSteps,
    final List<Duration>? relearningSteps,
    final int? maximumInterval,
    final bool? enableFuzzing,
  }) {
    return FsrsSettings(
      desiredRetention: desiredRetention ?? this.desiredRetention,
      learningSteps: learningSteps ?? this.learningSteps,
      relearningSteps: relearningSteps ?? this.relearningSteps,
      maximumInterval: maximumInterval ?? this.maximumInterval,
      enableFuzzing: enableFuzzing ?? this.enableFuzzing,
    );
  }

  // -------------------------------------------------------------------------
  // Clamping — applied at every edit so a raw out-of-range value never reaches
  // the scheduler.
  // -------------------------------------------------------------------------

  static double clampRetention(final double v) =>
      v.clamp(minRetention, maxRetention).toDouble();

  static int clampMaximumInterval(final int v) =>
      v < minMaximumInterval ? minMaximumInterval : v;

  /// Drops negative durations; an empty list is allowed (skip these steps).
  static List<Duration> sanitizeSteps(final List<Duration> steps) =>
      steps.where((final d) => !d.isNegative).toList();

  // -------------------------------------------------------------------------
  // Prefs IO — primitive encoding, with per-parameter default fallback.
  // -------------------------------------------------------------------------

  /// Reads settings from prefs. Any missing, corrupt, or out-of-range value
  /// falls back to the corresponding default — never throws.
  static FsrsSettings fromPrefs(final SharedPreferences prefs) {
    return FsrsSettings(
      desiredRetention: _readRetention(prefs),
      maximumInterval: _readMaxInterval(prefs),
      enableFuzzing: prefs.getBool(_kFuzzing) ?? defaults.enableFuzzing,
      learningSteps:
          _readSteps(prefs, _kLearningSteps, defaults.learningSteps),
      relearningSteps:
          _readSteps(prefs, _kRelearningSteps, defaults.relearningSteps),
    );
  }

  /// Persists every parameter primitively. Steps encode as whole minutes.
  Future<void> writeTo(final SharedPreferences prefs) async {
    await prefs.setDouble(_kRetention, desiredRetention);
    await prefs.setInt(_kMaxInterval, maximumInterval);
    await prefs.setBool(_kFuzzing, enableFuzzing);
    await prefs.setStringList(_kLearningSteps, _encodeSteps(learningSteps));
    await prefs.setStringList(_kRelearningSteps, _encodeSteps(relearningSteps));
  }

  static double _readRetention(final SharedPreferences prefs) {
    final v = prefs.getDouble(_kRetention);
    if (v == null || v < minRetention || v > maxRetention) {
      return defaults.desiredRetention;
    }
    return v;
  }

  static int _readMaxInterval(final SharedPreferences prefs) {
    final v = prefs.getInt(_kMaxInterval);
    if (v == null || v < minMaximumInterval) return defaults.maximumInterval;
    return v;
  }

  static List<Duration> _readSteps(
    final SharedPreferences prefs,
    final String key,
    final List<Duration> fallback,
  ) {
    final raw = prefs.getStringList(key);
    if (raw == null) return fallback;
    final mins = <int>[];
    for (final s in raw) {
      final m = int.tryParse(s);
      if (m == null) return fallback; // corrupt entry → whole list falls back
      if (m >= 0) mins.add(m);
    }
    return mins.map((final m) => Duration(minutes: m)).toList();
  }

  static List<String> _encodeSteps(final List<Duration> steps) =>
      steps.map((final d) => d.inMinutes.toString()).toList();

  @override
  bool operator ==(final Object other) =>
      other is FsrsSettings &&
      other.desiredRetention == desiredRetention &&
      other.maximumInterval == maximumInterval &&
      other.enableFuzzing == enableFuzzing &&
      _stepsEqual(other.learningSteps, learningSteps) &&
      _stepsEqual(other.relearningSteps, relearningSteps);

  @override
  int get hashCode => Object.hash(
        desiredRetention,
        maximumInterval,
        enableFuzzing,
        Object.hashAll(learningSteps),
        Object.hashAll(relearningSteps),
      );

  static bool _stepsEqual(final List<Duration> a, final List<Duration> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

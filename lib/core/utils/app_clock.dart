import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for time across Breakdex.
///
/// This is the Phase-1 seed of the atomic-time work: all *new* code reads time
/// through this abstraction so we have one UTC wall clock plus one monotonic
/// clock. Existing `DateTime.now()` call sites are migrated in a later, schema-
/// touching phase — this introduces the contract without rewriting them.
///
/// Use [nowUtc] for timestamps that get persisted or compared across devices.
/// Use [monotonic] for elapsed-time and rate math: it is immune to wall-clock
/// changes (NTP corrections, manual clock edits) and is deterministic under
/// test when a fake clock is injected.
abstract class AppClock {
  /// Wall-clock time, always in UTC.
  DateTime nowUtc();

  /// Monotonic elapsed time since this clock was created. Never derive elapsed
  /// time by subtracting two [nowUtc] values.
  Duration get monotonic;
}

/// Production clock backed by the system wall clock and a monotonic [Stopwatch].
class SystemClock implements AppClock {
  SystemClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  Duration get monotonic => _stopwatch.elapsed;
}

/// App-wide clock. Override in tests with a controllable fake.
final appClockProvider = Provider<AppClock>((final ref) => SystemClock());

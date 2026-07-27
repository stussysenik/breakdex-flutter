import 'package:breakdex/core/utils/app_clock.dart';

/// Smoothed transfer-rate + ETA estimator — the "math = how much time is left"
/// behind deterministic download UI.
///
/// Feed cumulative bytes via [record]; read [bytesPerSecond], [etaRemaining]
/// and [isStalled]. Backed by an injected [AppClock] (monotonic) so it is
/// immune to wall-clock changes and fully deterministic under test.
///
/// Rate uses an exponentially-weighted moving average so a momentary hiccup
/// doesn't whipsaw the displayed ETA, while a genuine slowdown is still tracked.
class TransferRateEstimator {
  TransferRateEstimator({
    required final AppClock clock,
    final double smoothing = 0.3,
    final Duration stallAfter = const Duration(seconds: 6),
  })  : _clock = clock,
        _smoothing = smoothing,
        _stallAfter = stallAfter;

  final AppClock _clock;
  final double _smoothing;
  final Duration _stallAfter;

  Duration? _lastTime;
  int _lastBytes = 0;
  Duration _lastForwardTime = Duration.zero;
  double _rate = 0; // bytes/second, EWMA
  int _bytesSoFar = 0;
  int _totalBytes = 0;
  bool _started = false;

  /// Record a cumulative byte count and the (possibly growing) total.
  void record(final int bytesSoFar, final int totalBytes) {
    final now = _clock.monotonic;
    _bytesSoFar = bytesSoFar;
    _totalBytes = totalBytes;

    if (!_started) {
      _started = true;
      _lastTime = now;
      _lastForwardTime = now;
      _lastBytes = bytesSoFar;
      return;
    }

    final dtSeconds = (now - _lastTime!).inMicroseconds / 1e6;
    final deltaBytes = bytesSoFar - _lastBytes;
    if (dtSeconds > 0 && deltaBytes > 0) {
      final instant = deltaBytes / dtSeconds;
      _rate = _rate == 0
          ? instant
          : _smoothing * instant + (1 - _smoothing) * _rate;
      _lastForwardTime = now;
    }
    _lastTime = now;
    _lastBytes = bytesSoFar;
  }

  /// Smoothed transfer rate in bytes/second (0 before any forward progress).
  double get bytesPerSecond => _rate;

  /// Estimated time until completion, or null when it can't be computed yet
  /// (no rate, or unknown total).
  Duration? get etaRemaining {
    if (_rate <= 0 || _totalBytes <= 0) return null;
    final remaining = _totalBytes - _bytesSoFar;
    if (remaining <= 0) return Duration.zero;
    final seconds = remaining / _rate;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// True when no forward progress has been seen for [_stallAfter]. Evaluated
  /// against the live clock, so a frozen transfer is detected even when no
  /// further progress callbacks arrive.
  bool get isStalled {
    if (!_started) return false;
    if (_totalBytes > 0 && _bytesSoFar >= _totalBytes) return false;
    return (_clock.monotonic - _lastForwardTime) >= _stallAfter;
  }

  /// Reset for a fresh transfer of the same item (e.g. a retry).
  void reset() {
    _started = false;
    _lastTime = null;
    _lastBytes = 0;
    _lastForwardTime = Duration.zero;
    _rate = 0;
    _bytesSoFar = 0;
    _totalBytes = 0;
  }
}

/// Human-readable "time left" label for a transfer ETA.
String formatTransferEta(final Duration eta) {
  final seconds = eta.inSeconds;
  if (seconds <= 0) return 'almost done';
  if (seconds < 60) return '${seconds}s left';
  final minutes = eta.inMinutes;
  final remSeconds = seconds % 60;
  return '${minutes}m ${remSeconds}s left';
}

/// Human-readable transfer rate (e.g. "1.4 MB/s"). Empty when rate is unknown.
String formatTransferRate(final double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '';
  return '${formatBytes(bytesPerSecond.round())}/s';
}

/// Human-readable byte size (binary units).
String formatBytes(final int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

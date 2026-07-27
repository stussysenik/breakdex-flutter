import 'dart:async';

import 'package:breakdex/core/utils/app_clock.dart';
import 'package:breakdex/core/utils/diagnostics.dart';

/// Watches an in-flight operation's progress feed and logs stall windows.
///
/// While started, if [threshold] passes without the noted progress value
/// advancing, a `stalled` stage entry is emitted on [_log] with the frozen
/// value and elapsed ms; when progress advances again a `recovered` entry
/// closes the window, so the log trail shows exactly where an import hung.
///
/// Elapsed time is read through [AppClock.monotonic] and the periodic check
/// runs on a [Timer], so tests can drive both with a fake clock and fake
/// async time instead of waiting out real seconds.
class StallDetector {
  StallDetector({
    required final StageLogger log,
    final AppClock? clock,
    this.threshold = const Duration(seconds: 2),
    this.checkInterval = const Duration(milliseconds: 500),
  })  : _log = log,
        _clock = clock ?? SystemClock();

  final StageLogger _log;
  final AppClock _clock;
  final Duration threshold;
  final Duration checkInterval;

  Timer? _timer;
  Duration _lastAdvanceAt = Duration.zero;
  double _lastValue = -1;
  bool _stalled = false;

  /// Begin watching. Resets any previous state.
  void start() {
    _timer?.cancel();
    _lastAdvanceAt = _clock.monotonic;
    _lastValue = -1;
    _stalled = false;
    _timer = Timer.periodic(checkInterval, (final _) => _check());
  }

  /// Feed the latest progress value (from any source). Only an actual change
  /// in value counts as an advance; repeated identical emissions do not
  /// reset the stall window.
  void note(final double value) {
    if (value == _lastValue) return;
    if (_stalled) {
      _stalled = false;
      _log.stage('recovered', {
        'progress': value,
        'stalledMs': (_clock.monotonic - _lastAdvanceAt).inMilliseconds,
      });
    }
    _lastValue = value;
    _lastAdvanceAt = _clock.monotonic;
  }

  /// Stop watching (operation finished, failed, or was cancelled).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _check() {
    if (_stalled) return;
    final frozen = _clock.monotonic - _lastAdvanceAt;
    if (frozen >= threshold) {
      _stalled = true;
      _log.stage('stalled', {
        'progress': _lastValue,
        'frozenMs': frozen.inMilliseconds,
      });
    }
  }
}

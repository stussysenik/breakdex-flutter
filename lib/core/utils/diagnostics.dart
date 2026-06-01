import 'package:flutter/foundation.dart';

enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
}

abstract class DiagnosticsLog {
  DiagnosticsLog._();

  static LogLevel _threshold = LogLevel.info;

  static DateTime? _startupEpoch;

  static final Map<String, LogLevel> _subsystemThresholds = {};

  static void configure({final LogLevel threshold = LogLevel.info}) {
    _threshold = threshold;
    _startupEpoch ??= DateTime.now();
  }

  static void setSubsystemThreshold(final String subsystem, final LogLevel level) {
    _subsystemThresholds[subsystem] = level;
  }

  static bool _shouldLog(final String subsystem, final LogLevel level) {
    final effectiveThreshold =
        _subsystemThresholds[subsystem] ?? _threshold;
    return level.index >= effectiveThreshold.index;
  }

  static String _levelLabel(final LogLevel level) => switch (level) {
        LogLevel.trace => 'TRC',
        LogLevel.debug => 'DBG',
        LogLevel.info => 'INF',
        LogLevel.warn => 'WRN',
        LogLevel.error => 'ERR',
      };

  static String _elapsed() {
    if (_startupEpoch == null) return '';
    final ms = DateTime.now().difference(_startupEpoch!).inMilliseconds;
    final s = (ms / 1000).toStringAsFixed(1);
    return 'T+${s}s';
  }

  static void _emit(final String subsystem, final LogLevel level, final String message) {
    if (!_shouldLog(subsystem, level)) return;
    final label = _levelLabel(level);
    final elapsed = _elapsed();
    debugPrint('[$label][$subsystem] $elapsed $message');
  }

  static void trace(final String subsystem, final String message) =>
      _emit(subsystem, LogLevel.trace, message);

  static void debug(final String subsystem, final String message) =>
      _emit(subsystem, LogLevel.debug, message);

  static void info(final String subsystem, final String message) =>
      _emit(subsystem, LogLevel.info, message);

  static void warn(final String subsystem, final String message) =>
      _emit(subsystem, LogLevel.warn, message);

  static void error(final String subsystem, final String message) =>
      _emit(subsystem, LogLevel.error, message);
}

class StageLogger {
  final String _operation;
  final String _subsystem;
  final Map<String, Object?> _context;
  final Stopwatch _stopwatch;

  String _currentStage = 'init';

  StageLogger._({
    required final String operation,
    required final String subsystem,
    final Map<String, Object?>? context,
  })  : _operation = operation,
        _subsystem = subsystem,
        _context = context ?? {},
        _stopwatch = Stopwatch() {
    _stopwatch.start();
    DiagnosticsLog.info(
      _subsystem,
      '$_operation ▸ START ${_fmtContext()}',
    );
  }

  factory StageLogger.begin(
    final String operation, {
    required final String subsystem,
    final Map<String, Object?>? context,
  }) {
    return StageLogger._(
      operation: operation,
      subsystem: subsystem,
      context: context,
    );
  }

  String _fmtContext() {
    if (_context.isEmpty) return '';
    return _context.entries
        .map((final e) => '${e.key}=${e.value}')
        .join(' ');
  }

  void stage(final String name, [final Map<String, Object?>? extra]) {
    final elapsed = _stopwatch.elapsedMilliseconds;
    final extraStr =
        extra != null && extra.isNotEmpty
            ? ' ${extra.entries.map((final e) => '${e.key}=${e.value}').join(' ')}'
            : '';
    DiagnosticsLog.debug(
      _subsystem,
      '$_operation │ $name (${elapsed}ms)$extraStr',
    );
    _currentStage = name;
  }

  void complete([final String? detail]) {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    final detailStr = detail != null ? ' — $detail' : '';
    DiagnosticsLog.info(
      _subsystem,
      '$_operation ✔ COMPLETE (${elapsed}ms)$detailStr',
    );
  }

  void fail(final Object error, [final StackTrace? stack]) {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    DiagnosticsLog.error(
      _subsystem,
      '$_operation ✘ FAILED at "$_currentStage" (${elapsed}ms): $error',
    );
    if (stack != null && !kReleaseMode) {
      debugPrintStack(stackTrace: stack);
    }
  }
}

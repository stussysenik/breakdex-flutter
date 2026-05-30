import 'dart:async';
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

  static void configure({LogLevel threshold = LogLevel.info}) {
    _threshold = threshold;
    _startupEpoch ??= DateTime.now();
  }

  static void setSubsystemThreshold(String subsystem, LogLevel level) {
    _subsystemThresholds[subsystem] = level;
  }

  static bool _shouldLog(String subsystem, LogLevel level) {
    final effectiveThreshold =
        _subsystemThresholds[subsystem] ?? _threshold;
    return level.index >= effectiveThreshold.index;
  }

  static String _levelLabel(LogLevel level) => switch (level) {
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

  static void _emit(String subsystem, LogLevel level, String message) {
    if (!_shouldLog(subsystem, level)) return;
    final label = _levelLabel(level);
    final elapsed = _elapsed();
    debugPrint('[$label][$subsystem] $elapsed $message');
  }

  static void trace(String subsystem, String message) =>
      _emit(subsystem, LogLevel.trace, message);

  static void debug(String subsystem, String message) =>
      _emit(subsystem, LogLevel.debug, message);

  static void info(String subsystem, String message) =>
      _emit(subsystem, LogLevel.info, message);

  static void warn(String subsystem, String message) =>
      _emit(subsystem, LogLevel.warn, message);

  static void error(String subsystem, String message) =>
      _emit(subsystem, LogLevel.error, message);
}

class StageLogger {
  final String _operation;
  final String _subsystem;
  final Map<String, Object?> _context;
  final Stopwatch _stopwatch;

  String _currentStage = 'init';

  StageLogger._({
    required String operation,
    required String subsystem,
    Map<String, Object?>? context,
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
    String operation, {
    required String subsystem,
    Map<String, Object?>? context,
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
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
  }

  void stage(String name, [Map<String, Object?>? extra]) {
    final elapsed = _stopwatch.elapsedMilliseconds;
    final extraStr =
        extra != null && extra.isNotEmpty
            ? ' ${extra.entries.map((e) => '${e.key}=${e.value}').join(' ')}'
            : '';
    DiagnosticsLog.debug(
      _subsystem,
      '$_operation │ $name (${elapsed}ms)$extraStr',
    );
    _currentStage = name;
  }

  void complete([String? detail]) {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    final detailStr = detail != null ? ' — $detail' : '';
    DiagnosticsLog.info(
      _subsystem,
      '$_operation ✔ COMPLETE (${elapsed}ms)$detailStr',
    );
  }

  void fail(Object error, [StackTrace? stack]) {
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

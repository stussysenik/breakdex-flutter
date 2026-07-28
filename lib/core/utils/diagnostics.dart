import 'package:flutter/foundation.dart';

enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
}

/// One retained line. Kept as data rather than a formatted string so a reader
/// can filter by level or subsystem after the fact — the whole point of
/// retention is answering a question you did not know to ask while it ran.
@immutable
class DiagnosticRecord {
  const DiagnosticRecord({
    required this.at,
    required this.subsystem,
    required this.level,
    required this.message,
  });

  final DateTime at;
  final String subsystem;
  final LogLevel level;
  final String message;
}

abstract class DiagnosticsLog {
  DiagnosticsLog._();

  static LogLevel _threshold = LogLevel.info;

  /// What gets *retained*, independent of what gets *printed*. These are two
  /// different questions: the console stays readable at `info`, while the ring
  /// buffer keeps `debug` so a bug report contains the detail nobody thought to
  /// enable beforehand. Raising print verbosity needs a rebuild; reading the
  /// buffer does not.
  static LogLevel _captureThreshold = LogLevel.debug;

  static DateTime? _startupEpoch;

  static final Map<String, LogLevel> _subsystemThresholds = {};

  /// Bounded so a long session cannot grow without limit; oldest lines are
  /// dropped first, because the tail is what explains a failure.
  static final List<DiagnosticRecord> _buffer = [];
  static int _bufferLimit = 2000;

  static void configure({
    final LogLevel threshold = LogLevel.info,
    final LogLevel captureThreshold = LogLevel.debug,
    final int bufferLimit = 2000,
  }) {
    _threshold = threshold;
    _captureThreshold = captureThreshold;
    _bufferLimit = bufferLimit;
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
    if (level.index >= _captureThreshold.index) {
      _buffer.add(DiagnosticRecord(
        at: DateTime.now(),
        subsystem: subsystem,
        level: level,
        message: message,
      ));
      if (_buffer.length > _bufferLimit) {
        _buffer.removeRange(0, _buffer.length - _bufferLimit);
      }
    }
    if (!_shouldLog(subsystem, level)) return;
    final label = _levelLabel(level);
    final elapsed = _elapsed();
    debugPrint('[$label][$subsystem] $elapsed $message');
  }

  /// The retained lines, oldest first, optionally narrowed. Returns a copy so a
  /// caller rendering the list cannot be surprised mid-build by a concurrent log.
  static List<DiagnosticRecord> recent({
    final LogLevel? minLevel,
    final String? subsystem,
  }) =>
      _buffer
          .where((final r) =>
              (minLevel == null || r.level.index >= minLevel.index) &&
              (subsystem == null || r.subsystem == subsystem))
          .toList(growable: false);

  static void clearBuffer() => _buffer.clear();

  /// The retained log as one shareable block, secrets redacted.
  ///
  /// Redaction is not optional here: this exists so a log can be pasted into a
  /// bug report or handed to an agent, and the auth path logs the very values
  /// that must never leave the device (CLAUDE.md security posture — tokens live
  /// in secure storage, so they must not leak back out through a log).
  static String export({final LogLevel? minLevel, final String? subsystem}) {
    final rows = recent(minLevel: minLevel, subsystem: subsystem);
    if (rows.isEmpty) return '(no diagnostic records retained)';
    final buf = StringBuffer();
    for (final r in rows) {
      buf.writeln(
        '${r.at.toIso8601String()} [${_levelLabel(r.level)}]'
        '[${r.subsystem}] ${redactSecrets(r.message)}',
      );
    }
    return buf.toString();
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

/// Mask anything that looks like a credential in [input].
///
/// Deliberately pattern-based and over-eager rather than clever: a false
/// positive costs a reader one unreadable field, a false negative leaks a
/// session. Covers `key=value` secrets, bearer tokens, JWTs, and email
/// local-parts (an account id is enough to correlate a user).
String redactSecrets(final String input) {
  var out = input;
  out = out.replaceAllMapped(
    RegExp(
      r'\b(secret|token|password|passwd|apikey|api_key|jwt|session|cookie|authorization|bearer|client_secret|refresh_token|access_token)'
      r'''([=:]\s*|\s+)(['"]?)([^\s,;'"}\])]{4,})''',
      caseSensitive: false,
    ),
    (final m) => '${m[1]}${m[2]}${m[3]}<redacted>',
  );
  // Bare JWTs (three base64url segments) appear without a labelling key.
  out = out.replaceAll(
    RegExp(r'\beyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\b'),
    '<redacted-jwt>',
  );
  out = out.replaceAllMapped(
    RegExp(r'\b[\w.+-]+@([\w-]+\.[\w.-]+)\b'),
    (final m) => '<redacted>@${m[1]}',
  );
  return out;
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

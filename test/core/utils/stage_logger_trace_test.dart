import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:breakdex/core/utils/diagnostics.dart';

class _CauseUnderTest implements Exception {
  const _CauseUnderTest();
}

/// The shape every error path in production has: catch, report through
/// [StageLogger.fail], rethrow. If the reporter throws, the caller loses the
/// cause and receives the reporter's failure instead.
Object _reportedCauseOf(final StackTrace stack) {
  final logger = StageLogger.begin('probe', subsystem: 'test');
  try {
    try {
      throw const _CauseUnderTest();
    } on Object catch (error, _) {
      logger.fail(error, stack);
      rethrow;
    }
  } on Object catch (surfaced) {
    return surfaced;
  }
}

void main() {
  // Deliberately no `TestWidgetsFlutterBinding.ensureInitialized()` and no
  // per-file demangle hook: this is a plain `test()` body, which is exactly the
  // context where `FlutterError.demangleStackTrace` is left at its unwired
  // default.
  late DebugPrintCallback realDebugPrint;

  setUp(() {
    realDebugPrint = debugPrint;
    debugPrint = (final String? message, {final int? wrapWidth}) {};
  });

  tearDown(() {
    debugPrint = realDebugPrint;
  });

  group('StageLogger.fail with a package:stack_trace trace', () {
    // A bare `Trace` formats VM-shaped frames and parses fine; only a `Chain`
    // carries the `===== asynchronous gap =====` line the assertion rejects,
    // and a `Chain` is what `package:test` propagates from async bodies.
    test('does not throw on a Chain', () {
      final logger = StageLogger.begin('probe', subsystem: 'test');

      expect(
        () => logger.fail(const _CauseUnderTest(), Chain.current()),
        returnsNormally,
      );
    });

    test('leaves the reported cause as what the caller surfaces', () {
      expect(_reportedCauseOf(Chain.current()), isA<_CauseUnderTest>());
    });
  });
}

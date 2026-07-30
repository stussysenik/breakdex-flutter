import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stack_trace/stack_trace.dart';

/// Suite-wide test setup.
///
/// `flutter_test` looks for the nearest `flutter_test_config.dart` above each
/// test file and runs [testExecutable] instead of `main` directly, so anything
/// wired here applies to every test under `test/` with no per-file import. It
/// is the only hook that can make a rule hold for tests that do not exist yet.
///
/// ## Why the demangle hook lives here
///
/// `package:test` runs async bodies inside `Chain.capture`, so an error's stack
/// trace is a `package:stack_trace` [Chain] — frames plus
/// `===== asynchronous gap =====` separators. Flutter's `StackFrame.fromLines`
/// asserts it never sees one (`stack_frame.dart:197`), and reads the mangled
/// form through [FlutterError.demangleStackTrace], which `testWidgets` wires up
/// and a plain `test()` does not.
///
/// Anything that prints a stack therefore *throws* inside a plain `test()`
/// body: `debugPrintStack` in `StageLogger.fail` raised an `_AssertionError`
/// that superseded the exception it was reporting, so an error path reported
/// the reporter's failure instead of the cause. Fixing it in the logger would
/// bend correct production behavior to a harness gap; fixing it here closes the
/// gap for every unit test at once.
Future<void> testExecutable(final FutureOr<void> Function() testMain) async {
  FlutterError.demangleStackTrace = (final StackTrace stack) => switch (stack) {
        final Trace t => t.vmTrace,
        final Chain c => c.toTrace().vmTrace,
        _ => stack,
      };

  await testMain();
}

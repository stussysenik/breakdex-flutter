import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/utils/diagnostics.dart';

/// The retained-log contract. The buffer exists so the owner can hand over a
/// log after a failure without having been tethered to a console, so the two
/// properties that matter are: it keeps what the console dropped, and it never
/// hands back a secret.
void main() {
  setUp(() {
    DiagnosticsLog.clearBuffer();
    DiagnosticsLog.configure(
      threshold: LogLevel.info,
      captureThreshold: LogLevel.debug,
    );
  });

  group('retention is independent of printing', () {
    test('captures a level the console threshold suppresses', () {
      DiagnosticsLog.debug('Sync', 'pull cursor advanced');

      // Printing is at `info`, so this line never reached the console — the
      // whole reason the buffer exists.
      final rows = DiagnosticsLog.recent();
      expect(rows, hasLength(1));
      expect(rows.single.level, LogLevel.debug);
      expect(rows.single.subsystem, 'Sync');
    });

    test('drops below the capture threshold', () {
      DiagnosticsLog.configure(captureThreshold: LogLevel.info);
      DiagnosticsLog.trace('Sync', 'noisy');
      DiagnosticsLog.info('Sync', 'kept');

      expect(DiagnosticsLog.recent().map((final r) => r.message), ['kept']);
    });

    test('evicts oldest first when the buffer is full', () {
      DiagnosticsLog.configure(bufferLimit: 3);
      for (var i = 0; i < 5; i++) {
        DiagnosticsLog.info('Sync', 'line$i');
      }

      // The tail is what explains a failure, so the head is what goes.
      expect(
        DiagnosticsLog.recent().map((final r) => r.message),
        ['line2', 'line3', 'line4'],
      );
    });
  });

  group('filtering', () {
    test('narrows by subsystem and by minimum level', () {
      DiagnosticsLog.debug('Sync', 'a');
      DiagnosticsLog.error('Sync', 'b');
      DiagnosticsLog.error('Auth', 'c');

      expect(
        DiagnosticsLog.recent(subsystem: 'Sync').map((final r) => r.message),
        ['a', 'b'],
      );
      expect(
        DiagnosticsLog.recent(minLevel: LogLevel.error)
            .map((final r) => r.message),
        ['b', 'c'],
      );
    });
  });

  group('export redacts before it shares', () {
    test('masks a labelled secret but keeps the label readable', () {
      DiagnosticsLog.info('Auth', 'session=a1b2c3d4e5f6 established');

      final out = DiagnosticsLog.export();
      expect(out, contains('session='));
      expect(out, contains('<redacted>'));
      expect(out, isNot(contains('a1b2c3d4e5f6')));
    });

    test('masks a bare JWT that no key labels', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NSJ9.dBjftJeZ4CVPmB92K27u';
      DiagnosticsLog.info('Auth', 'got $jwt back');

      final out = DiagnosticsLog.export();
      expect(out, contains('<redacted-jwt>'));
      expect(out, isNot(contains(jwt)));
    });

    test('masks an email local-part but keeps the domain diagnosable', () {
      DiagnosticsLog.info('Auth', 'signed in as itsmxzou@gmail.com');

      final out = DiagnosticsLog.export();
      expect(out, contains('<redacted>@gmail.com'));
      expect(out, isNot(contains('itsmxzou')));
    });

    test('leaves ordinary diagnostic detail intact', () {
      DiagnosticsLog.info('Sync', 'pushed 139 rows in 412ms');

      expect(DiagnosticsLog.export(), contains('pushed 139 rows in 412ms'));
    });

    test('says so plainly when nothing was retained', () {
      expect(DiagnosticsLog.export(), '(no diagnostic records retained)');
    });
  });
}

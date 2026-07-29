import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No _pendingFiles allowlist — the ban is absolute.
/// Any file under lib/ (outside icons.dart) containing raw `Icons.` is a
/// review violation on the same footing as raw Duration/Curve literals.

void main() {
  group('icon conformance — no raw Icons.* anywhere', () {
    test('no file under lib/ has Icons.* (outside the pack resolver)', () {
      final libDir = Directory('lib');
      final offending = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path == 'lib/core/design/icons.dart') continue;
        final source = entity.readAsStringSync();
        if (RegExp(r'Icons\.\w+').hasMatch(source)) {
          offending.add(entity.path);
        }
      }
      expect(offending, isEmpty,
          reason:
              '${offending.length} file(s) still use raw Icons.*:\n'
              '${offending.join('\n')}\n'
              'Migrate to AppIcon before shipping.');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/typography.dart';

/// Every step of the scale, by the name a call site uses.
final _scale = <String, TextStyle>{
  'titleLarge': AppTypography.titleLarge,
  'titleMedium': AppTypography.titleMedium,
  'titleSmall': AppTypography.titleSmall,
  'bodyLarge': AppTypography.bodyLarge,
  'bodyMedium': AppTypography.bodyMedium,
  'bodySmall': AppTypography.bodySmall,
  'caption': AppTypography.caption,
  'sectionHeader': AppTypography.sectionHeader,
  'labelLarge': AppTypography.labelLarge,
  'labelSmall': AppTypography.labelSmall,
};

void main() {
  group('type rides the 2pt baseline', () {
    // The owner's ruling (2026-07-29) is that line heights are multiples of 2,
    // not 4 — a productive ramp needs a step between 26 and 32, and a 4pt
    // baseline cannot give it one. The previous TOKENS.md entry called 30 and
    // 26 "known non-conformance"; they were conforming to a rule nobody had
    // written down. This test is that rule.
    for (final entry in _scale.entries) {
      test('${entry.key} has a line height on the type baseline', () {
        final style = entry.value;
        final fontSize = style.fontSize;
        final heightFactor = style.height;
        expect(fontSize, isNotNull, reason: '${entry.key} has no fontSize');
        expect(heightFactor, isNotNull, reason: '${entry.key} has no height');

        final lineHeight = fontSize! * heightFactor!;
        expect(
          lineHeight % AppLayout.typeBaseline,
          moreOrLessEquals(0, epsilon: 0.001),
          reason:
              '${entry.key} resolves to a ${lineHeight}pt line box, which is '
              'not a multiple of AppLayout.typeBaseline '
              '(${AppLayout.typeBaseline}).',
        );
      });
    }

    test('the type baseline is half the layout baseline', () {
      // Type gets the finer grid; blocks still land on blockGrid. If these
      // ever diverge beyond a clean halving, the two grids have stopped being
      // one system and the ruling needs re-opening.
      expect(AppLayout.baseline / AppLayout.typeBaseline, 2);
    });
  });
}

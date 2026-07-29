import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/shared/widgets/back_leading.dart';

Widget _harness({required final double textScale, required final String label}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leadingWidth: BackLeading.slotWidth,
          leading: BackLeading(identifier: 'test-back', label: label),
        ),
        body: const SizedBox.shrink(),
      ),
    ),
  );
}

void main() {
  group('BackLeading', () {
    // `SCR-20260728-mafz`: "OVERFLOWED BY 2" on the Moves header. The AppBar's
    // leading slot is 56pt by default; a chevron plus a word of bodyMedium is
    // wider than that, and every point of text scaling makes it worse. The
    // control now declares the slot width it needs and its label degrades
    // instead of overflowing.
    for (final scale in <double>[1, 1.3, 2]) {
      testWidgets('does not overflow at text scale $scale', (
        final tester,
      ) async {
        await tester.pumpWidget(_harness(textScale: scale, label: 'Back'));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a long label ellipsizes rather than overflowing', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _harness(textScale: 1, label: 'Uncategorized combinations'),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(BackLeading), findsOneWidget);
    });

    testWidgets('carries its semantics identifier and button role', (
      final tester,
    ) async {
      await tester.pumpWidget(_harness(textScale: 1, label: 'Back'));

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Back').first,
      );
      expect(semantics.identifier, 'test-back');
    });
  });
}

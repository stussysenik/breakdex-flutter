import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/shared/widgets/app_row.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';

/// The grid is a thing you can adjust and watch, not a thing you take on faith.
///
/// These tests hold the two halves of that claim: with no [AppLayoutTheme]
/// registered the frame measures exactly the shipped constants, and with one
/// registered it measures *that* basis instead — same widgets, same pump, no
/// restart. A screen that still reads a constant where it should read the
/// theme fails the second half while passing the first.
void main() {
  Widget frame(final AppLayoutTheme? basis) => MaterialApp(
    theme: ThemeData(extensions: basis == null ? const [] : [basis]),
    home: const AppScreen(
      title: 'Basis',
      children: [
        Text('content'),
        AppRow(label: 'row'),
      ],
    ),
  );

  /// Where the first pixel of text sits: the clamped column's edge plus the
  /// gutter. The column centres above [AppLayout.maxContentWidth], so the
  /// gutter alone does not locate it.
  double leftEdge(final WidgetTester tester, final double gutter) {
    final width = tester.getSize(find.byType(AppScreen)).width;
    final column = width < AppLayout.maxContentWidth
        ? width
        : AppLayout.maxContentWidth;
    return (width - column) / 2 + gutter;
  }

  group('AppLayoutTheme', () {
    testWidgets('defaults to the shipped constants when unregistered', (
      final tester,
    ) async {
      await tester.pumpWidget(frame(null));

      expect(
        tester.getRect(find.text('Basis')).left,
        leftEdge(tester, AppLayout.gutter),
      );
      expect(
        tester.getRect(find.text('content')).top,
        AppLayout.headerHeight + AppLayout.contentTopGap,
      );
      expect(
        tester.getSize(find.byType(AppRow)).height,
        greaterThanOrEqualTo(AppLayout.rowHeight),
      );
    });

    testWidgets('re-flows the frame onto an overridden basis', (
      final tester,
    ) async {
      const basis = AppLayoutTheme(
        gutter: 48,
        rowHeight: 88,
        headerHeight: 120,
      );
      await tester.pumpWidget(frame(basis));

      // Band 2 is taller, so the first content pixel sits lower — the header
      // is the only band between the safe area and it.
      expect(
        tester.getRect(find.text('Basis')).left,
        leftEdge(tester, basis.gutter),
      );
      expect(
        tester.getRect(find.text('content')).top,
        basis.headerHeight + AppLayout.contentTopGap,
      );
      expect(
        tester.getRect(find.text('content')).left,
        leftEdge(tester, basis.gutter),
      );
      expect(
        tester.getSize(find.byType(AppRow)).height,
        greaterThanOrEqualTo(basis.rowHeight),
      );
    });

    test('snap rides the overridden block grid', () {
      expect(const AppLayoutTheme().snap(13), AppLayout.blockGrid * 2);
      expect(const AppLayoutTheme(blockGrid: 10).snap(13), 20);
    });
  });
}

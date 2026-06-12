import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/shared/widgets/beat_grid.dart';

void main() {
  Widget host(final List<BeatGridItem> items, {final double width = 360}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: BeatGrid(items: items)),
        ),
      ),
    );
  }

  group('BeatGrid', () {
    testWidgets('renders one block per move and total beat count',
        (final tester) async {
      await tester.pumpWidget(host([
        const BeatGridItem(label: 'Toprock', count: 4, isActive: true),
        const BeatGridItem(label: 'Drop', count: 2, isActive: false),
        const BeatGridItem(label: 'Windmill', count: 8, isActive: false),
      ]));

      expect(find.text('Toprock'), findsOneWidget);
      expect(find.text('Windmill'), findsOneWidget);
      expect(find.text('14 BEATS'), findsOneWidget);
    });

    testWidgets('tapping a block fires its onTap', (final tester) async {
      int? tapped;
      await tester.pumpWidget(host([
        BeatGridItem(
            label: 'A', count: 4, isActive: true, onTap: () => tapped = 0),
        BeatGridItem(
            label: 'B', count: 4, isActive: false, onTap: () => tapped = 1),
      ]));

      await tester.tap(find.text('B'));
      expect(tapped, 1);
    });

    testWidgets('block width is proportional to beat count',
        (final tester) async {
      await tester.pumpWidget(host([
        const BeatGridItem(label: 'Short', count: 2, isActive: false),
        const BeatGridItem(label: 'Long', count: 8, isActive: true),
      ]));

      final shortWidth = tester.getSize(find.text('Short')).width;
      // Compare the block containers, not the texts: find ancestors.
      final shortBlock = tester.getSize(
        find.ancestor(
          of: find.text('Short'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final longBlock = tester.getSize(
        find.ancestor(
          of: find.text('Long'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(longBlock.width / shortBlock.width, closeTo(4.0, 0.2));
      expect(shortWidth, greaterThan(0));
    });

    testWidgets('narrow blocks hide the label but keep the count',
        (final tester) async {
      // 12 one-beat moves at 240px → ~20px per block, below the 44px floor.
      await tester.pumpWidget(host(
        [
          for (var i = 0; i < 12; i++)
            BeatGridItem(label: 'Move$i', count: 1, isActive: i == 0),
        ],
        width: 240,
      ));

      expect(find.text('Move0'), findsNothing);
      // Counts still render (one "1" per block).
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('renders nothing for empty or zero-beat input',
        (final tester) async {
      await tester.pumpWidget(host(const []));
      expect(find.text('BEAT GRID'), findsNothing);

      await tester.pumpWidget(host([
        const BeatGridItem(label: 'X', count: 0, isActive: false),
      ]));
      expect(find.text('BEAT GRID'), findsNothing);
    });
  });
}

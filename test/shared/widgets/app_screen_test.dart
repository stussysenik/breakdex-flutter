import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';

void main() {
  group('AppScreen', () {
    testWidgets('holds the FAB clear of the nav band the shell draws over it', (
      final tester,
    ) async {
      const bottomPadding = 34.0; // a home-indicator-class safe inset
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: bottomPadding),
          ),
          child: MaterialApp(
            home: AppScreen(
              title: 'Frame',
              floatingActionButton: FloatingActionButton(
                onPressed: null,
                child: Icon(Icons.add),
              ),
              children: [Text('content')],
            ),
          ),
        ),
      );

      // The shell renders band 4 over this screen (`extendBody: true`), so a
      // FAB flush to the Scaffold bottom would sit underneath it. The frame
      // owns that inset so no screen hand-rolls it again.
      final fabBottom = tester.getRect(find.byType(FloatingActionButton)).bottom;
      final screenBottom = tester.getRect(find.byType(AppScreen)).bottom;
      expect(
        screenBottom - fabBottom,
        greaterThanOrEqualTo(AppLayout.navBandHeight + bottomPadding),
      );
    });

    testWidgets('holds the last scrolled pixel clear of the nav band', (
      final tester,
    ) async {
      const bottomPadding = 34.0;
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: bottomPadding),
          ),
          child: MaterialApp(
            home: AppScreen(
              title: 'Frame',
              children: [SizedBox(height: 2000), Text('last')],
            ),
          ),
        ),
      );

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      // Same computation the sheet owns: the shell paints band 4 over the
      // content, and on a home-indicator device that band is taller than the
      // 56pt constant by the safe inset.
      final lastBottom = tester.getRect(find.text('last')).bottom;
      final screenBottom = tester.getRect(find.byType(AppScreen)).bottom;
      expect(
        screenBottom - lastBottom,
        greaterThanOrEqualTo(AppLayout.navBandHeight + bottomPadding),
      );
    });

    testWidgets('fill form pins a control below the header and fills the rest', (
      final tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScreen.fill(
            title: 'Frame',
            pinned: const SizedBox(height: 40, child: Text('segments')),
            child: ListView(children: const [Text('body')]),
          ),
        ),
      );

      final pinnedBottom = tester.getRect(find.text('segments')).bottom;
      final bodyTop = tester.getRect(find.text('body')).top;
      expect(bodyTop, greaterThanOrEqualTo(pinnedBottom));
    });

    testWidgets('renders no FAB when a screen supplies none', (
      final tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppScreen(title: 'Frame', children: [Text('content')]),
        ),
      );

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}

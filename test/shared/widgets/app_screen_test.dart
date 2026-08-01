import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/shared/widgets/nav_band_scope.dart';

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
            home: NavBandScope(
              child: AppScreen(
                title: 'Frame',
                floatingActionButton: FloatingActionButton(
                  onPressed: null,
                  child: Icon(Icons.add),
                ),
                children: [Text('content')],
              ),
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
            home: NavBandScope(
              child: AppScreen(
                title: 'Frame',
                children: [SizedBox(height: 2000), Text('last')],
              ),
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

    testWidgets('reserves nothing for a band the shell does not paint', (
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

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();

      // `/settings-panel` is pushed on the **root** navigator, outside the
      // shell — there is no band 4 over it, so reserving 56pt for one is dead
      // space at the end of every settings list. The frame reserves the safe
      // inset and the trailing gap, and nothing for a band that is not there.
      final lastBottom = tester.getRect(find.text('last')).bottom;
      final screenBottom = tester.getRect(find.byType(AppScreen)).bottom;
      expect(
        screenBottom - lastBottom,
        closeTo(AppLayout.contentBottomGap + bottomPadding, 0.5),
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

    testWidgets('a pushed screen gets a back affordance; a root screen does not', (
      final tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const AppScreen(title: 'Root', children: [Text('root')]),
        ),
      );

      // A tab root cannot pop, so the frame must not offer a way back that
      // would do nothing. The affordance is a fact about the route, not a flag
      // a screen remembers to pass.
      expect(find.bySemanticsLabel('Back'), findsNothing);

      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const AppScreen(title: 'Detail', children: [Text('detail')]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Back'), findsOneWidget);
    });

    testWidgets('the back affordance meets the touch floor without moving the '
        'title baseline or growing band 2', (final tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const AppScreen(title: 'Frame', children: [Text('root')]),
        ),
      );
      final rootTitle = tester.getRect(find.text('Frame'));

      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const AppScreen(title: 'Frame', children: [Text('detail')]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final back = tester.getRect(find.bySemanticsLabel('Back'));
      expect(back.height, greaterThanOrEqualTo(44));
      expect(back.width, greaterThanOrEqualTo(44));

      // Band 2 is the same height on a detail screen as on a tab root — a
      // header that grows to hold a control is the drift the frame removes.
      final detailTitle = tester.getRect(find.text('Frame').last);
      expect(detailTitle.center.dy, rootTitle.center.dy);
      expect(tester.getRect(find.text('detail')).top, greaterThanOrEqualTo(
        AppLayout.headerHeight + AppLayout.contentTopGap,
      ));
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

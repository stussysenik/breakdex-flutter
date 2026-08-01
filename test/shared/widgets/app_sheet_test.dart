import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/shared/widgets/app_sheet.dart';
import 'package:breakdex/shared/widgets/nav_band_scope.dart';

/// The band-4 clearance contract, measured at three viewport heights.
///
/// The shell draws band 4 over the body it hands the nested navigator, so the
/// sheet's own viewport extends underneath it. Every case here fails against a
/// bare `showModalBottomSheet` — that is the clipping the owner reported on
/// the "Plan a combo" sheet.
void main() {
  const bottomPadding = 34.0; // a home-indicator-class safe inset

  Future<void> openSheet(
    final WidgetTester tester, {
    required final Size viewport,
    required final Widget body,
    final bool inShell = true,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late BuildContext screenContext;
    await tester.pumpWidget(
      MaterialApp(
        // Below MaterialApp, so the real view size survives and only the safe
        // inset is substituted.
        builder: (final context, final child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(bottom: bottomPadding),
          ),
          // Above the `Navigator`, exactly as the shell sits above its branch
          // navigator — a modal route is a sibling of `home`, not a child of
          // it, so a scope declared at `home` would never reach the sheet.
          child: _maybeShell(inShell, child!),
        ),
        home: Builder(
          builder: (final context) {
            screenContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    // Resolves only on dismissal, which these tests never do.
    unawaited(showAppSheet<void>(context: screenContext, builder: (_) => body));
    await tester.pumpAndSettle();
  }

  for (final height in <double>[600, 800, 1000]) {
    testWidgets('sheet content clears band 4 at ${height.toInt()}pt tall', (
      final tester,
    ) async {
      await openSheet(
        tester,
        viewport: Size(400, height),
        // A SafeArea inside the body is the common shape; the helper must not
        // let it double-count the home indicator either.
        body: const SafeArea(child: SizedBox(height: 120, child: Text('last'))),
      );

      final contentBottom = tester.getRect(find.text('last')).bottom;
      expect(
        height - contentBottom,
        greaterThanOrEqualTo(AppLayout.navBandHeight + bottomPadding),
        reason: 'the last row would sit under the nav band',
      );
      // Not merely "far enough": the safe inset must be counted once, not
      // twice, or every sheet grows a dead strip the width of the indicator.
      expect(
        height - contentBottom,
        lessThan(AppLayout.navBandHeight + (bottomPadding * 2)),
        reason: 'safe-area padding was applied twice',
      );
    });
  }

  testWidgets('a sheet on a root-navigator route reserves no band', (
    final tester,
  ) async {
    await openSheet(
      tester,
      viewport: const Size(400, 800),
      inShell: false,
      body: const SafeArea(child: SizedBox(height: 120, child: Text('last'))),
    );

    // `/settings-panel*` is outside the shell. Reserving 56pt there floats the
    // sheet's last row above its own bottom edge for a band that is not drawn.
    final contentBottom = tester.getRect(find.text('last')).bottom;
    expect(800 - contentBottom, closeTo(bottomPadding, 0.5));
  });
}

Widget _maybeShell(final bool inShell, final Widget child) =>
    inShell ? NavBandScope(child: child) : child;

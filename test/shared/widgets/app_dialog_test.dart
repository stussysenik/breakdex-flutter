import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/shared/widgets/app_dialog.dart';

/// The dialog clamp contract.
///
/// A dialog is centred, so band 4 never clips it — it is pushed on the **root**
/// navigator, above the shell, and paints over the band. What a dialog needs
/// instead is a bound: a measure it may not exceed on a wide window, and a
/// height it may not exceed on a short one.
/// The painted dialog box.
///
/// Not the `AlertDialog` element: that one builds a `Dialog`, whose outermost
/// render box is the full-screen `AnimatedPadding` the barrier sits behind. The
/// surface a user sees is the `Material` inside it.
Rect _card(final WidgetTester tester) => tester.getRect(
  find
      .descendant(of: find.byType(AlertDialog), matching: find.byType(Material))
      .first,
);

void main() {
  const safeTop = 44.0;
  const safeBottom = 34.0;

  Future<void> openDialog(
    final WidgetTester tester, {
    required final Size viewport,
    required final Widget dialog,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late BuildContext screenContext;
    await tester.pumpWidget(
      MaterialApp(
        builder: (final context, final child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: safeTop, bottom: safeBottom),
          ),
          child: child!,
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
    unawaited(
      showAppDialog<void>(context: screenContext, builder: (_) => dialog),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a dialog on a wide window keeps a dialog measure', (
    final tester,
  ) async {
    await openDialog(
      tester,
      viewport: const Size(1400, 900),
      dialog: const AlertDialog(
        title: Text('Discard edits?'),
        content: Text(
          'You have unsaved changes to this video. Discarding them cannot be '
          'undone, and the original file on disk is left exactly as it was '
          'before the editor opened it.',
        ),
      ),
    );

    // Flutter's own bound is `insetPadding` — 40pt of gutter, whatever the
    // window. On the ranked-#1 surface that is a 1320pt-wide confirm box.
    expect(_card(tester).width, lessThanOrEqualTo(AppLayout.dialogMaxWidth));
  });

  // Green before the clamp existed as well as after: `Dialog` already wraps
  // itself in a `SafeArea`, so height was never the defect the task assumed.
  // This is the guard that keeps it that way — the clamp above must not grow
  // into a second owner of the vertical inset.
  testWidgets('a tall dialog stops inside the safe region', (
    final tester,
  ) async {
    const height = 600.0;
    await openDialog(
      tester,
      viewport: const Size(400, height),
      dialog: const AlertDialog(
        title: Text('Long'),
        content: SizedBox(height: 2000, child: Text('tall')),
      ),
    );

    final rect = _card(tester);
    expect(rect.top, greaterThanOrEqualTo(safeTop));
    expect(rect.bottom, lessThanOrEqualTo(height - safeBottom));
    // Not merely "inside": the safe inset must be counted once. Counting it
    // twice shrinks every dialog by 78pt of dead margin it never asked for.
    expect(
      rect.height,
      greaterThan(height - safeTop - safeBottom - (safeTop + safeBottom)),
      reason: 'safe-area padding was applied twice',
    );
  });
}

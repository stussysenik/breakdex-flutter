import 'package:flutter/material.dart';

import 'package:breakdex/core/design/layout.dart';

/// Opens a dialog inside the stacked-viewport frame.
///
/// A dialog is **not** a sheet, and the difference is where it lives. A sheet
/// opened inside the tab shell is pushed on that branch's nested navigator,
/// underneath the band the shell paints over the body — which is why
/// `showAppSheet` subtracts band 4. A dialog is pushed on the **root**
/// navigator (`showDialog` defaults to it, and no call site overrides that), so
/// its route is a sibling of the shell in the root stack, drawn *over* band 4.
/// Nothing covers a dialog, and nothing here reserves space for the band.
///
/// What a dialog needs instead is a measure it may not exceed. Material's only
/// bound is `insetPadding` — a 40pt gutter, whatever the window — so on a
/// 1400pt browser window a two-sentence confirm box is painted 1320pt wide.
/// Flutter Web is the ranked-#1 surface, so that is a product defect on the
/// primary platform. This helper clamps the box the dialog is laid out in to
/// [AppLayout.dialogMaxWidth]; Material's own gutter sits inside that, so the
/// painted card is at most 400pt — the same box a 480pt phone gives it. A
/// dialog therefore reads identically on a desktop window and in the hand.
///
/// Height is deliberately **not** re-computed. `Dialog` already wraps itself in
/// a `SafeArea` and 24pt of vertical inset, and measurement confirms a dialog
/// with 2000pt of content stops inside the safe region unaided. Adding a second
/// clamp would only risk counting the safe inset twice — the exact defect
/// `showAppSheet` had to remove padding to avoid. The test guards the height
/// contract; it does not re-own it.
Future<T?> showAppDialog<T>({
  required final BuildContext context,
  required final WidgetBuilder builder,
  final bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (final dialogContext) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidth),
        child: builder(dialogContext),
      ),
    ),
  );
}

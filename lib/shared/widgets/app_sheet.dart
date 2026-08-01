import 'package:flutter/material.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';

/// Opens a modal bottom sheet inside the stacked-viewport frame.
///
/// A sheet opened from a screen inside the tab shell is pushed onto that
/// branch's nested `Navigator`, which lives inside the shell's `Scaffold`
/// **body** — and the shell draws band 4 over that body (`extendBody: true`).
/// So the viewport Flutter measures for the sheet runs all the way to the
/// physical bottom, while the last `navBandHeight + padding.bottom` of it is
/// covered by the blurred nav band. A sheet flush to that edge has its final
/// row and its safe inset hidden underneath it — the "Plan a combo" clipping.
///
/// This helper owns that inset once, the way `AppScreen` owns it for screens.
/// No call site computes `kBottomNavigationBarHeight + padding.bottom` again.
///
/// The bottom safe-area padding is *removed* from the subtree before the inset
/// is applied, so a body that wraps itself in a `SafeArea` (most of them do)
/// does not count the home indicator a second time. The guarantee therefore
/// holds whatever the body is built from.
///
/// Keyboard insets are deliberately untouched: `viewInsets` still reaches the
/// body, so a sheet that lifts itself above the keyboard keeps doing so.
///
/// [backgroundColor] exists for the one legitimate variant: a body that paints
/// its own container passes `Colors.transparent` so the frame does not draw a
/// second surface behind it. Every other kind of per-site chrome — a different
/// radius, sharp corners, a drag handle on one sheet only — is the drift this
/// helper removes, and has no parameter.
Future<T?> showAppSheet<T>({
  required final BuildContext context,
  required final WidgetBuilder builder,
  final bool isScrollControlled = true,
  final bool isDismissible = true,
  final bool enableDrag = true,
  final Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    // The top edge is a coordinate too: a scroll-controlled sheet tall enough
    // to reach band 1 must stop at the safe area, not slide under the status
    // bar. Flutter's flag wraps with `SafeArea(bottom: false)`, so it never
    // fights the bottom inset computed below.
    useSafeArea: true,
    backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (final sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return MediaQuery.removePadding(
        context: sheetContext,
        removeBottom: true,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: AppLayout.navBandHeight + media.padding.bottom,
          ),
          child: builder(sheetContext),
        ),
      );
    },
  );
}

import 'package:flutter/widgets.dart';

/// Declares that band 4 is painted over everything below this point.
///
/// The shell wraps its branch navigator in one. Routes pushed on the **root**
/// navigator — `/settings-panel*`, the editors, `/auth` — are siblings of the
/// shell in the root stack, not descendants of it, so they never find this
/// scope and are told the truth: nothing is drawn over their bottom edge.
///
/// Presence *is* the value, which is why there is no field. Band 4's height is
/// [AppLayout.navBandHeight] on every route that has one; the only question a
/// surface ever needs answered is whether it has one, and the widget tree is
/// the honest place to ask — a route-path allowlist would drift from the router
/// the first time a screen moved between navigators.
class NavBandScope extends InheritedWidget {
  const NavBandScope({super.key, required super.child});

  /// Whether band 4 is painted below [context].
  static bool of(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavBandScope>() != null;

  @override
  bool updateShouldNotify(final NavBandScope oldWidget) => false;
}

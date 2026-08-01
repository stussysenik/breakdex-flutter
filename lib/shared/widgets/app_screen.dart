import 'dart:async';

import 'package:flutter/material.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_breadcrumb.dart';
import 'package:breakdex/shared/widgets/nav_band_scope.dart';

/// The one screen frame. Every top-level surface is built from this.
///
/// It renders bands 1, 2 and 4 of the stacked-viewport model identically on
/// every screen (see `AppLayout`), so switching views swaps only the content.
/// Screens do not build their own `Scaffold`, `AppBar`, or `SliverAppBar` —
/// doing so re-introduces the per-screen header drift this type removes.
///
/// Three forms:
/// - default — a single scrolling column, the **one-scroll** default.
/// - [AppScreen.slivers] — for grids and lazy lists that need sliver control.
/// - [AppScreen.fill] — for a content band that manages its own scrolling
///   (an `IndexedStack` of views, each already a list).
///
/// The two scrolling forms apply the gutter, the reading-width clamp, and the
/// nav-band inset, so no caller has to remember them. [AppScreen.fill] applies
/// the clamp and the top gap only — its child owns its padding, because a
/// frame that padded it too would double every edge.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.floatingActionButton,
    this.pinned,
    this.wide = false,
    this.backIdentifier = _defaultBackIdentifier,
  }) : slivers = null,
       child = null;

  /// Sliver form, for content that must lazily build (grids, long lists).
  ///
  /// Callers supply bare slivers; the gutter, clamp and bottom inset are still
  /// applied by the frame. Do not add a `SliverAppBar` — the header band is
  /// already rendered above these slivers.
  const AppScreen.slivers({
    super.key,
    required this.title,
    required List<Widget> this.slivers,
    this.actions = const [],
    this.floatingActionButton,
    this.pinned,
    this.wide = false,
    this.backIdentifier = _defaultBackIdentifier,
  }) : children = const [],
       child = null;

  /// Fill form, for a content band that is not one scroll view the frame can
  /// pad — an `IndexedStack` whose branches each scroll themselves.
  ///
  /// The frame still owns bands 1, 2 and 4 and the width clamp; the child owns
  /// its own padding and its own bottom inset — [bottomInsetOf], the same sum
  /// the scrolling forms apply.
  const AppScreen.fill({
    super.key,
    required this.title,
    required Widget this.child,
    this.actions = const [],
    this.floatingActionButton,
    this.pinned,
    this.wide = false,
    this.backIdentifier = _defaultBackIdentifier,
  }) : children = const [],
       slivers = null;

  /// Screen title. Always rendered at the same baseline, in `titleLarge`.
  /// A screen whose title needs bespoke styling is asking for a different
  /// frame, which is the thing this type refuses.
  final String title;

  /// Trailing action cluster in the header band. Keep to three or fewer;
  /// beyond that the header stops reading as a fixed anchor.
  final List<Widget> actions;

  /// Floating action affordance for the screen's primary create action.
  ///
  /// The frame owns the `Scaffold`, so it also owns the FAB slot — and with it
  /// the nav-band inset every screen used to hand-roll as
  /// `kBottomNavigationBarHeight + padding.bottom`. The shell draws band 4 over
  /// this screen (`extendBody: true`), so an un-inset FAB sits under it.
  final Widget? floatingActionButton;

  /// A control that stays put directly under the header band — a segmented
  /// control, a filter row. It sits inside the content band, not inside band 2:
  /// the header keeps its fixed height on every screen, and a screen that needs
  /// a persistent control gets one without growing the band.
  final Widget? pinned;

  final List<Widget> children;
  final List<Widget>? slivers;
  final Widget? child;

  /// Opt into the wider [AppLayout.maxWideWidth] clamp. For dense grids only —
  /// never for reading content, where a wide measure hurts legibility.
  final bool wide;

  /// Semantics identifier the automation flows select the back affordance by.
  ///
  /// Only the *name* is per-screen. Whether a screen has a back affordance at
  /// all is read from the route (`Navigator.canPop`), never passed as a flag:
  /// a tab root cannot pop, so it cannot offer a way back that does nothing,
  /// and a pushed screen cannot forget to offer one.
  final String backIdentifier;

  static const String _defaultBackIdentifier = 'screen-back';

  @override
  Widget build(final BuildContext context) {
    final maxWidth = wide ? AppLayout.maxWideWidth : AppLayout.maxContentWidth;
    final slivers = this.slivers;
    final child = this.child;
    final pinned = this.pinned;
    final fab = floatingActionButton;
    // The shell paints band 4 over this screen, and on a home-indicator device
    // that band is `navBandHeight + padding.bottom` tall — the same sum
    // `showAppSheet` owns. A flat constant here under-reserves by the inset.
    final bottomInset = bottomInsetOf(context);
    final contentPadding = EdgeInsets.fromLTRB(
      AppLayout.gutter,
      AppLayout.contentTopGap,
      AppLayout.gutter,
      bottomInset,
    );

    // The frame owns the Material surface. Screens no longer build a Scaffold,
    // so if this one went away every InkWell below would lose its ancestor.
    return Scaffold(
      floatingActionButton: fab == null
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom:
                    bandInsetOf(context) +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: fab,
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBand(
              title: title,
              actions: actions,
              maxWidth: maxWidth,
              backIdentifier: (Navigator.maybeOf(context)?.canPop() ?? false)
                  ? backIdentifier
                  : null,
            ),
            if (pinned != null)
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.gutter,
                      AppLayout.contentTopGap,
                      AppLayout.gutter,
                      AppLayout.contentTopGap,
                    ),
                    child: pinned,
                  ),
                ),
              ),
            Expanded(
              // topCenter, never Center: the clamp is horizontal only. Centring
              // vertically would let short content float away from the header
              // and break the one invariant this frame exists to hold.
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: switch ((slivers, child)) {
                    (final s?, _) => CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: contentPadding,
                          sliver: SliverMainAxisGroup(slivers: s),
                        ),
                      ],
                    ),
                    (_, final c?) => Padding(
                      padding: EdgeInsets.only(
                        top: pinned == null ? AppLayout.contentTopGap : 0,
                      ),
                      child: c,
                    ),
                    _ => SingleChildScrollView(
                      padding: contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What band 4 costs at the bottom of *this* route: the band's height where
  /// the shell paints one, nothing where it does not.
  ///
  /// `/settings-panel*` is pushed on the root navigator, outside the shell, so
  /// there is no band over it and an inset reserved for one is dead space at
  /// the end of every list. The frame asks the tree ([NavBandScope]) rather
  /// than taking a per-screen flag, for the same reason the back affordance is
  /// read from the route: a screen cannot get a fact about its surroundings
  /// wrong if it is never asked for one.
  static double bandInsetOf(final BuildContext context) =>
      NavBandScope.of(context) ? AppLayout.navBandHeight : 0;

  /// The bottom inset a `fill` child must reserve at the end of its own scroll,
  /// so it ends exactly where the frame's own scrolling forms end.
  static double bottomInsetOf(final BuildContext context) =>
      bandInsetOf(context) +
      AppLayout.contentBottomGap +
      MediaQuery.of(context).padding.bottom;
}

/// Band 2. Fixed height, fixed baseline, on every screen.
class _HeaderBand extends StatelessWidget {
  const _HeaderBand({
    required this.title,
    required this.actions,
    required this.maxWidth,
    required this.backIdentifier,
  });

  final String title;
  final List<Widget> actions;
  final double maxWidth;

  /// Non-null exactly when this route can pop.
  final String? backIdentifier;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: AppLayout.headerHeight,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppBreadcrumb(),
                const SizedBox(height: AppLayout.crumbGap),
                Row(
                  children: [
                    if (backIdentifier != null)
                      _BackAffordance(identifier: backIdentifier!),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The way back up the address line.
///
/// A chevron and nothing else: the crumb line rendered directly above it
/// already *says* where back goes, so a word here would be the same fact typed
/// twice — and the two would drift the first time a route was renamed. It
/// occupies [AppLayout.backSlot] square so the target clears the touch floor
/// while the glyph stays on the gutter line the crumbs start from.
///
/// It **asks** the route to pop rather than popping it. `Navigator.maybePop` is
/// the same question the system back gesture asks, so a screen that must refuse
/// — unsaved edits, a battle in progress — declares that once with a [PopGuard]
/// and both entry points honour it. The alternative was the state this replaces:
/// a screen that could not trust the frame's back hid it and hand-rolled a close
/// control, which is exactly how bespoke chrome grows back.
class _BackAffordance extends StatelessWidget {
  const _BackAffordance({required this.identifier});

  final String identifier;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      identifier: identifier,
      label: 'Back',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(Navigator.maybePop(context)),
        child: SizedBox.square(
          dimension: AppLayout.backSlot,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppIconView(
              AppIcon.back,
              color: colorScheme.secondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// How a screen with state it would lose refuses a pop.
///
/// The refusal is a fact about the *screen*, so the screen declares it; the
/// frame keeps one back affordance and never learns which screens are special.
/// [blocked] says a pop would cost something right now; [confirm] asks the
/// person and returns whether to leave anyway. Both the frame's chevron and the
/// system back gesture route through the same declaration, because both go
/// through `Navigator.maybePop`.
class PopGuard extends StatefulWidget {
  const PopGuard({
    super.key,
    required this.blocked,
    required this.confirm,
    required this.child,
  });

  /// True while leaving would discard something the person cannot get back.
  final bool blocked;

  /// Asks whether to leave anyway. Returning false keeps the screen.
  final Future<bool> Function(BuildContext context) confirm;

  final Widget child;

  @override
  State<PopGuard> createState() => _PopGuardState();
}

class _PopGuardState extends State<PopGuard> {
  /// Two back taps while the dialog is up must not queue two confirms.
  bool _asking = false;

  @override
  Widget build(final BuildContext context) => PopScope<Object?>(
    canPop: !widget.blocked,
    onPopInvokedWithResult: (final didPop, final _) async {
      if (didPop || _asking) return;
      _asking = true;
      // Captured before the await: after it, this context may be gone.
      final navigator = Navigator.of(context);
      final leave = await widget.confirm(context);
      _asking = false;
      // `Navigator.pop` does not consult the guard, which is what makes the
      // consented exit possible while `canPop` is still false.
      if (leave && mounted) navigator.pop();
    },
    child: widget.child,
  );
}

/// A titled group inside a content band.
///
/// Sections are how the content band keeps its rhythm: [AppLayout.sectionGap]
/// above each one, [AppLayout.itemGap] between the items inside it. Screens
/// that space their own blocks with ad-hoc `SizedBox`es drift apart again.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.children,
    this.title,
    this.first = false,
  });

  final String? title;
  final List<Widget> children;

  /// The first section on a screen sits directly under the header gap and
  /// takes no leading section gap.
  final bool first;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = this.title;
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppLayout.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title.toUpperCase(),
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppLayout.itemGap),
          ],
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppLayout.itemGap),
            children[i],
          ],
        ],
      ),
    );
  }
}

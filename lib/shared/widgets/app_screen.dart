import 'package:flutter/material.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_breadcrumb.dart';

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
  }) : children = const [],
       child = null;

  /// Fill form, for a content band that is not one scroll view the frame can
  /// pad — an `IndexedStack` whose branches each scroll themselves.
  ///
  /// The frame still owns bands 1, 2 and 4 and the width clamp; the child owns
  /// its own padding and its own bottom inset ([AppLayout.scrollBottomInset]
  /// plus the safe inset, exactly as the scrolling forms compute it).
  const AppScreen.fill({
    super.key,
    required this.title,
    required Widget this.child,
    this.actions = const [],
    this.floatingActionButton,
    this.pinned,
    this.wide = false,
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
                    AppLayout.navBandHeight +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: fab,
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBand(title: title, actions: actions, maxWidth: maxWidth),
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

  /// The bottom inset a `fill` child must reserve at the end of its own scroll,
  /// so it clears band 4 exactly as the frame's own scrolling forms do.
  static double bottomInsetOf(final BuildContext context) =>
      AppLayout.scrollBottomInset + MediaQuery.of(context).padding.bottom;
}

/// Band 2. Fixed height, fixed baseline, on every screen.
class _HeaderBand extends StatelessWidget {
  const _HeaderBand({
    required this.title,
    required this.actions,
    required this.maxWidth,
  });

  final String title;
  final List<Widget> actions;
  final double maxWidth;

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

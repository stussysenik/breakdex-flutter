/// The stacked-viewport layout constitution.
///
/// Every screen in this app is the **same frame** with different filling. Bands
/// 1, 2 and 4 below are identical on every screen and never move; only the
/// content band changes. Switching tabs must feel like swapping the contents of
/// one persistent viewport, not like arriving at a differently-built page.
///
/// ```
///  ┌──────────────────────────┐
///  │ safe area (system)       │  band 1 — system owned
///  ├──────────────────────────┤
///  │ HEADER      [actions]    │  band 2 — [headerHeight], title on a fixed baseline
///  ├──────────────────────────┤
///  │                          │
///  │  content (scrolls)       │  band 3 — the ONLY band that varies
///  │                          │
///  ├──────────────────────────┤
///  │ ◇  ◇  ◇  ◇               │  band 4 — [navBandHeight], shell owned
///  └──────────────────────────┘
/// ```
///
/// The frame is enforced by `AppScreen` (`lib/shared/widgets/app_screen.dart`),
/// not by convention. A screen that builds its own `Scaffold`/`AppBar`/
/// `SliverAppBar` has opted out of the constitution and is a review violation.
///
/// See `docs/design/TOKENS.md` → **Layout & Grid** for the prose rules and the
/// per-screen conformance ledger.
abstract final class AppLayout {
  // ── Band geometry ────────────────────────────────────────────────────────

  /// Height of the header band, measured below the safe area.
  ///
  /// 72 = the `titleLarge` line box (36) centred in 18/18 padding. On the 8pt
  /// grid, so content below it stays on grid too. This is a constant, not a
  /// range: no collapsing, floating, or `.large` variants — a title that moves
  /// between screens is the exact discontinuity this file exists to remove.
  static const double headerHeight = 72;

  /// Gap between the header band and the first content pixel.
  ///
  /// Content therefore always begins at `headerHeight + contentTopGap` = 80
  /// below the safe area, on every screen, with no exceptions.
  static const double contentTopGap = 8;

  /// Height of the bottom navigation band.
  ///
  /// The shell renders it over the content (`extendBody: true`), so scroll
  /// views must reserve [scrollBottomInset] rather than assume it is clipped.
  static const double navBandHeight = 56;

  /// Bottom padding a scrolling content band must reserve so its last element
  /// clears the translucent nav band instead of hiding beneath it.
  static const double scrollBottomInset = navBandHeight + 16;

  // ── Horizontal grid ──────────────────────────────────────────────────────

  /// Horizontal gutter, left and right, on every screen.
  ///
  /// Mirrors `AppSpacing.screenEdge`. Named here as well because the gutter is
  /// a *layout* invariant — it defines the content column's edges — while
  /// `AppSpacing` is a scale of arbitrary gaps.
  static const double gutter = 24;

  /// Maximum width of a reading column.
  ///
  /// Above this the column centres and the gutters grow. Text measured wider
  /// than this is hard to read, and Flutter Web is the ranked-#1 surface, so
  /// an unclamped column is a product defect on the primary platform.
  static const double maxContentWidth = 720;

  /// Maximum width of a dense/grid content band (media grids, boards) where
  /// more columns genuinely beat a narrower measure.
  static const double maxWideWidth = 1080;

  // ── Breakpoints ──────────────────────────────────────────────────────────

  /// Below this the layout is single-column and stacks.
  static const double breakpointCompact = 600;

  /// At or above this the layout may use side-by-side regions.
  static const double breakpointExpanded = 1024;

  // ── Vertical rhythm ──────────────────────────────────────────────────────

  /// The baseline unit. Every vertical measurement resolves to a multiple of
  /// this; every *block* height resolves to a multiple of [blockGrid].
  static const double baseline = 4;

  /// Block grid. Card heights, row heights, and section heights land here.
  static const double blockGrid = 8;

  /// Gap between two sections of a screen.
  static const double sectionGap = 32;

  /// Gap between sibling items inside one section.
  static const double itemGap = 12;

  /// Padding inside a card or panel.
  static const double cardPadding = 16;

  /// Minimum height of any tappable row. Also the a11y touch-target floor.
  static const double rowHeight = 56;

  /// Resolves the content column width for a viewport, honouring the clamp.
  static double contentWidthFor(final double viewportWidth, {final bool wide = false}) {
    final max = wide ? maxWideWidth : maxContentWidth;
    final available = viewportWidth - (gutter * 2);
    return available < max ? available : max;
  }

  /// Snaps a raw dimension up onto the block grid.
  ///
  /// For composing new blocks — never for retro-fitting a bespoke value that a
  /// designer chose deliberately. Snapping is a mechanical conformance move;
  /// changing an intentional off-grid value is a design decision.
  static double snap(final double raw) => (raw / blockGrid).ceil() * blockGrid;
}

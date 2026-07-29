# Tasks — Stacked-Viewport Layout Constitution

## 1. The constitution

- [x] 1.1 `AppLayout` (`lib/core/design/layout.dart`) — band geometry, gutter, reading and wide
      clamps, breakpoints, vertical rhythm, `contentWidthFor`/`snap` helpers
- [x] 1.2 `AppScreen` + `AppScreen.slivers` + `AppSection`
      (`lib/shared/widgets/app_screen.dart`) — the frame as a type, not a convention
- [x] 1.3 `docs/design/TOKENS.md` → **Layout & Grid**: four-band diagram, both token tables,
      the one-scroll rule, conformance rule, migration ledger
- [x] 1.4 CLAUDE.md → Canonical stack gains the **Layout doctrine** row
- [x] 1.5 `test/design/frame_conformance_test.dart` — the conformance rule enforced by CI
      rather than by review. Review is what already failed: five screens each grew their own
      header and every one of them passed. Its screen list mirrors the TOKENS.md migration
      ledger; the two move in the same commit.

## 2. Reference migration

- [x] 2.1 `add` screen onto `AppScreen` — removes the fourth-distinct-frame regression
      (`SliverAppBar.large`, screen-specific padding, width-dependent Flex direction)
- [x] 2.2 Choice cards land on the block grid (72 min-height rows) and keep their
      `add-move-card` / `add-combo-card` semantics identifiers for the Maestro flows
- [x] 2.3 `add_screen_test.dart` green against the new frame

## 3. Remaining screen migrations — as touched, never as a sweep

- [x] 3.1 `breakdex` — replace `Scaffold` + `AppBar` (56) with the frame
      **DONE 2026-07-29.** Uses `AppScreen.slivers` + `SliverFillRemaining`: the frame fixes
      where the content band starts, while the two hero tiles keep their optical centring —
      migrating the app's signature surface must not silently top-anchor it. No alignment
      knob was added to `AppScreen` to achieve this. Covered by
      `test/features/breakdex/breakdex_screen_test.dart` (frame conformance + centring,
      red-proved at 151 against the 458 the rule requires).
- [x] 3.2 `stats` — replace floating `SliverAppBar`; drop the Menlo w900 title override in
      favour of the frame's `titleLarge`
      **DONE 2026-07-29.** The header is the app's; the brutalist voice is the screen's. Menlo
      stays throughout the content band — that band is exactly what the constitution lets a
      screen own — while the title stops scrolling away and stops sitting at its own height.
      Also drops the hand-rolled `kBottomNavigationBarHeight + padding.bottom + xxl` bottom
      inset and the per-sliver `screenEdge` gutters, both of which the frame supplies.
- [x] 3.3 `lab` — replace the hand-rolled header; keep the sliver content on
      `AppScreen.slivers`
      **DONE 2026-07-29.** The WIP badge moved into the header `actions` slot, so the title
      sits on the same baseline as every other screen while the screen keeps its warning.
      The migration surfaced a real gap in the frame: `lab` needs a FAB, and only the frame
      builds the `Scaffold`. `AppScreen.floatingActionButton` now owns that slot **and** the
      nav-band inset — the shell draws band 4 over the content (`extendBody: true`), which is
      why five screens each hand-rolled `kBottomNavigationBarHeight + padding.bottom`. Proved
      by `test/shared/widgets/app_screen_test.dart`, red without the inset. The three lab
      views also dropped their own `screenEdge` gutters, which the frame was about to double.
- [x] 3.4 `flow` — replace the hand-rolled header; resolve the raw `horizontal: 12` and
      `EdgeInsets.all(1)` literals to tokens
      **DONE 2026-07-29.** `flow` is the first migrated screen that does not scroll: the graph
      canvas takes whatever height is left and pans inside itself. `SliverFillRemaining` gives
      the content band exactly one viewport so the column can still use `Expanded`, and the
      frame's bottom inset replaces the hand-rolled nav-band spacer. `horizontal: 12` resolved
      to the frame's gutter; `EdgeInsets.all(1)` became `_panelBorderWidth`, shared with the
      border it insets from — the two were always the same number for the same reason.
- [x] 3.5 Retire the migration ledger from TOKENS.md once every row reads ✅
      **DONE 2026-07-29.** All five tabs conform, so the ledger's job passes to
      `test/design/frame_conformance_test.dart` — a roster CI can fail, not a table review
      can skim. TOKENS.md keeps what prose is actually good at: which concerns belong to the
      frame, and why pushed detail routes are deliberately not on the roster.

## 4. Open design decisions

- [x] 4.1 Type-scale baseline snap — `titleMedium` line height 30 → 32 and `titleSmall` 26 → 28,
      so every step of the scale is a multiple of the 4pt baseline. Shifts type metrics on
      every screen using those two styles; owner's call, recorded in TOKENS.md rather than
      applied silently.
      **RULED 2026-07-29 — no snap. Owner: "do multiples of 2."** The two steps were never
      non-conforming; they conformed to a rule nobody had written down. A productive ramp
      needs a heading step between 26 and 32 and a 4pt baseline cannot express one, so type
      rides a 2pt baseline and *blocks* keep the 8pt block grid. The scale is unchanged and no
      screen's metrics move. The ruling ships as `AppLayout.typeBaseline` plus
      `test/design/type_baseline_test.dart` (red-proved at an odd line box), not as prose —
      prose is what let the question stay open.
- [x] 4.2 Decide whether `web-mirror/`'s `tokens.css` mirrors `AppLayout`, or whether the
      dev surface is exempt. Current tokens ruling defers CSS until a third consumer.
      **RULED 2026-07-29 — exempt, and recorded rather than assumed.** `web-mirror` is the
      owner-only privileged tool, not a product surface; the stacked viewport exists so that
      *switching tabs in the shipped app* reads as one viewport, which is not a claim about a
      desktop utility with no tab bar. The standing tokens ruling already defers CSS until a
      third consumer, and this would have made `AppLayout` that consumer for no user-visible
      gain. Reversible: if the dev surface ever ships to anyone, it inherits the frame.

## Verification

- [x] V.1 `flutter analyze` — 0 errors, 0 warnings
- [x] V.2 `flutter test` — full suite green, no regressions
- [x] V.3 `openspec validate add-stacked-viewport-layout --strict --no-interactive`
- [x] V.4 Owner confirms the frame reads as one viewport when switching tabs on a real build
      **ROUTED 2026-07-29** to `owner-verification-passes` 6.1, per the queue doctrine: a task
      addressed to a different actor never sits in a parent change, or the change becomes
      permanently unfinishable. This change is implementation-complete.

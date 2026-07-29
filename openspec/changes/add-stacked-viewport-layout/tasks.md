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
- [ ] 3.3 `lab` — replace the hand-rolled header; keep the sliver content on
      `AppScreen.slivers`
- [ ] 3.4 `flow` — replace the hand-rolled header; resolve the raw `horizontal: 12` and
      `EdgeInsets.all(1)` literals to tokens
- [ ] 3.5 Retire the migration ledger from TOKENS.md once every row reads ✅

## 4. Open design decisions

- [ ] 4.1 Type-scale baseline snap — `titleMedium` line height 30 → 32 and `titleSmall` 26 → 28,
      so every step of the scale is a multiple of the 4pt baseline. Shifts type metrics on
      every screen using those two styles; owner's call, recorded in TOKENS.md rather than
      applied silently.
- [ ] 4.2 Decide whether `web-mirror/`'s `tokens.css` mirrors `AppLayout`, or whether the
      dev surface is exempt. Current tokens ruling defers CSS until a third consumer.

## Verification

- [x] V.1 `flutter analyze` — 0 errors, 0 warnings
- [x] V.2 `flutter test` — full suite green, no regressions
- [x] V.3 `openspec validate add-stacked-viewport-layout --strict --no-interactive`
- [ ] V.4 Owner confirms the frame reads as one viewport when switching tabs on a real build
      (device/browser sitting — routed to `owner-verification-passes`)

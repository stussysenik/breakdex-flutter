# Tasks — add-library-time-and-metadata-browsing

> **Phase dependencies:** Phase 1 is the foundation (pure model + comparators) and blocks
> everything else. Phases 2, 3, and 4 are independent of each other once Phase 1 lands and
> may fan out across sessions. Phase 5 is owner-gated (design.md O1) and additionally
> cross-change-blocked on `fix-video-backup-truth-and-unify-account` Phase 4.
> Ledger rule: tick in the same commit as the work, with terminal evidence.
> Doctrine gates on every UI task: `AppMotion` tokens only (no raw `Curve`/`Duration`
> literals), no new hard-coded user-facing strings (ARB + `scripts/check_l10n.sh`).

## Phase 1 — Sort model (pure, no UI)

- [ ] 1.1 `LibrarySort` enum (recentlyAdded, recentlyFilmed, recentlyPracticed,
  alphabetical) plus `effectiveDate` accessors for moves and combos implementing the
  design D2 fallback table. Pure functions in `lib/core/models/` — no Drift, no widgets.
  Verify: unit tests covering each dimension, the null-`videoCreationDate` fallback, the
  combo `lastEntryAt → updatedAt → createdAt` chain, and comparator stability for equal
  dates (ties break by name, so ordering is deterministic). `flutter analyze` clean.
- [ ] 1.2 Persisted sort provider alongside the existing `_viewModeProvider` pattern
  (SharedPreferences key `library_sort`), with a legacy-value-tolerant read like
  `ViewMode`'s migration at `move_list_screen.dart:56-65`. Default: recentlyAdded
  (today's behavior — a stored preference is never overridden by a new default).
  Verify: unit test for default, round-trip, and unknown stored value.

## Phase 2 — Sort + grouping in the library

- [ ] 2.1 Apply the comparator in the provider that already derives the filtered move and
  combo lists (design D1 — client-side; DAO ordering untouched). Verify: widget test via
  the pure-override harness (live Drift streams flake widget tests) asserting reorder on
  sort change; existing move-list tests green.
- [ ] 2.2 Sort control in the library header, composed with the existing
  `_PillToggleRow`/`_ViewModeToggle` idiom rather than a new control vocabulary.
  Localized. Verify: widget test, `scripts/check_l10n.sh` green.
- [ ] 2.3 Combo tab under a filmed-date sort falls back to recently-added and says so
  (spec: "Combos do not fake a capture date"). Verify: widget test for the fallback and
  its disclosure.
- [ ] 2.4 Month grouping for date sorts in scan and glance modes; no grouping in study
  mode or under A–Z (design D3). Relative labels for the current and prior month,
  absolute beyond. Verify: unit tests on the bucketing boundaries (month edge, year edge,
  local-time correctness), widget test asserting headers appear and disappear with the
  sort. Localized.

## Phase 3 — Dates on rows and tiles

- [ ] 3.1 Shared date-line presentation (relative for the recent past, absolute beyond)
  as one localized formatter reused by all row/tile widgets — not re-implemented per
  widget. Verify: unit tests across the relative/absolute boundary; l10n check green.
- [ ] 3.2 Render it on `_MoveRow`, `_MoveGridCell`, `_ComboRow`, and the combo grid cell,
  showing the date for the **active** sort (spec: "The displayed date follows the active
  sort"). Verify: widget tests per surface; visual density stays within TOKENS grid
  (8pt base / 4pt half-step).

## Phase 4 — Category recency

- [ ] 4.1 Extend the existing per-category count pass in `MoveCategoryScreen:36-43` to
  also compute most-recent activity (design D5 — same pass, no new query, no schema
  change). Verify: unit test on the aggregation incl. the empty-category case.
- [ ] 4.2 Show last-activity on `_CategoryTile` and add a recency ordering for the
  category grid; empty categories sort last, never hidden. Localized. Verify: widget
  test, l10n check green.

## Phase 5 — Provenance beyond the date (owner-gated)

- [ ] 5.1 [OWNER] Rule on O1: beyond the date, which provenance earns tile space — file
  size, original filename, backup state — or does the date line stand alone (visual-first
  default)? Also O2: global sort vs per-tab. Record rulings in design.md.
- [ ] 5.2 Implement the O1 ruling, if any. Visual encoding preferred over text where one
  exists (design D4).
- [ ] 5.3 Make the tile backup indicator honest. **Cross-change: blocked on
  `fix-video-backup-truth-and-unify-account` Phase 4** (4.2/4.3 land `copyCount` truth).
  Today the icon keys off `contentHash != null` — "tracked", not "backed up"
  (`move_grid_cell.dart:29-45`). Re-key it to real protection state once that count can
  be trusted; tick both ledgers per the cross-change rule. Verify: widget test for
  backed-up vs tracked-but-unprotected.

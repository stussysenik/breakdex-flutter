# Tasks — add-library-time-and-metadata-browsing

> **Phase dependencies:** Phase 1 is the foundation (pure model + comparators) and blocks
> everything else. Phases 2, 3, and 4 are independent of each other once Phase 1 lands and
> may fan out across sessions. Phase 5 is owner-gated (design.md O1) and additionally
> cross-change-blocked on `fix-video-backup-truth-and-unify-account` Phase 4.
> Ledger rule: tick in the same commit as the work, with terminal evidence.
> Doctrine gates on every UI task: `AppMotion` tokens only (no raw `Curve`/`Duration`
> literals), no new hard-coded user-facing strings (ARB + `scripts/check_l10n.sh`).

## Phase 1 — Sort model (pure, no UI)

- [x] 1.1 `LibrarySort` enum (recentlyAdded, recentlyFilmed, recentlyPracticed,
  alphabetical) plus `effectiveDate` accessors for moves and combos implementing the
  design D2 fallback table. Pure functions in `lib/core/models/` — no Drift, no widgets.
  Verify: unit tests covering each dimension, the null-`videoCreationDate` fallback, the
  combo `lastEntryAt → updatedAt → createdAt` chain, and comparator stability for equal
  dates (ties break by name, so ordering is deterministic). `flutter analyze` clean.
- [x] 1.2 Persisted sort provider alongside the existing `_viewModeProvider` pattern
  (SharedPreferences key `library_sort`), with a legacy-value-tolerant read like
  `ViewMode`'s migration at `move_list_screen.dart:56-65`. Default: recentlyAdded
  (today's behavior — a stored preference is never overridden by a new default).
  Verify: unit test for default, round-trip, and unknown stored value.

## Phase 2 — Sort + grouping in the library

- [x] 2.1 Apply the comparator in the provider that already derives the filtered move and
  combo lists (design D1 — client-side; DAO ordering untouched). Verify: widget test via
  the pure-override harness (live Drift streams flake widget tests) asserting reorder on
  sort change; existing move-list tests green.
  **Widened by 1.1 (design D2 note):** `watchLibraryRows` builds its `Combo` without
  `updatedAt` (`combos_dao.dart:475-484`), so the practiced chain's middle link is dead
  in the only surface that uses it — a combo with no jots sorts by `createdAt` even when
  it was edited yesterday. Add `c.updated_at` to that SELECT and hydrate it here; the
  comparator already reads it. Verify: the combo ordering test must distinguish
  edited-but-never-jotted from never-touched, which today it cannot.
  **DONE 2026-07-18.** `libraryMovesProvider` / `libraryCombosProvider` in
  `move_list_screen.dart` now own filter-then-sort; the screen reads them instead of the
  raw streams. **1.1's premise was one surface off:** the library's combo tab did not read
  `watchLibraryRows` at all — it read `watchAllWithMoveCounts` (`(Combo, int)` tuples,
  ordered by move count then name), so the practiced chain had no `lastEntryAt` there
  either, and jotting a combo does **not** stamp `combos.updatedAt`
  (`combo_note_entries_dao.dart:62-82`) — both middle links were dead, not one. The feed
  is now `watchLibraryRows` for both library surfaces, with `c.updated_at` added to that
  SELECT and hydrated; `LibraryRow` maps back to `(combo, moveCount)` at the sliver
  boundary, so no widget signature moved. Verified by driving the derivation providers
  against a real in-memory database rather than pumping the screen (live Drift streams
  flake widget tests). Binary truth: 7 tests, mutation-proven — removing both `..sort`
  calls goes −4, dropping the `updatedAt` hydration goes −2; the fixture gives all four
  sorts four *different* orders, none of them the feed's own `createdAt DESC`, so no sort
  can pass by coincidence. `flutter analyze` 0 errors (9 pre-existing infos), suite
  **1055 green / 9 pre-existing reds / 0 regressions**.
- [x] 2.2 Sort control in the library header, composed with the existing
  `_PillToggleRow`/`_ViewModeToggle` idiom rather than a new control vocabulary.
  Localized. Verify: widget test, `scripts/check_l10n.sh` green.
  **DONE 2026-07-18, under the O2 ruling (global, single key — recorded in design.md).**
  `LibrarySortToggle` is a third `_PillToggleRow`, sitting below the view-mode row: four
  pills (Added / Filmed / Practiced / A–Z), 4 new ARB keys, `HapticFeedback.selectionClick`
  and persistence through the existing `librarySortProvider`. It is public, unlike the
  other two toggles, so it can be pumped alone — the screen around it reads live Drift
  streams, which flake widget tests.
  **One shared-widget change was forced, not chosen:** `_PillToggleRow` rendered its label
  as a bare `Text` in a `Row`, which is fine at two and three pills and *overflows* at
  four. The label is now `Flexible` + ellipsis. This is load-bearing, not defensive — the
  narrow-screen test goes red when the wrapper is removed (320pt viewport, real overflow
  exception). Two and three pills lay out unchanged.
  Binary truth: 5 tests, each mutation-proven — removing `Flexible` reds the narrow-screen
  test, dropping the `setString` reds the persistence test, and hardcoding `build()` to the
  default reds the restore-stored-sort test. `flutter analyze` 0 errors (9 pre-existing
  infos), `scripts/check_l10n.sh` green, suite **1060 green / 9 pre-existing reds / 0
  regressions** (the 9 confirmed red on a clean stash of HEAD, incl. `preview_harness_smoke`).
- [x] 2.3 Combo tab under a filmed-date sort falls back to recently-added and says so
  (spec: "Combos do not fake a capture date"). Verify: widget test for the fallback and
  its disclosure.
  **DONE 2026-07-18.** `LibraryFilmedFallbackNotice` renders a caption under the sort row
  — "Combos have no filmed date — showing most recently added." — only for the
  filmed × combos pair, and `SizedBox.shrink()` everywhere else. It takes `sort` and
  `segment` as parameters rather than reading them, which is what makes it poolable as a
  pure pump; the screen around it reads live Drift streams that flake widget tests.
  The noun comes from `entityNamesProvider.comboPlural` (ARB placeholder), so a user who
  renamed combos sees their own word — a hardcoded "Combos" reds a test.
  **The ordering half needed no code**: `ComboLibrarySort.effectiveDate` already resolved
  `recentlyFilmed → createdAt` from 1.1. It was, however, unasserted at the provider
  level, so the fallback was only true by construction — now proven against a real
  in-memory database, using a fixture whose added order differs from its practiced order,
  so a fallback that leaked to `lastEntryAt`/`updatedAt` reds rather than passing by
  coincidence.
  Binary truth: 5 tests, mutation-proven — dropping the segment guard reds the moves-tab
  silence, hardcoding the noun reds the rename test, and pointing the combo filmed arm at
  the practiced chain reds the ordering test. `flutter analyze` 0 errors (9 pre-existing
  infos), `scripts/check_l10n.sh` green, suite **1065 green / 9 pre-existing reds / 0
  regressions**.
- [x] 2.4 Month grouping for date sorts in scan and glance modes; no grouping in study
  mode or under A–Z (design D3). Relative labels for the current and prior month,
  absolute beyond. Verify: unit tests on the bucketing boundaries (month edge, year edge,
  local-time correctness), widget test asserting headers appear and disappear with the
  sort. Localized.
  **DONE 2026-07-18.** Three pure functions in `lib/core/models/library_month_sections.dart`
  — `libraryMonthSections` (contiguous-run split, order preserved byte-for-byte, so
  grouping is a *projection* of the sort and can never re-order it),
  `libraryMonthLabel` (month-ordinal comparison, so the December→January edge is not a
  special case), and `libraryGroupsByMonth` — plus `LibraryMonthHeader` and the
  `librarySectionedSliver` wrapper in the screen.
  **The sliver shape is what kept this cheap.** Rather than interleaving headers into a
  flattened item list (which would have moved `_MoveRow`'s stagger index and every
  builder signature with it), the wrapper applies the caller's *existing* per-mode sliver
  builder once per section and joins them with `SliverMainAxisGroup`. Grid headers fall
  out as full-width rows for free, and no row/cell/grid widget changed at all.
  **Two things the executor should not have to re-derive.** Bucketing normalizes with
  `.toLocal()` — Drift hands back UTC for some columns, and bucketing the raw instant
  puts a late-evening capture in the following month for anyone west of UTC. That
  normalization has a test, but it is honestly **vacuous under `TZ=UTC`** (the two inputs
  are then the same wall clock), so it discriminates only off UTC; it is there because
  the behavior is load-bearing in production, not because it is provable everywhere.
  Second: a *future* month (a wrong device clock stamping a filmed date ahead) is
  absolute, not "This month" — a negative delta must not fall into the relative arm.
  **Not asserted:** the screen-level binding `dateOf: (m) => m.effectiveDate(sort)` — the
  one line tying the buckets to the *active* sort's dimension — is only reachable by
  pumping the screen, whose live Drift streams flake widget tests. The grouping and the
  date resolution are each proven; their junction is not.
  Binary truth: 23 tests (13 unit + 10 widget), **five** mutations each proven to red —
  dropping the study exclusion (−1), dropping the A–Z exclusion (−2), making the section
  split never split (−6), reading the label from the month number alone so December reads
  as "last month" from July (−3), and letting a future month fall into `thisMonth` (−1).
  `flutter analyze` 0 errors (9 pre-existing infos), suite **1088 green / 9 pre-existing
  reds / 0 regressions**, `scripts/check_l10n.sh` green, `flutter build web` green.

## Phase 3 — Dates on rows and tiles

- [x] 3.1 Shared date-line presentation (relative for the recent past, absolute beyond)
  as one localized formatter reused by all row/tile widgets — not re-implemented per
  widget. Verify: unit tests across the relative/absolute boundary; l10n check green.
  **DONE 2026-07-18.** Built before any surface renders it, which is the point of the
  task: there is no per-widget implementation to converge later.
  **Split in two, along the layering line this repo already holds.**
  `libraryDateLine` (`lib/core/models/library_date_line.dart`) classifies a date against
  `now` into `today` / `yesterday` / `daysAgo` / `absolute` with no Flutter at all;
  `formatLibraryDateLine` (`lib/features/move_list/widgets/library_date_line_format.dart`)
  turns that into a string via the ARB keys or `DateFormat.yMMMd`. The two are separate
  because `lib/core/` imports `AppLocalizations` in exactly zero places today, and 3.1 was
  not worth making it one — the classification is the part with rulings in it, and it
  tests without a `pumpWidget`.
  **Two rulings the executor of 3.2 should not re-derive.** First, the boundary is
  **calendar days, not elapsed hours**: something filmed at 11pm reads "Yesterday" at 1am,
  because that is the day the user remembers, and 24-hour arithmetic calls it "Today".
  Both instants normalize to local midnight and compare as *UTC* day ordinals, so a 23- or
  25-hour local day (DST) cannot round a 7-day gap down to 6 and leak into the relative
  arm. Second, a *future* date is absolute, never "Today" — the same ruling 2.4 made for
  month headers, for the same reason (a wrong device clock stamping a filmed date ahead
  must not borrow the relative arm through a negative delta). Horizon: 7 days, exclusive
  (`libraryRelativeDateHorizonDays`).
  **Prior art acknowledged rather than absorbed.** `relativeTime` in
  `lib/core/utils/time_format.dart` (compact, hardcoded English, non-injectable clock) and
  the private `_daysAgo` in `lab_detail_screen.dart:463` are unlocalized ancestors of this
  formatter. Converging them means ARB keys and context plumbing through lab cards,
  timelines, and quick-log feeds — surfaces this change does not touch — so they stay put;
  folding them in would be a drive-by refactor, not DRY.
  Binary truth: 18 tests (11 unit + 7 widget), **six** mutations each proven red —
  elapsed-hours instead of calendar days (−3), dropping the future guard (−3), widening the
  horizon to 30 (−3), deleting the yesterday arm (−3), pointing the `daysAgo` arm at the
  yesterday ARB key (−2), and dropping the year from the absolute format (−2).
  `flutter analyze` 0 errors (9 pre-existing infos), suite **1106 green / 9 pre-existing
  reds / 0 regressions**, `scripts/check_l10n.sh` green post-commit.
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
  default)? Record the ruling in design.md.
  **O2 is no longer part of this task — ruled 2026-07-18 (global, single key) to unblock
  2.2; see design.md.** Only O1 remains owner-gated here.
- [ ] 5.2 Implement the O1 ruling, if any. Visual encoding preferred over text where one
  exists (design D4).
- [ ] 5.3 Make the tile backup indicator honest. **Cross-change: blocked on
  `fix-video-backup-truth-and-unify-account` Phase 4** (4.2/4.3 land `copyCount` truth).
  Today the icon keys off `contentHash != null` — "tracked", not "backed up"
  (`move_grid_cell.dart:29-45`). Re-key it to real protection state once that count can
  be trusted; tick both ledgers per the cross-change rule. Verify: widget test for
  backed-up vs tracked-but-unprotected.

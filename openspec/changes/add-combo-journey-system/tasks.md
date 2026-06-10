# Tasks — Combo Journey System

## Phase 1 — Data model (schema v22, additive only)

- [x] 1.1 Add `status` (default `'idea'`) and `createdAt` columns to `combos` table definition
- [x] 1.2 Add `kind` (default `'jot'`), `videoPath`, `videoHash` columns to `combo_note_entries`
- [x] 1.3 Create `combo_plans` table (id, comboId FK cascade, planDate, position, createdAt, completedAt)
- [x] 1.4 Write v21→v22 migration: 4× addColumn, 1× createTable, `createdAt` backfill from `MIN(combo_note_entries.createdAt)` (PRAGMA-guarded for legacy `created_at` columns)
- [x] 1.5 `dart run build_runner build` — regenerate, compiles clean
- [x] 1.6 Migration test: seed v21 fixture → upgrade → assert row counts, byte-identical bodies, correct backfills
- [x] 1.7 DAO: `CombosDao.updateStatus()` appends `kind='status'` ledger row in same transaction; test proves atomicity
- [x] 1.8 DAO: `ComboPlansDao` CRUD + `watchPlansQueue()` + `watchPlansForDate()`; unit tests
- [x] 1.9 DAO: `watchCombosWithMeta()` (combo + last jot + counts, grouped by createdAt month); unit test
- [x] 1.10 Rollup: `watchActivityRollup()` (per-day jot/take counts for calendar heat) derived from ledger; unit test
- [x] 1.11 Evidence completion: query stamps `completedAt` when a jot exists for (comboId, planDate); unit test
- [x] 1.12 Export schema v9 (current was already v8, not v6; new fields) + import accepts v8 and older with defaults; round-trip test

## Phase 2 — Combo detail page (the working surface)

- [ ] 2.1 StatusTag widget: current word + ▾; tap → four-word picker (idea/attempting/landed/clean); writes via 1.7
- [ ] 2.2 Detail header: `‹ COMBOS` breadcrumb, `titleLarge` name, transition chain line (secondary, wraps)
- [ ] 2.3 Keep existing player + `ComboStepLine` directly under it (12px gap); verify 10-step scroll + per-step video swap with real moves
- [ ] 2.4 JournalList: 56/16/fluid grid, fluid type by length (14/16), `kind='status'` rows muted style, video refs render name+size with resolver-miss fallback
- [ ] 2.5 JotComposer pinned bottom: text field ("Jot it down…"), `+ video`, send (44dp circle, accent); writes immutable jot
- [ ] 2.6 LibraryVideoPickerSheet: sections "THIS COMBO'S MOVES" (with usage counts) and "RECENT TAKES"; instant link (no copy); "Import new from Photos…" last row
- [ ] 2.7 ⋯ action sheet: Plan for a day…, Duplicate, Edit, Share, Save to Album, Delete (destructive style)
- [ ] 2.8 Duplicate: clones combo+combo_moves as new `idea` combo, seeds journal with `kind='duplicate'` provenance row; test
- [ ] 2.9 Remove NOTES section from combo detail (jots supersede); migrate nothing — `combos.notes` stays readable via Edit screen
- [ ] 2.10 `flutter analyze` + widget tests for 2.1/2.4/2.5 green

## Phase 3 — Three tabs (Library · Planned · Calendar)

- [ ] 3.1 CombosScreen tab host with `AppSegmentedControl` (Library | Planned | Calendar); FAB "+" on Library only
- [ ] 3.2 LibraryView: month-grouped rows (name, 2-line transition chain, tag, mono stamp); stream-driven
- [ ] 3.3 PlannedView: progress strip (last session / this week / landed — all ledger-derived), numbered queue with ▲▼ reorder persisting `position`, one-line *why* from latest jot/status
- [ ] 3.4 "Plan a combo" primary button on PlannedView → picker: existing combo or "New combo…" (create-then-plan)
- [ ] 3.5 ComboCalendarView: reuse PracticeCalendarView pattern; past heat from rollup, future days show dashed ring + plan dots; legend
- [ ] 3.6 Day tap: past → that day's combos+facts; future → planned list + "+ Plan"
- [ ] 3.7 Create flow: new combo born `status='idea'`; success affordance offers "Plan it?"
- [ ] 3.8 Route swap: new CombosScreen replaces old combo list; old screen deleted (no zombie)
- [ ] 3.9 CTA/orientation audit against design.md rules (one primary per screen, ≥48dp, verbs on controls)

## Phase 4 — Storage hygiene

- [ ] 4.1 VideoPathHealer: stale-folder sweep (legacy `Documents/videos/` migrate-then-prune; temp export dirs >24h)
- [ ] 4.2 CanonicalFolderService: ledger-consistency pass; unreferenced masters → `Moves/Archive/` quarantine (never delete)
- [ ] 4.3 Diagnostics counters surfaced: staleFoldersRemoved / orphansQuarantined / pathsHealed
- [ ] 4.4 Idempotency tests: each sweep run twice → second run is a no-op
- [ ] 4.5 StageLogger coverage on all sweeps (begin/stage/complete/fail)

## Phase 5 — Files deep link

- [ ] 5.1 Info.plist (both debug + release plists — see iOS config gotcha): viewer role for `public.movie`, documents-in-place OFF
- [ ] 5.2 DeepLinkResolver: fast-hash match → `asset_manifest`/`moves.contentHash` → route `/moves/{id}` (combo-step aware); unmatched → import sheet pre-filled
- [ ] 5.3 Unit tests: hash match, filename fallback, no-match path
- [ ] 5.4 Physical-device verification via FlowDeck: open from Files → lands on move detail; full StageLogger trail

## Phase 6 — Real-time reactivity & zombie audit

- [ ] 6.1 Audit every combo-surface provider: anything `Future`-based for changeable data → converted to streams
- [ ] 6.2 Import/thumbnail progress: determinate byte/frame progress streams; stall detector logs after 2s without advance; no indeterminate spinners where size is knowable
- [ ] 6.3 `ast-grep` zombie sweep: unreferenced widget classes from replaced views deleted; report in PR description
- [ ] 6.4 Final gate: `dart run build_runner build` && `flutter analyze` && `flutter test` green; FlowDeck device smoke (create → jot → tag → plan → calendar → files-open)

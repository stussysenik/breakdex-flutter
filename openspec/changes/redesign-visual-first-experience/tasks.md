# Tasks — Redesign Visual-First Experience

Ledger rule: tick each box in the same commit that lands the work.

## Phase 1: Motion doctrine (foundation — other phases build on it)

- [x] 1.1 Add Fluid/Morph family aliases to `AppMotion` (`lib/core/design/spacing.dart`) and
  document both families in `docs/design/TOKENS.md` (single source rule).
- [x] 1.2 Sweep shared widgets with raw controllers (pressable, celebration_overlay,
  combo_step_line, notes_section, app_segmented_control, beat_grid, video_player_widget,
  metadata_video_picker_sheet, loading_state_widget) onto family tokens; fix any missing
  `dispose()` found during the sweep. (All targets already disposed correctly — no leaks
  found. Sweep extended to the only 3 other files with raw literals — flow_coach_marks,
  party_screen, robust_video_editor_view, flashcard breath — so the grep is zero app-wide.)
- [x] 1.3 Add "motion composes from AppMotion family tokens; controllers disposed" to the
  review checklist (`openspec/AGENTS.md` Non-negotiables); grep-verify zero raw motion literals
  on product surfaces (`rg 'Curves\.' lib/` → 0 outside the token definition; evidence in
  commit).
- [x] 1.4 Signature two-dot loader: build `AppLoader` (`lib/shared/widgets/app_loader.dart`) —
  two dots that slide in opposite phase and cross paths at center, composed from the Fluid
  family (`AppMotion.fluid` + new ambient `AppMotion.loaderLoop` token, documented in
  TOKENS.md). Wire it into the canonical loading surface (`loading_state_widget.dart`
  `_RetryingWidget`), replacing the stock `CircularProgressIndicator`. Widget test covers the
  two-dot invariant, semantics label, and clean dispose.
- [ ] 1.5 Rolling sweep: replace bare `CircularProgressIndicator` with `AppLoader` across the
  remaining product surfaces (`rg -l CircularProgressIndicator lib/`) so the loading motif is
  one connected system app-wide. Per-directory, additive, no behavior change — intentionally
  NOT done in the 1.4 commit to avoid a 50-file drive-by; each cluster ticks as it lands.
  Progress: `lib/shared/widgets/` cluster done (video_player_widget, quick_video_viewer,
  video_picker_sheet, move_photos_section) — 50→46 files. Remaining: features/* surfaces.

## Phase 2: Media grid membership + 4-slot tile

Decision (owner, 2026-07-08): **exact-identity membership only.** The spec's literal
"`contentHash` per visible tile" is infeasible for the photo-library tab — a PHAsset has no
file path, so hashing it means downloading the full video from iCloud per tile, and the source
PHAsset id is never persisted on the move. So membership resolves by exact identity: managed
tab by `managedAlbumAssetId`, app-storage tab by content hash of the local file, and
camera-roll is an honest miss (unmarked) — never a false mark, never a byte download to test
membership. Spec delta (`visual-first-surfaces`) reconciled to match.

- [x] 2.1 Membership index: `MoveMembershipIndex` built once per sheet-open from
  `MovesDao.getAll()` (keyed by `managedAlbumAssetId` + `contentHash`); local-file hashes
  memoized per sheet-open in `metadata_video_picker_sheet.dart`.
- [x] 2.2 Rebuilt `_VideoTile` as the 4-slot layout (thumbnail+duration badge, name, one
  secondary fact via `formatTileSecondaryFact`, `bookmark_added_rounded` membership mark);
  missing facts omitted, never padded with text.
- [x] 2.3 Importing an in-Breakdex tile opens a choice sheet — "Open existing move" (routes to
  `/breakdex/move/:id`) vs "Import again" — never a silent duplicate.
- [x] 2.4 Tests: membership match/miss (`MoveMembershipIndex`), tile slot cap (fact helpers),
  duplicate-selection affordance (managed asset → mark + choice sheet), honest photo-library
  miss. 13/13 green.

## Phase 3: Add flow de-text

Decision (owner, 2026-07-08): **task 3.2 is a widget test, not an image golden.** The repo
has no golden-file infrastructure, and a pixel golden freezes appearance without verifying the
actual requirement ("no paragraph-style helper text"). The widget test asserts the semantic
rule directly — every rendered `Text` node on the Add surface is a short label/anchor — which
is both the stronger check and net-cheaper than standing up golden tooling for one screen.

- [x] 3.1 De-texted `add_screen.dart`: dropped the two paragraph subtitles and the dead no-op
  help button; `_ChoiceCard` is now a full-height anchor tile (64px emoji + single label,
  "Move" / "Combo") laid out side-by-side. Metadata form keeps its input labels (text-for-input
  is exempt per the spec). Net −25 LOC.
- [x] 3.2 Widget test `test/features/add/add_screen_test.dart`: asserts both anchor labels
  render and no `Text` node exceeds the paragraph threshold. Green.

## Phase 4: Three view modes

Decisions (owner, 2026-07-08):
- **Toggle stays a direct-select 3-segment control**, not a literal cycle button. The existing
  `_PillToggleRow` renders `ViewMode.values` in order, so the enum declaration order
  (`glance, scan, study`) *is* the fixed cycle contract the spec names — same pattern the
  old list/grid toggle already used. Reconciles "3-segment control cycling in fixed order."
- **Unknown/absent stored value defaults to Glance** (was `list`→Scan). Glance is the
  design's lowest-cognitive-load mode and the visual-first landing; explicit legacy choices
  still migrate exactly (`grid`→Glance, `list`→Scan), so no prior *choice* is lost.
- **Task 4.4 "same result set under filter" is verified structurally, not by a DB pump.** The
  screen computes one `filtered` list and hands it to whichever sliver, so all three modes are
  fed the identical collection by construction; the unit tests cover order/migration/persistence.

- [x] 4.1 `ViewMode { glance, scan, study }`; `viewModeFromStored` + `isLegacyViewModeValue`
  pure helpers do the migration (`grid`→glance, `list`→scan) and `_ViewModeNotifier.build`
  re-persists migrated legacy values on first read of `arsenal_view_mode`.
- [x] 4.2 Study sliver family in `widgets/study_card.dart`: `_MoveStudyCard`/`_ComboStudyCard`
  over a shared `_StudyCardShell` (inline tap-to-play `RobustVideoPlayer`, beat/move counts,
  category/status, 2-line notes preview) reusing `_CategoryLabel`/`_MoveCountDots`/
  `_ComboPreviewFallback`. Glance reuses the grid sliver, Scan the list sliver; toggle icons +
  labels extended to three.
- [x] 4.3 Combos library gets all three modes via the same content switch
  (`_ComboGridSliver` / `_CombosContentSliver` / `_ComboStudySliver`).
- [x] 4.4 `test/features/move_list/view_mode_test.dart`: fixed cycle order, legacy migration
  (grid/list), new-name pass-through (no re-persist), unknown→Glance default, and per-mode
  name round-trip (persistence across restart). 6/6 green; preview-harness smoke test still
  renders the screen in the new default mode.

## Phase 5: Review WYSIWYG

- [ ] 5.1 Re-layout the review card as a fixed viewport budget (media, prompt, rating row);
  long notes collapse behind an expand affordance; no default scroll view.
- [ ] 5.2 Move review surfaces to `AppRadius.xxs`; raw radii remain only on thin bars.
- [ ] 5.3 Wire card fill to the arbitrary-color mechanism from
  `clarify-review-loop-and-media-cleanup` (do not duplicate the color editor).
- [ ] 5.4 Tests: no-scroll on reference viewports (small phone + tablet), overflow affordance,
  live fill application.

## Verification

- [ ] V.1 `dart analyze` + `flutter test` green; goldens updated deliberately.
- [ ] V.2 Patrol journey: open library → cycle 3 modes → pick device video already in
  Breakdex → land on existing move → run one review card without scrolling (iOS + Android).
- [ ] V.3 Token conformance: grep evidence that review radii and motion literals resolve from
  tokens; TOKENS.md updated in the same commit as 1.1.

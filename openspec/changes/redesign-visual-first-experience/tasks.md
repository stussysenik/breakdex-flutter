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

- [ ] 3.1 Replace helper copy on `add_screen.dart` with visual anchors (Move / Combo) —
  iconography + single labels; net-negative LOC expected.
- [ ] 3.2 Golden test: Add tab renders with no paragraph-style text nodes.

## Phase 4: Three view modes

- [ ] 4.1 Extend `ViewMode` to `{ glance, scan, study }` with legacy migration
  (`grid`→glance, `list`→scan) on first read of `arsenal_view_mode`.
- [ ] 4.2 Build the Study sliver family (rich card: inline playback, counts, category, notes
  preview) reusing existing card/video widgets; 3-segment `_ViewModeToggle` in fixed order.
- [ ] 4.3 Apply the same three modes to the combos library surfaces
  (`_ComboGridSliver`/`_CombosContentSliver`).
- [ ] 4.4 Tests: cycling order, persistence across restart, legacy migration, same result set
  across modes under an active filter.

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

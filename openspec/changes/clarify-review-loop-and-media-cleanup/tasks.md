# Tasks — Clarify Review Loop, Media Cleanup & Color Customization

> **Ledger reconciliation (2026-07-09).** This change was 0/21 while its behavior had
> almost entirely shipped under adjacent changes — the drift the repo's same-commit ledger
> rule exists to prevent. Each box below was verified against shipped code (file:line evidence
> inline); 17 were already SHIPPED, and the one real gap (2.6, album filename on move detail)
> was built in this commit. Ticks now reflect ground truth.

## Phase 1: Review Loop
- [x] 1.1 State-based review launcher counts due-only, not total-by-state
  (`review_providers.dart:180,209` — `reviewStateMatrixProvider` skips `!_isDue`)
- [x] 1.2 Brand-new entities without an FSRS row stay launchable as `New`
  (`review_providers.dart:174` — `_isDue` returns true when `card == null`)
- [x] 1.3 Swipe-preview nav replaced with a single centered reveal-first card
  (`flashcard_review_screen.dart:400-461` — one `ReviewCard`, "Assess" reveals ratings)
- [x] 1.4 Move review writes so visible state follows the FSRS result
  (`flashcard_review_screen.dart:918-928` — `learningStateFromFsrs(postState)`)
- [x] 1.5 Reduced learning-step aggressiveness; interval previews still match
  (`fsrs_settings.dart:31` — single gentle `[10m]` step; previews via `RatingButtonRow`)
- [x] 1.6 Provider tests for due-only and missing-card behavior
  (`card_count_sync_test.dart` — added; new-move inclusion, delete exclusion, manual-reset,
  combo parity all green). **2 assertions RED, pre-existing & unrelated to this reconciliation**
  (`:222`, `:314`): they seed a *desynced* move (FSRS card = learning, `move.learningState` =
  NEW) and expect FSRS-derived move bucketing, but `reviewStateMatrixProvider` buckets moves by
  the `learningState` column (`review_providers.dart:212`; combos derive from FSRS at `:227`).
  The **due-only filter itself works** (`:209` `!_isDue` → skip). Verified red at `b67777a`
  (pre-change) — this is the "FSRS due-counts" pre-existing failure the redesign V.1 ledger
  already flagged and deferred. Reconciling move-vs-FSRS bucketing is an owner behavior call
  (changes real launcher counts), not part of this drift-correction. See V.1 below.
- [x] 1.7 Pause playback when media is covered/backgrounded/non-primary
  (`video_player_widget.dart:108,160,309` — `WidgetsBindingObserver` + `RouteAware` + `TickerMode`)
- [x] 1.8 Preserve the active card when live review data refreshes mid-session
  (`flashcard_review_screen.dart:752-761` — `reconcileReviewSession` keeps current item)

## Phase 2: Sync & Media Cleanup
- [x] 2.1 Reconcile `moves.learningState` from synced `fsrs_cards` after pull
  (`sync_bloc.dart:70,77` → `sync_service.dart:209-226` `reconcileLegacy`)
- [x] 2.2 Preserve pending `videoSynced=false` across later metadata writes
  (`sync_dao.dart:49` — metadata write uses `videoSynced: Value.absent()`)
- [x] 2.3 Remove remote uploaded video objects during delete sync
  (`sync_service.dart:84-91` — `FirebaseStorage.ref('videos/$path').delete()` before doc delete)
- [x] 2.4 Move/combo delete flows clean local video files and thumbnails
  (`move_detail/provider.dart:290` + `combo_detail/provider.dart:126` → `video_service.deleteVideo`)
- [x] 2.5 Tests for sync reconciliation and relative-path cleanup
  (`sync_service_test.dart:181` + `video_service_test.dart:59`)
- [x] 2.6 Surface source **and** app-managed album filenames on move detail
  (source `originalVideoName` shipped; **built here** — `move_detail_screen.dart` now also
  renders `move.managedAlbumFilename` as an `Album · …` caption when present)

## Phase 3: Settings Colors
- [x] 3.1 Reusable arbitrary color editor control
  (`color_setting_tile.dart:23` — `showColorEditorDialog`: hex + HSV + RGB + opacity + presets)
- [x] 3.2 Preset-only accent and rating pickers replaced with the reusable editor
  (`accent_color_section.dart:35` + `rating_colors_section.dart:76`)
- [x] 3.3 Same editor used for category color create/rename flows
  (`settings_screen.dart:780` rename, `:941` create)
- [x] 3.4 Persistence tests for arbitrary ARGB values
  (`theme_providers_test.dart:27,36,52` + `review_fill_color_test.dart:27`)

## Phase 4: Validation
- [x] 4.1 Focused Flutter tests green for each slice (evidence cited per task; the 2.6 display
  slice is a pure additive conditional `Text` — no logic to unit-test, field population already
  covered by `managed_album_reconciliation_service_test`). **Known exception:** the 2 pre-existing
  reds in `card_count_sync_test` (`:222`, `:314`) — see 1.6; confirmed red at `b67777a`, so this
  reconciliation introduced no regression.
- [x] 4.2 Analyzer clean on touched files (`move_detail_screen.dart` — no errors)
- [x] 4.3 OpenSpec scope confirmed to match the integrated change set (this reconciliation)

> **V.1 — deferred owner decision (move-vs-FSRS bucketing).** `reviewStateMatrixProvider`
> buckets moves by the `move.learningState` column while combos derive from FSRS state. In
> production the column is kept consistent with FSRS by 1.4 (review writes) + 2.1 (pull
> reconcile), so counts are correct; the 2 red tests seed an unreconciled state that only exists
> in the fixture. Whether to make the matrix derive move state from FSRS (robust to any desync)
> or keep the column as the display source of truth is a behavior call for the owner — it moves
> real launcher counts and is out of scope for this ledger reconciliation. Tracked here so it is
> not lost.

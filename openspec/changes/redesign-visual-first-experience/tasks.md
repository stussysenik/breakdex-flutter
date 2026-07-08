# Tasks — Redesign Visual-First Experience

Ledger rule: tick each box in the same commit that lands the work.

## Phase 1: Motion doctrine (foundation — other phases build on it)

- [ ] 1.1 Add Fluid/Morph family aliases to `AppMotion` (`lib/core/design/spacing.dart`) and
  document both families in `docs/design/TOKENS.md` (single source rule).
- [ ] 1.2 Sweep shared widgets with raw controllers (pressable, celebration_overlay,
  combo_step_line, notes_section, app_segmented_control, beat_grid, video_player_widget,
  metadata_video_picker_sheet, loading_state_widget) onto family tokens; fix any missing
  `dispose()` found during the sweep.
- [ ] 1.3 Add "motion composes from AppMotion family tokens; controllers disposed" to the
  review checklist; grep-verify zero raw motion literals on product surfaces
  (`ast-grep`/`rg` evidence in the commit message).

## Phase 2: Media grid membership + 4-slot tile

- [ ] 2.1 Membership lookup: index device-asset `contentHash` against moves (lazy per visible
  tile, cached per sheet-open) in `metadata_video_picker_sheet.dart`.
- [ ] 2.2 Rebuild `_VideoTile` as the 4-slot layout (thumbnail+duration, name, one secondary
  fact, membership mark); missing facts omitted, never padded with text.
- [ ] 2.3 Selecting an in-Breakdex tile offers "Open existing move" (route to move detail)
  vs "Import again" — never a silent duplicate.
- [ ] 2.4 Tests: membership match/miss, tile slot cap, duplicate-selection affordance.

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

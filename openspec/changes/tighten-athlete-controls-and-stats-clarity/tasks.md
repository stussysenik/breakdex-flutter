# Tasks - Tighten Athlete Controls & Stats Clarity

> Ledger reconciled 2026-07-27 (CLAUDE.md ledger rule): this change shipped zero-ticked,
> mostly inside mega-commit `46c604c` ("land athlete ux, sync tooling, and research
> workbench"). Ticks below carry file + commit evidence; unticked tasks are verified
> NOT shipped, not merely unaudited.

## Phase 1: Quick Corrections
- [x] 1.1 Make move-detail state/category chips direct edit controls — `lib/features/move_detail/move_detail_screen.dart:230-249` (`StatePill`/`_CategoryBadge`/`_CountBadge` with `onTap` → `TapChangeState`/`TapChangeCategory`/`TapChangeCount` machine events; events landed `4230c1f`, wiring hardened `46c604c`)
- [x] 1.2 Add inline category creation to the move-detail category sheet — `lib/features/move_detail/widgets/move_detail_overlays.dart:142-146,171-175` (`_showAddCategoryDialog` + "Add new" affordance in `CategoryPickerOverlay`; landed `46c604c`)
- [x] 1.3 Apply newly created categories immediately with minimal taps — `move_detail_overlays.dart:143` (`if (created != null) onSave(created)` — created category is applied in the same flow; landed `46c604c`)

## Phase 2: Overlap Hardening
- [x] 2.1 Harden `ActionTile` against long labels — `lib/shared/widgets/action_tile.dart` (label in `Expanded`, `maxLines: 2`, ellipsis; landed `46c604c`, test `test/shared/widgets/action_tile_test.dart`)
- [x] 2.2 Harden `StatePill` against long/custom labels — `lib/shared/widgets/state_pill.dart` (label in `Flexible`, `maxLines: 1`, ellipsis; landed `46c604c`, test `test/shared/widgets/state_pill_test.dart`)
- [x] 2.3 Rework move-row and stats-row metadata to wrap instead of collide — `lib/features/move_list/widgets/move_row.dart:111` + `lib/features/stats/widgets/top_moves_list.dart:132` (metadata in `Wrap`; landed `46c604c`, overflow test in `top_moves_list_test.dart`)

## Phase 3: Subject-First Stats
- [ ] 3.1 Surface top reviewed subjects earlier on the stats screen — NOT shipped: `TopMovesList` exists but has zero call sites in `lib/`; the live brutalist `StatsScreen` (`lib/features/stats/stats_screen.dart:55-88`) leads with number rows and has no top-subjects section
- [x] 3.2 Flip summary cards to label-first/value-second hierarchy — `lib/features/stats/widgets/stat_card.dart` (column flipped label-above-value in `46c604c`; live screen's `_StatRow` is also label-first; asserted by `stat_card_test.dart` "presents the subject label above the value")
- [ ] 3.3 Tighten summary copy around review subjects — NOT proven: `46c604c` swapped hardcoded NEW/LEARN/MASTERY for user-configured state labels in `due_cards_summary.dart`, but no identifiable subject-copy tightening on the live stats screen; leave open

## Phase 4: Graph Label Reliability
- [x] 4.1 Replace fixed graph-label boxes with measured bounds — `lib/features/flow/widgets/flow_graph_canvas.dart:586-625` (`ui.Paragraph.layout` → `longestLine`/`height` measured rects; landed `46c604c`)
- [x] 4.2 Clamp labels to canvas bounds and skip only true collisions — `flow_graph_canvas.dart:609-613` (clamp to canvas) + "Greedy collision-aware placement" pass (landed `99271e2`)

## Phase 5: Validation
- [x] 5.1 Add focused widget tests for touched shared widgets and stats hierarchy — `test/shared/widgets/state_pill_test.dart`, `test/shared/widgets/action_tile_test.dart`, `test/features/stats/widgets/stat_card_test.dart`, `test/features/stats/widgets/top_moves_list_test.dart` (all added `46c604c`)
- [x] 5.2 Run targeted Flutter tests — re-run 2026-07-27: `flutter test` on the four files above, **5 tests, all passed**
- [x] 5.3 Run analyzer on touched files — re-run 2026-07-27: `dart analyze` on the 8 touched files → 0 errors (1 pre-existing info in `move_detail_screen.dart:156`)

# Archive note — 2026-08-10 — tighten-athlete-controls-and-stats-clarity

**Verdict: IMPLEMENTATION-COMPLETE (12/14 shipped).** Not a repair candidate — most of
the work shipped in mega-commit `46c604c`; the proposal's old template is moot because
the code it described is live. The two unticked tasks are owner-verification, not
unstarted implementation.

## Shipped (12 tasks, `46c604c` unless noted)

- Phase 1 (quick corrections): move-detail state/category chips as direct-edit controls,
  inline category creation in the category sheet, apply-created-category-immediately.
- Phase 2 (overlap hardening): `ActionTile`/`StatePill` long-label ellipsis, move-row and
  stats-row metadata `Wrap` instead of collide.
- Phase 3 partial: summary cards flipped label-above-value.
- Phase 4 (graph labels): fixed boxes → measured `ui.Paragraph.layout` bounds,
  canvas-clamped + greedy collision-aware placement (`99271e2`).
- Phase 5 (validation): 4 focused widget tests (5 tests, all passed), analyzer 0 errors.

## NOT shipped (2 tasks — owner-verification)

| Task | Status | Why |
| --- | --- | --- |
| 3.1 Surface top reviewed subjects earlier on stats | `TopMovesList` exists but has **zero call sites** in `lib/`; the live `StatsScreen` leads with number rows, no top-subjects section | Needs owner decision on where it goes on the live screen |
| 3.3 Tighten summary copy around review subjects | `due_cards_summary.dart` does not exist; no subject-copy tightening on the live stats screen | Needs owner's eyes on real stats UI |

## Where the remaining work goes

Per the queue doctrine ("agent-unclosable tasks never sit in a parent change"), the two
unticked tasks need the owner's eyes on the live stats screen — they are moved to
`owner-verification-passes` as a dated entry, not left to rot in this change. The owner
reviews the live `StatsScreen` and either accepts the current number-first layout or
specifies where top-subjects + tightened copy go.

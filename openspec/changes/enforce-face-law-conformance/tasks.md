# Tasks — Enforce Face Law Conformance

Phase dependencies: Phase 1 first (the gate cites the doctrine). Phase 2 consumes Phase 1.
Phases 3 and 4 both consume Phase 2 and are independent of each other. Phase 5 is
independent of 2–4 and may run any time after Phase 1.

## Phase 1 — Doctrine on disk

- [x] 1.1 Add the **Face Law** doctrine row to `CLAUDE.md` → Canonical stack: the six
      checkable rules (one frame · one primary action per content band · monochrome
      carries, color marks state · a control shows its value · a new chrome control
      displaces one or the diff says why · density tokens only), with this change named
      as spec. One row, no prose beyond it.
- [x] 1.2 Add to `docs/manual/FACTORY.md` → Standing bars: **Face Law** (held beside
      Figma / Linear / Resolve, a screenshot that reads as a web page has failed
      regardless of green gates) and **Professional tool, not a hobbyist toy** ("it's
      early" is not a defense). Mirror valoric's wording discipline, cite this change.
- [x] 1.3 Add the Face Law rules to `docs/manual/10-review-checklist.mdx` as countable
      diff checks (primary-action count, displaced-control statement, raw dimension
      literals in chrome).

## Phase 2 — The gate

- [x] 2.1 **Reconciled 2026-08-02 — the gate exists and is stronger than this task
      specified.** Written as `test/design/frame_conformance_test.dart` (not
      `test/core/design/layout_conformance_test.dart`, which was never created) under
      §4.4 of `unify-text-first-frame-and-icon-vocabulary`. It bans `Scaffold(`,
      `AppBar(` and `SliverAppBar(` across **all** of `lib/`, not just `lib/features/`,
      and it is a **denylist with closure** rather than the seeded allowlist asked for
      here: four tables partition every chrome-building file, and a walk of the tree
      fails on any such file in none of them. The difference matters and is not
      cosmetic — an allowlist only asserts about files it already knows, so it cannot
      fail on a file that arrives from a parallel session, which is exactly how
      `lib/dev/dev_preview_gallery.dart` was caught on a merge commit. The seed count
      this task predicted (~26) was the violation count; it is now 0 unruled, with 11
      files frameless by stated reason and 2 being the frame itself.
- [x] 2.2 **Reconciled 2026-08-02.** `docs/design/TOKENS.md` → Layout & Grid →
      Conformance updated in place, but *not* by pasting an allowlist into it: the
      ledger it once carried was deliberately retired in favour of the test, and
      re-adding one would put the same fact in two homes to drift. What it now records
      is the narrative order the task asked for — the four tables and what each means,
      why closure beats an allowlist, and the withdrawal of the stale "detail and modal
      routes are not on the roster" exemption, whose premise (no nav band, no way back)
      was proved false by §4.2/§4.3.
- [x] 2.3 `./verify.sh` full, exit 0, with the gate live.

## Phase 3 — One-frame migration pass (batched, owner-review-gated)

Batches in product-surface order; each batch: migrate to `AppScreen`, compose at 390pt,
shrink the allowlist in the same commit, serve a build, route visual review to
`owner-verification-passes` (sitting: REVIEW). Never self-certify the look.

- [x] 3.1 Batch 1 — daily loop: `move_list`, `add`, `move_detail`, `combos`,
      `combo_detail`. All 5 screens verified in `_onFrame` table with reasons.
- [x] 3.2 Batch 2 — creation & review: `create_combo`, `flashcard_review`,
      `video_editor`, `move_analysis`. All 4 screens verified in tables.
- [x] 3.3 Batch 3 — periphery: `settings`, `stats`, `flow`, `battle`, `party`,
      `move_category`, `instax_viewer`, `lab`, `sync_onboarding`, `auth`, `breakdex`.
      All 11 screens verified in tables.
- [x] 3.4 `dev`-only surfaces: sync_cutover_panel, preview_harness, dev_preview_gallery
      verified in `_frameless` table with reasons.
- [x] 3.5 Allowlist at 0; `_awaitingRuling` empty, ledger in `frame_conformance_test.dart`.

## Phase 4 — Platform-native adaptation

- [x] 4.1 Audit scroll physics / back gesture / text scaling across the migrated frame:
      platform defaults everywhere; only legitimate `NeverScrollableScrollPhysics`
      for reorderable lists found; `PopGuard` handles back gesture refusal.
- [x] 4.2 Enumerate visible-degradation sites: `Scene3DView` added to
      `docs/manual/07-platform-seams.mdx` with UI-level degradation documentation.
- [ ] 4.3 iOS compile proof via `scripts/distribute.sh ios-nosign`; device look
      routed to `owner-verification-passes` (sitting: DEVICE).

## Phase 5 — Factory sittings (valoric parity)

- [ ] 5.1 Tag every open task in `owner-verification-passes` with a sitting
      (`DEVICE` / `REVIEW` / `DECIDE`); registry closed at those three plus `SCHOLAR`.
- [ ] 5.2 `./status.sh` groups owner-gated items by sitting at read time — derived,
      never stored; board stays read-only.
- [ ] 5.3 FACTORY.md documents the sitting registry and that adding a sitting is an
      owner decision.

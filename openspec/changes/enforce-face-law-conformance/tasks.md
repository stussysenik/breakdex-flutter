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

- [ ] 2.1 Write `test/core/design/layout_conformance_test.dart`: any `Scaffold`,
      `AppBar`, or `SliverAppBar` construction under `lib/features/` outside the
      allowlist fails. Seed the allowlist with the current raw-Scaffold files
      (enumerated at write time, expected ~26). Same two-assertion shape as the color
      gate: a listed file that no longer violates must be removed from the list.
- [ ] 2.2 Record the seeded allowlist as the migration ledger in
      `docs/design/TOKENS.md` → Layout & Grid (update in place — one home for the list;
      the test reads as the enforcement, TOKENS.md as the narrative order).
- [ ] 2.3 `./verify.sh` green with the gate live and the allowlist at its seed size.

## Phase 3 — One-frame migration pass (batched, owner-review-gated)

Batches in product-surface order; each batch: migrate to `AppScreen`, compose at 390pt,
shrink the allowlist in the same commit, serve a build, route visual review to
`owner-verification-passes` (sitting: REVIEW). Never self-certify the look.

- [ ] 3.1 Batch 1 — daily loop: `move_list`, `add`, `move_detail`, `combos`,
      `combo_detail`.
- [ ] 3.2 Batch 2 — creation & review: `create_combo`, `flashcard_review`,
      `video_editor`, `move_analysis`.
- [ ] 3.3 Batch 3 — periphery: `settings`, `stats`, `flow`, `battle`, `party`,
      `move_category`, `instax_viewer`, `lab`, `sync_onboarding`, `auth`, `breakdex`.
- [ ] 3.4 `dev`-only surfaces: migrate or mark as permanent allowlist entries with a
      one-line reason each (a dev screen is a tool surface too; default is migrate).
- [ ] 3.5 Allowlist at 0 (or dev-only residue, each line justified); ledger in
      TOKENS.md closed out.

## Phase 4 — Platform-native adaptation

- [ ] 4.1 Audit scroll physics / back gesture / text scaling across the migrated frame:
      platform defaults everywhere, zero custom re-implementations; delete any found.
- [ ] 4.2 Enumerate visible-degradation sites (the `Scene3DView` shape) in
      `docs/manual/07-platform-seams.mdx` — update in place; every platform gap names
      itself on the surface.
- [ ] 4.3 iOS compile proof via `scripts/distribute.sh ios-nosign`; device look
      routed to `owner-verification-passes` (sitting: DEVICE).

## Phase 5 — Factory sittings (valoric parity)

- [ ] 5.1 Tag every open task in `owner-verification-passes` with a sitting
      (`DEVICE` / `REVIEW` / `DECIDE`); registry closed at those three plus `SCHOLAR`.
- [ ] 5.2 `./status.sh` groups owner-gated items by sitting at read time — derived,
      never stored; board stays read-only.
- [ ] 5.3 FACTORY.md documents the sitting registry and that adding a sitting is an
      owner decision.

# OpenSpec Conventions — Breakdex

This folder IS the task queue (owner ruling). Repo contract: `/CLAUDE.md` (root). This file
governs how changes are written and executed here. Planner (teacher) devises changes;
executor (student, e.g. Opus 4.8) attacks tasks — the split only works if every change is
executable without re-deriving intent.

## Product doctrine (the moat — encode it, never dilute it)

- **Atomic architecture**: a *move* is the atom; a *combo* is move-after-move; a *set/deck*
  composes combos. Beats/counts are pre-planned musicality metadata on the atoms
  (`count` column, beat grid). Every feature composes from these atoms — the product is a
  portable gym / infinite idea-generation machine, and that power comes from the
  opinionated atom model, not from feature count.
- **Visual-first**: interface chrome communicates through visual anchors; text is for input
  and settings (`redesign-visual-first-experience`).
- **UI = f(state)**: `Machine<S,E>` on Flutter, XState v5 on web. State transitions are
  explicit; impossible states are unrepresentable. Patterns (GoF/FP) only when the problem
  has that shape — essentialism rules (`/CLAUDE.md` §1–§3).

## Change anatomy

```
openspec/changes/<verb-led-id>/
  proposal.md   # Why / What Changes / Capabilities / Footprint estimate / Non-goals
  design.md     # only when architecture needs trade-off discussion
  tasks.md      # phased checkboxes; the executor's contract
  specs/<capability>/spec.md  # ## ADDED|MODIFIED|REMOVED Requirements, ≥1 #### Scenario: each
```

- **Footprint estimate** is required in proposals: quantize the expected file/LOC state
  (current → target per surface). Grounded numbers beat adjectives.
- Validate before sharing: `openspec validate <id> --strict --no-interactive`.

## Execution discipline (sequential-or-parallel, stated explicitly)

- Every `tasks.md` declares phase dependencies at the top (e.g. "Phases 1–3 independent;
  Phase 4 consumes all three"). An executor may fan out independent phases across sessions;
  dependent phases run in order. If it isn't stated, assume sequential.
- **Ledger rule (same-commit ticking)**: checkboxes tick in the same commit that lands the
  work. Cross-change overlaps name the other change and tick both ledgers in whichever
  commit lands first.
- **Binary truth**: no box ticks without terminal-verified evidence (build/test/analyze
  output, or a named device/simulator run). "Compiles" is not "works".
- Extend existing changes over new umbrellas; supersession is explicit (archive with a
  dated header, move keepers, name the ruling) — see
  `archive/2026-07-08-evolve-web-mirror-to-crud-platform` for the precedent.
- Sequencing authority: root `ROADMAP.md` → "Backlog — OpenSpec change order (D8)".

## Non-negotiables (inherited, restated for executors)

- Brownfield production: additive over invasive; never delete/orphan user state; migrations
  one-way and tested; verify on a real build before claiming done.
- Data safety: original video bytes are truth (never transcode); tombstones over hard
  deletes; a stored user preference is never overridden by a new default.
- Tokens: `docs/design/TOKENS.md` is the single design source. **Review checklist:**
  motion composes from `AppMotion` family tokens (Fluid/Morph doctrine) — raw
  `Curve`/`Duration` literals driving visible motion on a product surface are
  violations; every `AnimationController` is disposed with its owning widget.
- Every deployment (web/iOS/Android) is the same standardized brick: one codebase, one
  config surface (remote config + cohorts), platform gaps degrade visibly.

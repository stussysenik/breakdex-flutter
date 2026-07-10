# Tasks — add-engineering-manual-and-docs-ledger

> **Phase dependencies:** Phase 1 first. Phases 2–4 independent after 1 (fan-out
> allowed). Phase 5 consumes 2–4. Phase 6 last.
> Binary truth: a chapter task ticks only when its `status: verified` claim is checked
> against code at the `verified` commit; script tasks tick on terminal-verified runs.

## 1. Skeleton & ledger format

- [x] 1.1 Create `docs/manual/` with `index.mdx` (TOC, reading order, "how to use this as
      an agent" preface) + chapter stubs carrying the frontmatter schema
      (`watches`/`verified`/`status`) from design D3. Validate: stubs parse as YAML
      frontmatter + CommonMark (`node -e` or dart snippet run in terminal).
- [x] 1.2 Absorb-or-index audit: table in `index.mdx` mapping every existing doc
      (`architecture.md`, `TECHSTACK.MD`, `VISION.MD`, `PRD.md`, `hyperdata-ledger.md`,
      `docs/design/TOKENS.md`, root `CLAUDE.md`, `openspec/AGENTS.md`) → absorbed /
      indexed / out-of-scope, and add pointer headers to indexed docs (additive only).

## 2. Core reference chapters (each: write → set `watches` → verify → `status: verified`)

- [x] 2.1 Product doctrine: atom model (move → combo → set, beats/counts), visual-first
      interface language, non-goals (no E2EE/CRDTs/Temporal).
- [x] 2.2 State architecture: `Machine<S,E>` (sealed states/events, transition table,
      production wiring), web mirror rule (XState v5 1:1).
- [x] 2.3 Data layer: Drift schema v8 (tables, polymorphic fsrs_cards), DAOs +
      build_runner, three-layer repositories (abstract → Drift → SyncAware), FSRS
      integration gotchas.
- [x] 2.4 Sync: SyncBackend contract, record-level LWW + tombstones, dirty-guard, upload
      spool, Drive pointer model, Appwrite topology + env conventions.
- [x] 2.5 Design system: tokens index (→ `TOKENS.md`), 8pt/4pt grid, Fluid/Morph motion
      doctrine, `AppMotion` composition rules.
- [x] 2.6 Localization: ARB → `lib/l10n/gen/`, `scripts/check_l10n.sh` gate, parametric
      noun composition rules.
- [x] 2.7 Platform seams & web: `lib/core/platform/io.dart` seam, Drift WASM/OPFS, plugin
      degradation policy (gaps degrade visibly).
- [x] 2.8 Testing & verification: binary-truth standard, runtime verification targets
      (iOS sim path; macOS/Chrome dead ends), red/green discipline, known pre-existing
      failures policy.

## 3. Standards chapters

- [x] 3.1 Staff-level mobile standards: numbered, citable rules for state, rebuilds,
      async, disposal, diff discipline (essentialist axiom applied to Flutter).
- [x] 3.2 Consolidated review checklist page (motion tokens, l10n grep gate, data safety,
      brownfield) with stable anchors reviews can cite.
- [x] 3.3 Executor onboarding chapter: session-start protocol (NOW block → tasks.md →
      same-commit ledger), what a student may/may-not touch without teacher escalation.

## 4. Docs ledger tooling

- [x] 4.1 Drift-check script (git-plumbing diff of `verified..HEAD` per chapter's
      `watches`; exit 0/non-zero per spec). Validate red/green: stale stub → non-zero;
      after `verified` bump → zero.
- [x] 4.2 `--json` work-order output (`chapter, watches, verified, changed_files,
      diff_stat`). Validate against a synthetic stale chapter.
- [x] 4.3 Wire drift check into CI alongside existing gates.

## 5. Student priming bundle

- [ ] 5.1 Bundle script (`--all` / `--chapters`, TOC + token estimates, deterministic
      output, standards preamble always included). Validate: two runs byte-identical;
      subset bundle reports totals.
- [ ] 5.2 Priming dry-run: fresh session + bundle only + one small real seam task; record
      task, model, subset, token weight, outcome in the manual meta chapter.

## 6. Close-out

- [ ] 6.1 All chapters `status: verified`, drift check green in CI, cross-reference note
      added to `add-web-authoring-and-lifecycle-studio` proposal (hosting ↔ content
      split), `openspec validate` strict pass, archive-readiness review.

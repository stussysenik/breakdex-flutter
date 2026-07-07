# spec-ledger-hygiene

## ADDED Requirements

### Requirement: Repo-root agent contract
The repository SHALL contain a root `CLAUDE.md` stating the canonical stack rulings
(Appwrite backend; Next.js 15 + XState v5 web; Flutter `Machine<S,E>`; TOKENS.md; LWW +
dirty-guard sync model; non-goals E2EE/Temporal/CRDTs) and pointing to the single canonical
roadmap. Root `ROADMAP.md` SHALL be the only roadmap; duplicated planning docs
(`docs/ROADMAP.MD`, `docs/PROGRESS.MD`) SHALL be folded in and removed.

#### Scenario: One source of planning truth
- **WHEN** an agent session starts and reads root CLAUDE.md
- **THEN** it can name the canonical backend, web stack, state architecture, token source,
  and top-of-backlog change without exploring, and finds exactly one roadmap file

### Requirement: Tasks tick in the same commit as the work
A change's `tasks.md` checkboxes SHALL be updated in the same commit that lands the
corresponding work. A pending change whose tasks materially contradict shipped code is a
review violation to be reconciled before new work builds on it.

#### Scenario: Ledger cannot drift silently
- **WHEN** a commit implements a task from a pending OpenSpec change
- **THEN** that commit also ticks the task, and review rejects implementation commits that
  leave the ledger stale

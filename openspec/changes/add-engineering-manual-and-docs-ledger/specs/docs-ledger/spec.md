# Docs Ledger — docs↔code freshness

## ADDED Requirements

### Requirement: Every chapter declares a machine-readable watch ledger

Each manual chapter SHALL carry YAML frontmatter with `watches:` (path globs naming the
code the chapter is truth about), `verified:` (the commit the chapter was last checked
against), and `status:` (`stub` | `draft` | `verified`). A chapter reaches `verified`
only after its claims are checked against the code at that commit (binary truth).

#### Scenario: Chapter is self-describing after a rename

- **WHEN** a chapter file is moved or renamed
- **THEN** its ledger travels with it (frontmatter, not a central registry) and the drift
  check keeps working unchanged

### Requirement: A deterministic drift check flags stale chapters

A repo script SHALL, for each chapter, diff `verified..HEAD` restricted to its `watches`
globs using git plumbing only (no network, no model). It SHALL exit non-zero listing
stale chapters when any watched path changed, and exit zero on a clean tree. The check
SHALL run in CI.

#### Scenario: Drift detected

- **GIVEN** the state-machine chapter verified at commit `X`
- **WHEN** a later commit touches `lib/core/state_machines/` and the check runs
- **THEN** it exits non-zero naming the chapter and the changed files

#### Scenario: Clean pass

- **WHEN** no watched path changed since any chapter's `verified` commit
- **THEN** the check exits zero

### Requirement: Drift emits model-agnostic work orders

With `--json`, the drift check SHALL emit one work order per stale chapter:
`{chapter, watches, verified, changed_files, diff_stat}` — sufficient for any executor
(teacher session, student model, or cheap hosted inference) to update the chapter and
bump `verified` without further discovery.

#### Scenario: Work order handed to a student session

- **GIVEN** a stale sync chapter work order and the priming bundle
- **WHEN** a student session receives both
- **THEN** it can produce the chapter update + `verified` bump without repo-wide search

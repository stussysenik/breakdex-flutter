# docs-ledger Specification

## MODIFIED Requirements

### Requirement: Every chapter declares a machine-readable watch ledger

Each manual chapter — **engineering half and business half alike** — SHALL carry YAML
frontmatter with `watches:` (path globs naming the code the chapter is truth about),
`verified:` (the commit the chapter was last checked against), and `status:`
(`stub` | `draft` | `verified`). A chapter reaches `verified` only after its claims are
checked against the code at that commit (binary truth).

Business-half chapters SHALL additionally carry `domain:` (one of
`product | design | gtm | ops`), so intent resolution can distinguish a business ruling from
an engineering one without inferring it from the filename.

#### Scenario: Chapter is self-describing after a rename

- **WHEN** a chapter file is moved or renamed
- **THEN** its ledger travels with it (frontmatter, not a central registry) and the drift
  check keeps working unchanged

#### Scenario: A business chapter is ledgered identically to an engineering one

- **GIVEN** the GTM chapter watches the offering-config source
- **WHEN** that config changes without the chapter changing
- **THEN** the drift check flags the GTM chapter exactly as it would flag the sync chapter

### Requirement: A deterministic drift check flags stale chapters

A repo script SHALL, for each chapter in **both halves**, diff `verified..HEAD` restricted to
its `watches` globs using git plumbing only (no network, no model). It SHALL exit non-zero
listing stale chapters when any watched path changed, and exit zero on a clean tree. It SHALL
additionally exit non-zero when a `watches:` glob matches no file on disk, or when a
business-half chapter declares an empty `watches:` list. The check SHALL run in CI.

#### Scenario: A dead glob fails the check

- **GIVEN** a chapter watching a path that no longer exists
- **WHEN** the drift check runs
- **THEN** it exits non-zero naming the chapter and the dead glob, distinguishing this from
  ordinary staleness

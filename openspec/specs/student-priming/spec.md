# student-priming Specification

## Purpose
TBD - created by archiving change add-engineering-manual-and-docs-ledger. Update Purpose after archive.
## Requirements
### Requirement: A deterministic bundle script exports the manual as one context artifact

A repo script SHALL concatenate the manual index plus selected chapters (`--all` or
`--chapters <names>`) into a single plain-text artifact prefixed with a generated table
of contents and per-chapter token estimates (chars/4 heuristic). Output SHALL be
deterministic for a given tree (no timestamps), contain no JSX-dependent content, and
subset bundles SHALL always include the standards preamble so they stand alone.

#### Scenario: Full bundle with token report

- **WHEN** the script runs with `--all`
- **THEN** it emits one artifact containing every chapter, a TOC, and a token-estimate
  table (per chapter + total)

#### Scenario: Subset bundle fits a small context

- **WHEN** the script runs with `--chapters sync`
- **THEN** the artifact contains the standards preamble + sync chapter only, and reports
  a total token estimate so the operator can budget a cheap model's context (e.g. NIM /
  Cerebras-hosted inference)

### Requirement: A primed student session is validated once against a real task

Before this change archives, a fresh session SHALL be primed with the bundle (no other
repo context) and given one small, real task touching a documented seam; the outcome
(succeeded without interference / where it stumbled) SHALL be recorded in the manual's
meta chapter as calibration for future delegation.

#### Scenario: Priming dry-run recorded

- **WHEN** the primed dry-run completes
- **THEN** the meta chapter records the task, model used, bundle subset, token weight,
  and outcome


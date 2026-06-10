# storage-hygiene

## ADDED Requirements

### Requirement: Stale folder elimination
The storage healing pass SHALL deterministically remove stale filesystem artifacts: empty directories under `Moves/`, legacy `Documents/videos/` content (migrated to canonical paths, then pruned), and temporary export directories older than 24 hours. Sweeps SHALL be idempotent — a second consecutive run performs zero mutations.

#### Scenario: Legacy directory retired
- **WHEN** `Documents/videos/` contains a video matching a DB row
- **THEN** the file is moved to its canonical semantic path, the row's path updated, and the empty legacy directory removed

#### Scenario: Idempotency
- **WHEN** the full hygiene sweep runs twice in a row
- **THEN** the second run reports 0 changes

### Requirement: Master ledger consistency
Every file in the content-addressed master SHALL be referenced by at least one of `asset_manifest`, `moves`, or `combo_note_entries.videoHash`. Unreferenced masters SHALL be quarantined to `Moves/Archive/` (never hard-deleted) with a provenance log entry.

#### Scenario: Orphan master quarantined
- **WHEN** a master hash file has no referencing row
- **THEN** it is moved to `Moves/Archive/`, logged, and counted — not deleted

### Requirement: Hygiene diagnostics
Each sweep SHALL log begin/stage/complete via StageLogger and surface counters (`staleFoldersRemoved`, `orphansQuarantined`, `pathsHealed`) on the diagnostics screen so physical-device testing failures are capturable from logs alone.

#### Scenario: Failure is capturable post-hoc
- **WHEN** a sweep fails on-device during user testing
- **THEN** the log contains the sweep name, the stage reached, and the error without needing a debugger attached

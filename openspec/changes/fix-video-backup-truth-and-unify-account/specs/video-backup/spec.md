# video-backup — Spec Delta

## ADDED Requirements

### Requirement: Integrity verification resolves stored paths

The integrity verifier SHALL resolve each manifest `localPath` (stored relative, v10+)
to an absolute device path via `VideoPathResolver` before hashing, so verification
verdicts reflect file reality, not path bookkeeping.

#### Scenario: Library of playable videos verifies clean

- **GIVEN** 67 manifest rows whose relative `localPath`s resolve to existing files
- **WHEN** the user runs Verify Integrity
- **THEN** the report counts 67 OK · 0 mismatched · 0 missing

#### Scenario: Genuinely missing file is still reported

- **GIVEN** a manifest row whose resolved absolute path does not exist on disk
- **WHEN** verification runs
- **THEN** that row is reported missing (the fix must not mask real losses)

### Requirement: Upload sweep is per-file, never blocked by one deferral

The underprotected-upload sweep SHALL evaluate network policy per file and skip
(not abort on) files deferred by `waitForWifi` or `dataCapExceeded`, queueing every
transferable file in the same pass.

#### Scenario: One oversized file does not block the library

- **GIVEN** 67 underprotected assets where the first evaluated file exceeds the mobile
  data cap and the rest fit
- **WHEN** a sync cycle runs on mobile data with sync-on-mobile enabled
- **THEN** the remaining 66 files are queued for upload and the oversized file is
  deferred, with the engine reporting pending work — not idle

### Requirement: A sync cycle drains the operation queue

A single sync cycle SHALL process queued operations in `maxConcurrent` batches until the
queue is empty or the engine is paused/offline — never a fixed single batch.

#### Scenario: Full library uploads in one user action

- **GIVEN** 67 queued upload operations and a Wi-Fi connection
- **WHEN** the user taps Sync Now once
- **THEN** the cycle continues batch after batch until all 67 operations complete or
  fail into the retry lane, without further user action

#### Scenario: Pause interrupts a drain promptly

- **GIVEN** a drain in progress
- **WHEN** the engine is paused
- **THEN** no new batch starts after the in-flight operations settle

### Requirement: Sync health derives from persistent protection state

Sync health surfaces (health dot, status labels, Sync Status screen) SHALL derive from
the database's underprotected count — a live asset lacking a verified cloud copy — and
SHALL NOT report "All synced" as a default when no engine progress has been emitted.

#### Scenario: Fresh launch with unprotected videos tells the truth

- **GIVEN** an app launch where 66 live assets have no verified cloud copy and the sync
  engine has not yet emitted progress
- **WHEN** the settings Video Backup section renders
- **THEN** it reports pending backup work (count visible), not "All synced"

#### Scenario: All synced means all synced

- **GIVEN** every live asset has ≥1 verified cloud copy alongside its local copy
- **WHEN** health is computed
- **THEN** it reports all-synced

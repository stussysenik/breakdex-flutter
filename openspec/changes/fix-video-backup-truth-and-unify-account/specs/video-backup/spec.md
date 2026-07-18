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

### Requirement: Progress reflects work as it completes, not only on state changes

Sync progress surfaces SHALL update as each operation settles, so a running sweep visibly
advances rather than freezing on the snapshot taken when the cycle began. Progress SHALL
be emitted after every operation reaches a terminal outcome (success or failure), in
addition to engine state transitions.

#### Scenario: The counter advances during a long sweep

- **GIVEN** 55 queued uploads and a Sync Status screen open on "17/72 synced"
- **WHEN** the first upload completes
- **THEN** the displayed count advances to 18/72 without waiting for the cycle to end

#### Scenario: A failed operation still advances the display

- **GIVEN** a drain in progress
- **WHEN** an operation fails terminally
- **THEN** progress re-emits (the failure is reflected immediately, not at cycle end)

### Requirement: In-flight transfers expose their live byte progress

While an upload is transferring, the app SHALL surface which asset is moving and how far
along it is (bytes transferred against total), so a large file over a slow network reads
as working rather than hung.

#### Scenario: A large upload shows movement

- **GIVEN** an 80 MB upload in progress on a slow connection
- **WHEN** the user watches the Sync Status screen
- **THEN** the asset is identified as uploading with an advancing byte/percentage
  readout, updating as the provider reports progress

### Requirement: A copy is identified by asset and provider

Copy records SHALL be uniquely identified by `(contentHash, provider)`. Recording a copy
for an asset+provider that already has one SHALL update that record, never append a
second. `copyCount` therefore counts distinct providers holding the asset, and can never
be inflated by repeated uploads of the same file.

#### Scenario: Re-uploading the same asset does not inflate its copy count

- **GIVEN** an asset with one verified local copy and one verified `gdrive` copy
  (`copyCount == 2`)
- **WHEN** an upload operation for that asset to `gdrive` runs again and succeeds
- **THEN** the existing `gdrive` copy record is updated in place and `copyCount` stays 2

#### Scenario: Duplicate historical copy rows are reconciled once

- **GIVEN** a database containing multiple copy rows for the same `(contentHash,
  provider)` pair, written before this rule existed
- **WHEN** the one-way migration runs
- **THEN** each pair collapses to a single record retaining the most protective status
  (`verified` wins over `pending`/`failed`) and every affected `copyCount` is recomputed,
  with no asset losing a copy record it genuinely has

### Requirement: Protection state reflects copies that actually exist

Every live asset whose file is present on disk SHALL have a verified `local` copy record,
so `copyCount` measures real protection rather than bookkeeping history. A reconcile
SHALL be able to rebuild missing copy records from observable ground truth.

#### Scenario: A legacy asset gains its missing local record

- **GIVEN** a live manifest row whose resolved `localPath` exists on disk but which has
  no `local` copy record (imported before local records were written)
- **WHEN** the copy reconcile runs
- **THEN** a verified `local` copy record is created and `copyCount` is recomputed

#### Scenario: Reconcile never invents a copy

- **GIVEN** a manifest row whose local file does not exist on disk
- **WHEN** the copy reconcile runs
- **THEN** no `local` copy record is created and the asset remains underprotected

### Requirement: Unbackupable assets fail terminally and visibly

An upload that fails because the asset's bytes are genuinely unavailable locally SHALL be
treated as terminal — not retried on backoff, not re-queued on later cycles — and the
affected assets SHALL be surfaced to the user as needing attention, separately from work
that is merely pending.

#### Scenario: A missing local file does not enter the retry lane

- **GIVEN** an upload operation whose asset has no local file and cannot be healed from
  any owning move or combo
- **WHEN** the operation runs
- **THEN** it fails terminally on the first attempt, consumes no retry budget, and is not
  re-attempted by subsequent sync cycles

#### Scenario: The user is told what cannot be backed up

- **GIVEN** 22 assets that failed terminally for missing local bytes
- **WHEN** the user opens Sync Status
- **THEN** those assets are reported as unbackupable with the reason, counted separately
  from pending uploads, so the pending count can reach zero honestly

#### Scenario: A network failure stays retryable

- **GIVEN** an upload that fails on a transport or provider error while the local file
  exists
- **WHEN** the failure is classified
- **THEN** it remains retryable under the existing backoff and retry-limit rules

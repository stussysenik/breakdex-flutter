# metadata-sync-backend

> Supersedes the deltas in `add-convex-sync-backend` (never archived, never deployed): the
> provider-neutral requirements are carried forward verbatim in spirit; the concrete provider is
> now Appwrite.

## ADDED Requirements

### Requirement: Provider-agnostic SyncBackend contract

The system SHALL define a provider-agnostic `SyncBackend` contract for metadata sync, distinct
from the asset/blob `AssetStorageProvider` contract. It SHALL expose push (upserts + tombstones),
pull (records changed since a server-issued cursor), and a reactive subscribe, keyed by entity
type. All callers SHALL depend on this contract, not on any concrete provider.

#### Scenario: Callers are provider-unaware
- **WHEN** a repository writes a metadata change
- **THEN** it invokes `SyncBackend` and has no compile-time dependency on Appwrite or Firestore

#### Scenario: Swapping providers requires no caller change
- **WHEN** the backing deployment changes (Appwrite Cloud → self-hosted Appwrite)
- **THEN** only configuration (endpoint/project keys) changes and no caller is modified

### Requirement: Appwrite is the canonical metadata backend

The system SHALL implement `SyncBackend` against Appwrite as the canonical metadata backend,
superseding the Convex selection in `add-convex-sync-backend` while honoring
`add-beam-web-architecture-foundation`'s abstract capabilities (`web-access-foundation`,
`provider-pluggability-posture`). Server-side conflict resolution (last-writer-wins on
`updatedAt`) and `clientOpId` idempotency SHALL be enforced in Appwrite Functions, not trusted to
clients. Self-hosting Appwrite SHALL be a configuration swap requiring no caller changes.

#### Scenario: App and web read one live truth
- **WHEN** a metadata change is committed on any client
- **THEN** Appwrite Realtime delivers the change to subscribed app and web clients

#### Scenario: Replayed push is idempotent
- **WHEN** a client re-sends a push batch containing an already-applied `clientOpId`
- **THEN** the server applies it at most once and no record is double-applied

#### Scenario: Self-host cutover is config-only
- **WHEN** the owner points `APPWRITE_ENDPOINT`/`APPWRITE_PROJECT_ID` at a self-hosted deployment
- **THEN** the same `SyncBackend` implementation operates against it without code changes

### Requirement: Local Drift store stays canonical until verified cutover

The local Drift database SHALL remain the authoritative source on-device, and the Appwrite
backend SHALL be treated as a shadow copy per entity, until that entity's two-way reconcile is
verified against (a copy of) real data. Backfills SHALL be non-destructive, proven by a
byte-identical before/after local snapshot.

#### Scenario: Backfill never mutates local state
- **WHEN** an entity is backfilled into the Appwrite shadow
- **THEN** a before/after snapshot of the local database is byte-identical

### Requirement: Strangler-fig migration with dual-write preceding dual-read

Each entity SHALL migrate in the order: backfill → dual-write (Firestore AND Appwrite) →
dual-read (Appwrite first, Firestore fallback) → verified cutover. Dual-read SHALL NOT be
enabled for an entity before its dual-write is live. Every step SHALL be gated by a per-entity
preference acting as an instant kill-switch, and disabling it SHALL restore the prior behavior
without data loss. The backend pull cursor SHALL be a dedicated, server-issued high-water mark
persisted per entity, never shared with the Firestore sync clock.

#### Scenario: Kill-switch rollback is lossless
- **WHEN** the owner disables an entity's dual-read after a soak period
- **THEN** subsequent syncs serve that entity from Firestore including all changes made during
  the soak window (no cursor hole)

#### Scenario: Backend failure never blocks sync
- **WHEN** an Appwrite pull fails or a record in the delta is malformed
- **THEN** the malformed record is skipped and counted, remaining records apply, and the entity
  falls back to the Firestore path for that cycle

### Requirement: Deletes propagate as tombstones

No hard-delete SHALL cross the sync boundary in either direction. Removal is expressed as a
tombstone record; clients hide tombstoned rows without destroying local user state.

#### Scenario: Cross-device delete is recoverable
- **WHEN** a move is deleted on device A
- **THEN** device B receives a tombstone, hides the row, and no video bytes or local rows are
  hard-deleted by the sync layer

### Requirement: FSRS state reconciles event-sourced, not last-writer-wins

Review ratings SHALL sync as append-only `reviewEvents` (idempotent by `clientOpId`).
`fsrsCards` SHALL be derived server-side by reducing the event log — using the same `fsrs`
package version as the client so scheduling math is identical — and SHALL never be pushed by
clients nor LWW-overwritten.

#### Scenario: Concurrent reviews on two devices converge
- **WHEN** the same card is reviewed offline on two devices which later both flush
- **THEN** both events append and the derived card state reflects the full event log

### Requirement: The backend stores video pointers only

Metadata records SHALL carry only video pointers (Drive file id / object key) plus content hash.
Video bytes SHALL NOT flow through the metadata backend; Google Drive remains the canonical blob
store on the existing `AssetStorageProvider` plane.

#### Scenario: Sync payloads are metadata-sized
- **WHEN** any entity syncs
- **THEN** the payload contains pointers and descriptive fields, never media bytes

### Requirement: Metadata export safety net

The system SHALL periodically export all metadata entities (including tombstones) as versioned
JSON to the user's Google Drive, restorable independently of any backend vendor.

#### Scenario: Vendor-independent recovery
- **WHEN** the Appwrite deployment becomes unavailable or is decommissioned
- **THEN** the latest Drive JSON export suffices to reconstruct all metadata

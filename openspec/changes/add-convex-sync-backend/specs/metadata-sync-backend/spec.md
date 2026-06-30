# metadata-sync-backend

## ADDED Requirements

### Requirement: Provider-agnostic SyncBackend contract

The system SHALL define a provider-agnostic `SyncBackend` contract for metadata sync, distinct
from the asset/blob `AssetStorageProvider` contract. It SHALL expose push (upserts + tombstones),
pull (records changed since a cursor), and a reactive subscribe, keyed by entity type. All callers
(`sync_service`, `sync_aware_repositories`) SHALL depend on this contract, not on any concrete
provider.

#### Scenario: Callers are provider-unaware
- **WHEN** a repository writes a metadata change
- **THEN** it invokes `SyncBackend` and has no compile-time dependency on Convex or Firestore

#### Scenario: Swapping providers requires no caller change
- **WHEN** the backing provider changes (Convex Cloud → self-hosted Convex, or another provider)
- **THEN** only the `SyncBackend` implementation changes and no caller is modified

### Requirement: Convex is the canonical metadata backend

The system SHALL implement `SyncBackend` against Convex (Convex Cloud) as the canonical metadata
backend, superseding the `Phoenix + Postgres + S3-compatible` stack named in
`add-beam-web-architecture-foundation` while honoring that change's abstract capabilities
(`web-access-foundation`, `provider-pluggability-posture`). Self-hosting Convex SHALL remain an
available escape hatch and SHALL NOT require caller changes.

#### Scenario: App and web read one reactive truth
- **WHEN** a metadata change is committed on any client
- **THEN** Convex reactively delivers the change to subscribed app and web clients (eventual-realtime)

#### Scenario: Self-host escape hatch preserved
- **WHEN** the owner elects to self-host Convex
- **THEN** the `SyncBackend` implementation can target the self-hosted deployment without altering callers

### Requirement: Local Drift store stays canonical until verified cutover

The local Drift database SHALL remain the authoritative source on-device, and the Convex backend
SHALL be treated as a shadow copy per entity, until that entity's two-way reconcile is verified.
This change SHALL be additive: it SHALL NOT delete or mutate any existing local row. Each
per-entity cutover SHALL be reversible to local-authoritative without data loss.

#### Scenario: No local row is destroyed
- **WHEN** the change is applied and the backfill runs against a populated local database
- **THEN** every local row is preserved and none is deleted or mutated

#### Scenario: Cutover gated on verified reconcile
- **WHEN** an entity's two-way reconcile has not been verified
- **THEN** Drift remains authoritative for that entity and Convex stays a shadow copy

#### Scenario: Cutover is reversible
- **WHEN** an issue is detected after an entity is cut over
- **THEN** the system reverts that entity to local-authoritative without data loss

### Requirement: Strangler-fig migration off Firestore with dual-read

The migration off Firestore SHALL proceed one entity at a time in the order
`moves → combos → reviews → fsrs_cards → decks`. During an entity's cutover the system SHALL
dual-read (Convex first, Firestore fallback) so a Convex gap cannot blank the UI, and SHALL remove
the Firestore path for that entity only after its reconcile is verified green.

#### Scenario: Dual-read prevents blank UI mid-cutover
- **WHEN** Convex lacks a record that exists in Firestore during cutover
- **THEN** the system falls back to the Firestore copy and the UI renders the record

#### Scenario: Firestore retired per entity only when proven
- **WHEN** an entity's reconcile is verified against a copy of real data
- **THEN** the Firestore read path for that entity may be removed, leaving other entities untouched

### Requirement: Deletes propagate as tombstones

Removal of a metadata record SHALL propagate across the sync boundary as a soft-delete tombstone
carrying `{id, type, deletedAt}`. The system SHALL NOT hard-delete user state across sync. Reconcile
SHALL apply tombstones by last-writer-wins on a monotonic timestamp.

#### Scenario: Delete on one client tombstones, not destroys
- **WHEN** a record is deleted on one client
- **THEN** a tombstone is pushed and reconciled on other clients, and no hard-delete crosses the boundary

### Requirement: FSRS state reconciles event-sourced, not last-writer-wins

Review ratings SHALL be recorded as append-only, immutable events carrying
`{entityId, entityType, rating, reviewedAt, clientOpId}`. Derived FSRS card state (stability,
difficulty, due) SHALL be computed by a Convex function that reduces the review-event log, and
SHALL NOT be reconciled by last-writer-wins on the card record. Replaying a duplicate
`clientOpId` SHALL NOT change the derived state (idempotent).

#### Scenario: Concurrent reviews do not regress scheduling
- **WHEN** two devices each submit a review for the same card while offline and later sync
- **THEN** both review events are appended and the derived card state reflects the reduced log, with no stale write regressing the schedule

#### Scenario: Duplicate review submission is idempotent
- **WHEN** a review event with an already-seen `clientOpId` is pushed again on retry
- **THEN** the derived FSRS state is unchanged

### Requirement: Convex stores video pointers only

Convex records SHALL store only references to video assets (Drive file id / object key), never
video bytes. Video bytes SHALL remain on the asset plane (`AssetStorageProvider` / Google Drive),
preserving metadata/media separation.

#### Scenario: A move record carries a pointer, not bytes
- **WHEN** a move with a video is synced to Convex
- **THEN** the Convex record holds the Drive pointer and contains no video bytes

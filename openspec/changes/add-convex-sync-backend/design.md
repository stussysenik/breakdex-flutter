# Design — Convex Canonical Backend via SyncBackend

## Context

Breakdex is a brownfield, local-first Flutter app (Drift/SQLite canonical on-device) with
deployed users and data. Two data planes already exist and must stay separated:

- **Asset plane** — videos. Owned by `AssetStorageProvider` / `CloudProvider`
  (`lib/core/sync/cloud_provider.dart`): iCloud, Google Drive, S3. **Untouched by this change.**
- **Metadata plane** — moves, combos, reviews, fsrs_cards, decks (+ tombstones). Currently synced
  via `sync_service.dart` on `cloud_firestore`. **This change moves it onto Convex behind a new
  contract.**

The repo's `add-beam-web-architecture-foundation` contract defines the canonical-backend
capabilities abstractly; the owner has chosen **Convex** as their implementation (superseding the
Phoenix+Postgres+S3 stack). Convex is open-source/self-hostable, so Cloud-now / self-host-later
keeps the no-lock-in posture.

## Goals / Non-goals

**Goals**
- One reactive metadata truth serving the Flutter app now and web + native clients later.
- Strangler-fig off Firestore with zero loss and reversible per-entity cutovers.
- A `SyncBackend` interface so Convex is swappable (self-host, or another provider) without
  touching callers.

**Non-goals**
- Auth migration, web CRUD UI, video/asset changes, self-host provisioning (all later).

## Decisions

### Decision 1 — Canonical backend = Convex (Cloud now, self-host escape hatch)
Convex Cloud is managed and reactive, the fastest path to ASAP. Lock-in is mitigated because
Convex is open-source and self-hostable on Postgres. Recorded as the chosen implementation of the
`web-access-foundation` and `provider-pluggability-posture` capabilities.

### Decision 2 — A new metadata `SyncBackend` contract, parallel to `AssetStorageProvider`
The existing `AssetStorageProvider` is a *blob* contract (upload/download/verify). Metadata sync
needs a different shape: push/pull *records* by entity type, reconcile, tombstone. We add a
distinct `SyncBackend` interface rather than overloading the asset contract (SRP). Sketch:

```
abstract interface class SyncBackend {
  String get providerType;                       // 'convex'
  Future<void> push(EntityType type, List<SyncRecord> upserts, List<Tombstone> deletes);
  Future<SyncDelta> pull(EntityType type, {DateTime? since});  // records changed since cursor
  Stream<SyncDelta> subscribe(EntityType type);  // reactive eventual-realtime
}
```
`SyncRecord` carries `{id, type, json, updatedAt}`; `Tombstone` carries `{id, type, deletedAt}`.
Reconciliation is **last-writer-wins per field on monotonic `updatedAt`**, single-writer-at-a-time
(matches the assumption already adopted in `shared-source-of-truth`).

### Decision 3 — Drift stays canonical until each entity's reconcile is verified
The backend is a **shadow** copy per entity. Writes apply optimistically to Drift, then write
through to Convex. An entity is "cut over" only after its two-way reconcile is verified against a
copy of real data; until then Drift is authoritative and the cutover is reversible.

### Decision 4 — Strangler-fig order: `moves → combos → reviews → fsrs_cards → decks`
Highest-value, lowest-fan-in first (`moves`), then dependents. During each entity's cutover, reads
**dual-read** (Convex first, Firestore fallback) so a Convex gap can't blank the UI. Firestore is
removed for an entity only when its reconcile is green.

### Decision 5 — Video stays on Drive; Convex stores pointers only
A move's Convex record holds the Drive file id / object key — never bytes. Keeps Convex storage
caps irrelevant (metadata is bytes-per-record) and preserves the asset/metadata separation the
beam contract requires.

### Decision 6 — Convex client boundary is HTTP-swappable
Flutter has no first-party Convex SDK (community `convex_flutter` wraps Convex's Rust core). To
de-risk: the Convex impl of `SyncBackend` is the *only* place that touches the client, and it can
fall back to Convex's HTTP API if the community client disappoints. Native Swift/Kotlin clients
(first-party) are used when those apps are built.

## Local ↔ cloud workflow

```
WRITE  user edits a move
  → Drift writes locally (instant, offline-safe)        ← UI never blocks on network
  → SyncBackend.push(moves, [record], []) → Convex mutation (server-side FSRS/combo logic)
  → Convex reactively fans the change to web + other devices

READ   app opens / reconnects
  → SyncBackend.subscribe(moves) pushes deltas → Drift updates → UI rebuilds
  → offline: Drift serves cache; queued pushes flush on reconnect

DELETE → tombstone pushed; never hard-delete across the boundary

VIDEO  bytes on Google Drive (AssetStorageProvider); Convex record holds the pointer only
```

## Convex schema mapping (from Drift metadata tables)

| Drift table | Convex table | Notes |
|---|---|---|
| `moves` (incl. `originalVideoName`) | `moves` | `driveFileId` pointer; no bytes |
| `combos`, `combo_moves` | `combos`, `comboMoves` | relations preserved as fields/ids |
| `reviews` (has `comboId`) | `reviews` | |
| `fsrs_cards` (entityId+entityType) | `fsrsCards` | polymorphic key kept |
| `decks`, `deck_moves` | `decks`, `deckMoves` | |
| tombstones (`sync_log` / `sync_operations`) | per-table `deletedAt` | soft-delete |

Each Convex table carries `updatedAt` for LWW reconciliation and the local row id for identity.

## Risks & mitigations

- **Flutter Convex client maturity** → contract isolates it; HTTP fallback (Decision 6).
- **Superseding a prior decision** → resolved explicitly with the owner; same abstract
  capabilities honored, only the stack changes (no parallel architecture).
- **Data loss during cutover** → shadow + dual-read + backfill-on-copy + reversible per-entity
  cutover + tombstone deletes (Decisions 3/4 + spec invariants).
- **Lock-in creep** → self-host escape hatch documented; periodic JSON export of metadata to the
  user's Drive so the user always owns a full copy.

## Open questions

- **Convex Auth vs keep Firebase Auth as IdP** — deferred to the follow-on auth change.
- **Exact reconcile cursor** (`updatedAt` watermark vs Convex change-stream) — settle during
  Phase 1 against real data.

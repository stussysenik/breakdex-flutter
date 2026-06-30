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

### Decision 7 — FSRS state reconciles event-sourced, NOT last-writer-wins
LWW-per-field (Decision 2) is correct for descriptive records (move names, combo structure) but
**wrong for FSRS scheduling state**: two devices reviewing the same card concurrently would let a
stale write *regress* the schedule. Instead, **review events are append-only** (each rating is an
immutable `{entityId, entityType, rating, reviewedAt, clientOpId}` row), and the derived card
state (stability/difficulty/due) is **computed by a Convex function** that reduces the event log.
This matches the repo's existing event-sourced direction (`add-protobuf-event-envelope-and-upload-spool`,
`add-provenance-ledger-and-beam-ingestion-contract`). Append + reduce is also idempotent under
retry via `clientOpId`.

### Client boundary — who talks to Convex, and how (per-platform thin clients)
`SyncBackend` is the **Flutter app's** adapter only. The web and native clients do **not**
implement it — they use Convex's own first-party clients. What is shared "write once" is the
**Convex schema + functions**, not the Dart contract:

```
        ┌──────── SHARED: Convex schema + functions (FSRS reduce, combos, tombstones) ────────┐
        Flutter (Dart SyncBackend → convex_flutter/HTTP) │ Web (Convex React client) │ Native (Swift/Kotlin, first-party)
```
The web client thus stays thin: reactivity is free (Convex subscriptions, no custom sync code,
which dissolves the `manifest.json` clobber problem), and business logic lives server-side in
Convex functions rather than being re-implemented per platform.

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
| `reviews` (has `comboId`) | `reviewEvents` | append-only event log (Decision 7) |
| `fsrs_cards` (entityId+entityType) | `fsrsCards` (derived) | computed by Convex reduce; not LWW-written |
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

## Full-stack roadmap (sibling changes — this change stays scoped to metadata sync)

Risk-ordered. Each is its own OpenSpec proposal; none expands this change.

0. **Launch-blocker audit** (no code) — App Store signing; **Apple Guideline 4.8** (offering
   Google Sign-In typically requires also offering *Sign in with Apple*); privacy nutrition labels
   (Convex + Drive disclosure); **Google Drive OAuth verification** (sensitive scopes → weeks).
   Run first, in parallel with everything.
1. **`add-convex-sync-backend`** (this) — metadata truth + `SyncBackend` + strangler off Firestore;
   FSRS event-sourced.
2. **`evolve-web-mirror-to-crud-platform`** (exists) — rewire Next.js onto Convex; `drive.ts` →
   media-by-pointer; web CRUD.
3. **`convex-auth-and-identity`** (new) — Firebase Auth as IdP → Convex identity; offer **both
   Google Sign-In and Sign in with Apple** (the latter satisfies Apple Guideline 4.8 when Google
   sign-in is present); access rules authorize by server-derived identity (never client-passed
   userId).
4. **`convex-scheduled-reminders-and-push`** (new) — Convex **cron/scheduled functions** compute
   due FSRS cards server-side → APNs/FCM review reminders. (Spaced-repetition reminders are a
   backend job, not a local timer.)
5. **`ios-native-surface`** (new, incremental) — WidgetKit home-screen widget (reads a compact
   Convex summary doc via App Group); App Intents / Siri Shortcuts → Convex mutations; Share
   Extension → upload spool; Live Activities for drills/battles; BGTaskScheduler background
   refresh (flush queued pushes + pull deltas).
6. **Video reliability stays on existing tracks** — `add-self-healing-video-reliability-runtime`,
   `add-protobuf-event-envelope-and-upload-spool`,
   `add-declarative-storage-truth-and-content-addressable-materialization`. Convex only stores the
   pointer **+ content hash**; it never owns bytes. A reconciler detects orphaned pointers (record,
   no bytes) and orphaned bytes (file, no record).

## Cross-cutting (apply across all of the above)

- **Schema evolution / version skew** — Convex schema migrations are additive-only; a
  `minClientVersion` gate forces upgrade so a stale client can't write the old shape onto new data.
- **Idempotency** — every push carries a `clientOpId`; retries never double-apply.
- **Security** — Convex functions authorize by auth-context identity; rate-limit mutations.
- **Observability** — Convex function logs + client crash reporting; surface health in the existing
  `sync_status_screen`.
- **Cost** — metadata-only stays under Convex free tier; **function-call volume** (incl. chatty
  subscriptions) is the lever, not storage. Add budget alarms.

## Open questions

- **Convex Auth vs keep Firebase Auth as IdP** — deferred to the follow-on auth change.
- **Exact reconcile cursor** (`updatedAt` watermark vs Convex change-stream) — settle during
  Phase 1 against real data.

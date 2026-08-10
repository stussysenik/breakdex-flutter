# Reverse Album Delete Archive & Recovery

> **Language: Dart (Flutter) + native iOS (PhotoKit).** Depends on: `appwrite`
> (sync metadata), `enforce-face-law-conformance` (Recently Deleted UI on `AppScreen`).
> Implementation in a fresh student session — never this one.

## Why

The media contract is **one-way**: Breakdex cleans up Photos copies it owns, but when a
user *externally* deletes a Breakdex-managed album copy in Photos, the app stays stale.
There is no move-level archive/recovery flow, so the only safe behavior today is to
leave broken rows behind. Hard-deleting the move immediately is unsafe — Photos deletion
is reversible and may propagate through iCloud — and loses the user's data on a
non-destructive action.

A recoverable archive state is the safer model and matches how serious media apps
separate library truth (Breakdex is canonical) from exported projections (Photos albums
are managed copies):

1. **External delete → archive, don't delete.** When a tracked managed Photos asset
   disappears, archive the move (`archivedAt`, `archiveReason`) and remove it from
   active drill/list/review surfaces. The record stays restorable for 30 days.
2. **Reconcile on managed-asset identity.** Each move already stores the exact Photos
   `localIdentifier` of its managed album copy. Reconciliation compares tracked IDs
   against `PHAsset.fetchAssets(withLocalIdentifiers:)` — never filename scanning.
3. **Restore recreates the projection.** Restoring requires a valid local video, then
   recreates the managed album copy, stores the new exact asset metadata, and clears
   archive fields. Missing-video or failed-recreation fails *explicitly* and leaves the
   move archived.
4. **iCloud-backed retrieval is documented, not built.** Photos-backed recovery uses
   asset-identity retrieval (`requestAVAsset`, `PHAssetResourceManager` with network
   enabled), not filename scanning. This slice documents the path; the restore-from-
   iCloud-Photos UI is out of scope.

This change absorbs the (now-archived) duplicate `add-photo-library-archive-recovery`,
which shared identical Phase 1 work.

## What Changes

- **Archive model.** Moves gain nullable `archivedAt` + `archiveReason`. Active queries
  exclude archived rows; detail views still resolve by ID so in-flight screens don't
  crash if reconciliation happens mid-session.
- **Reconciliation service.** Extends the iOS Photos bridge with read-access +
  managed-asset lookup; Dart owns the DB-aware reconcile (startup, resume, PhotoKit
  library-change event).
- **Recently Deleted UI.** A dedicated `AppScreen` surface listing archived moves with
  restore + permanent-delete, linked from Settings → Data.
- **30-day purge.** Expired archived moves purge via the existing cleanup service
  (files, thumbnails, content-addressed state, managed Photos copies removed
  consistently).
- **Archive syncs as update, not delete.** `archived_at`/`archive_reason` ride move
  metadata (Appwrite), preserving the recoverable-vs-hard-delete distinction.

## Capabilities

1. `managed-photos-reconciliation` — reconcile tracked Photos asset IDs against the
   library and archive missing items safely.
2. `recently-deleted-moves` — restore or permanently delete archived moves from a
   recoverable inbox.
3. `archive-sync-state` — persist archived move state locally and through move metadata.

## Footprint estimate

| Surface | Current → Target | Notes |
| --- | --- | --- |
| `lib/features/move_detail/data/` | +archive columns + DAO helpers, ~60 LOC | Phase 1 partially landed (`5707fe1`/`b28cfa1`/`d382437`) |
| `lib/core/services/` | +reconciliation service, ~120 LOC | startup/resume/PhotoKit triggers |
| native iOS bridge | +read/lookup reconcile APIs, ~80 LOC | PhotoKit, auth only when tracked assets exist |
| `lib/features/settings/` | +Recently Deleted screen, ~100 LOC | on `AppScreen`, restore + purge |
| `test/` | +reconcile/restore tests, ~120 LOC | archive filtering, reconcile, restore paths |

Net: ~480 LOC, +4–5 files. Phase 1 data work already landed.

## Non-goals

- **No full combo-level archive parity** — move-level only this slice.
- **No automatic iCloud re-download** — Photos-backed restore path is documented, not
  built (out of scope).
- **No Supabase.** The old draft referenced Supabase; the canonical backend is Appwrite
  (locked ruling). Archive state rides Appwrite move metadata.
- **No full Settings/Move Detail redesign** — Recently Deleted links from Settings →
  Data.

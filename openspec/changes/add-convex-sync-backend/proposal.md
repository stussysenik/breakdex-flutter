# Adopt Convex as the Canonical Backend via a Provider-Agnostic SyncBackend

## Summary

Choose **Convex** as Breakdex's canonical backend and deliver the first load-bearing slice: a
provider-agnostic **`SyncBackend`** metadata-sync contract, with a **Convex** implementation that
strangler-figs the app off **Firestore** one entity at a time (`moves → combos → reviews →
fsrs_cards → decks`). The Flutter app keeps running unchanged; **Drift/SQLite stays canonical
locally** and the backend is a shadow copy until each entity's reconcile is verified.

This is the slice that makes the app and a future web client read/write **one reactive source of
truth** without vendor lock-in: Convex is open-source and self-hostable, so Convex Cloud is the
fast-track now and self-hosting is the escape hatch later. **Video is out of scope of this
contract** — it stays on Google Drive (the existing `AssetStorageProvider` plane); Convex stores
pointers only.

## Motivation

- **Launch ASAP, fast-track, build-once.** The owner is shipping to the App Store and Google Play
  as soon as possible and wants one reactive backend serving the Flutter app now and native
  Swift/Kotlin + web later. Convex Cloud is managed (zero infra), reactive out of the box, has
  first-party Swift/Kotlin clients, and a generous free tier — metadata-only stays far under caps
  because video lives on Drive.
- **No lock-in.** Convex is open-source and self-hostable (Docker/binary, Postgres-backed). The
  lock-in objection that ruled out Firebase does not bind here: the cutover to self-hosting is an
  available lever, not a rewrite.
- **The current metadata sync is Firestore.** `cloud_firestore` backs metadata sync today through
  `sync_service.dart`. To unify app + web on a reactive truth, that path must move behind a
  swappable contract and onto Convex.

## Relationship to existing changes

- **Supersedes** the canonical-backend *stack choice* in `add-beam-web-architecture-foundation`:
  the abstract capabilities (`web-access-foundation`, `provider-pluggability-posture`,
  metadata/media separation) are **kept and honored**; their chosen implementation changes from
  `Phoenix + Postgres + S3-compatible` to **Convex** (Cloud now, self-host later). This is a
  revision of the chosen stack, **not** a parallel architecture.
- **Resolves Open Decision 1** of `evolve-web-mirror-to-crud-platform` (was "Firestore interim,
  swappable to Phoenix later") toward **Convex** as the canonical backend, and **concretizes** that
  change's planned provider-agnostic sync contract (its task 1.1) as the `SyncBackend` interface
  defined here. The web CRUD, reconcile, and persistent-media work there builds on this contract.
- **Scope boundary.** This change delivers metadata sync only. Auth migration (Firebase Auth →
  Convex Auth) and web CRUD are **follow-on changes**, not part of this slice.

## Data safety (non-negotiable — production app with deployed data)

- **Additive and reversible.** No existing local row is deleted or mutated by this change. Drift
  remains authoritative until each entity's two-way reconcile is verified; the backend is a shadow
  copy until then. Every per-entity cutover is reversible to local-authoritative.
- **Deletes are tombstones.** Removal propagates as a soft-delete tombstone; user state is never
  hard-deleted across the sync boundary.
- **Backfill on a copy first.** The non-destructive backfill is validated against a copy of real
  data before touching the live store.

## Scope

### In scope
- A provider-agnostic `SyncBackend` metadata-sync contract (push/pull deltas, reconcile,
  monotonic `updatedAt`, tombstone delete).
- A Convex implementation of `SyncBackend` (Convex Cloud), plus the Convex schema mapped from the
  Drift metadata tables and the queries/mutations that hold the sync logic.
- Strangler-fig migration off Firestore, one entity at a time with dual-read during cutover.
- Wiring the contract behind `sync_service` / `sync_aware_repositories` so callers are
  provider-unaware.

### Out of scope
- Migrating Firebase **Auth** or Firebase **Storage** (asset plane) — later changes.
- Web CRUD UI (delivered by `evolve-web-mirror-to-crud-platform` on top of this contract).
- Self-hosting Convex (documented as the escape hatch; not provisioned in this slice).
- Any change to the video/asset plane (`CloudProvider` / Google Drive) beyond storing pointers.

## Capabilities

1. `metadata-sync-backend` — the provider-agnostic `SyncBackend` contract, its Convex
   implementation, the additive strangler-fig migration off Firestore, and the data-safety
   invariants that keep the local store canonical until each entity is proven.

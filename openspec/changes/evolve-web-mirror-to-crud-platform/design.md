# Design — Evolve the Web Mirror into a Read-Write Platform

## Context

Today: the Flutter app's local **Drift** DB is the source of truth; `manifest_sync_service.dart`
serializes the *entire* library and uploads `manifest.json` to Drive on a 5s debounce; videos go
up content-addressed (`Breakdex/<contentHash>.mp4`). The web mirror (`web-mirror/`) reads that
manifest and streams videos — strictly read-only.

This is a **one-way** pipeline (phone → Drive, full overwrite). It cannot support web writes: any
edit the web makes to the Drive manifest is destroyed the next time the phone re-uploads.

## The core decision: invert the truth, keep clients as caches

The owner's framing is the design: **promote a shared backend to source of truth; make every
local store a cache.** Consequences:

- The phone no longer "owns" truth via its local DB; it **syncs** to the canonical backend and
  caches it locally (offline-first read, write-through on edit).
- The web client reads/writes the same canonical truth, caching locally (IndexedDB) and caching
  media persistently (Cache API) so a given video downloads once.
- Drive remains the **media** store (large blobs), globally synced and addressed by content hash;
  the canonical backend holds **metadata truth** (moves, combos, journal, plans, FSRS, review
  log) and the media index. Metadata and media ownership stay separated, matching the BEAM
  contract.

Once both clients reconcile against one truth, **writing from either side is safe** — there is no
manifest to clobber. This is why CRUD is a *consequence* of Phase 1, not a thing we hand-build
against production data first.

## Why sequence by risk (and not "full CRUD now")

`add-web-mirror-player` carries a non-negotiable data-safety clause, and this is a production app
with real data. Building bidirectional CRUD before the truth layer exists means web writes fight
the phone's overwrite — data loss. So:

- **Phase 1 (the unlock):** stand up the canonical backend + sync client as a **shadow** of the
  local DB. Non-destructive backfill (read local → write backend). Local DB stays authoritative.
  Verify two-way reconcile. This phase is invisible to users and reversible.
- **Phase 2 (CRUD):** flip web (and phone) to treat the backend as truth *after* reconcile is
  verified. Now journal/rename/metadata edits are safe write-throughs.
- **Phase 3 (media):** export governance + video swap-out as copy-then-verify writes to Drive,
  with the canonical index updated only after the new blob is confirmed.

Each phase is independently shippable and individually reversible.

## Decision 1 — source-of-truth provider (RESOLVED 2026-06-16)

**Resolved: B behind C.** Stand up **Firestore as the concrete interim backend** (option B) but
strictly *behind the provider-agnostic sync contract* (option C). The contract specs the property
(truth + cache + reconcile, monotonic `updatedAt`, soft-delete) with no Firestore types leaking
across the boundary, so the implementation can be swapped to the recorded `Phoenix + Postgres + S3`
contract (option A) later without re-spec. Rationale: `firebase.ts` and Firebase Auth already exist
in `web-mirror/`, so this is the fastest path to a *shadow* store for backfill/reconcile, while the
contract keeps the recorded BEAM direction reachable. The swap-to-A decision is deferred until
Phase 2 ships (or sooner if relational query needs force it).

### Original options (for the record)

The recorded contract (`add-beam-web-architecture-foundation`) says
`Phoenix + Postgres + S3-compatible storage`, provider-pluggable, *specifically to avoid parallel
architectures*. The owner floated **Firestore** (already have Firebase Auth; faster to ship).

| Option | Pros | Cons |
| --- | --- | --- |
| **A. Honor contract (Phoenix/Postgres/S3)** | Coherent with recorded direction; no parallel arch; real relational truth; S3 for media | Most infra to stand up; slowest first slice |
| **B. Firestore interim, behind the sync contract** | Ships fastest; reuses Firebase project/auth; managed | Deviates from the recorded contract; risks the parallel architecture the contract warns against; weaker relational/query story |
| **C. Provider-agnostic contract now, defer impl** *(proposed default)* | Specs the *property* (truth + cache + reconcile) without vendor lock; lets us prototype with Firestore yet swap to Phoenix without respec | Adds an abstraction layer; the provider choice still has to be made before Phase 2 ships |

**Recommendation:** **C** — spec the sync contract provider-agnostically (this change), and make
the concrete provider an explicit Phase-1 task gated on the owner choosing A vs B. This is the
only way to respect the existing contract *and* the owner's "ship fast" instinct without
unilaterally overriding a recorded decision.

## Open decision 2 — Drive scope

`drive.file` (current) only sees files this project created. For web **video swap-out** the web
client must create/replace media files — `drive.file` covers files it creates, but enumerating
pre-existing media the *phone* created across a different OAuth client can be unreliable. If
verification (existing task 3.4) shows gaps, move to `drive.readonly` for reads and keep
`drive.file` for writes, or consolidate the OAuth client. Decision deferred to the Phase-1
verification result.

## Reactive streams & UI

- **Web:** RxJS models the sync/cache streams (backend snapshot → cache → view) and debounced
  write-through. Fits React via hooks over observables.
- **Flutter:** keep Riverpod + Dart `Stream`s; add `rxdart` only if specific operators are needed.
  **No RxJS in Dart.**
- **Enterprise shell:** a persistent top toolbar (account, sync status, global actions), explicit
  left/section navigation, and **breadcrumbs** reflecting Section ▸ Subsection ▸ Item. Animations
  are purposeful (route/section transitions, optimistic-write feedback, video modal) — additive,
  never blocking.

## Sync & conflict model (provider-agnostic)

- **Write-through + optimistic UI:** client applies edit locally, enqueues a write to the backend,
  reconciles on ack.
- **Single-writer-at-a-time assumption:** the owner is one person; last-writer-wins per field with
  a monotonic `updatedAt` is sufficient for v1. The contract leaves room for CRDT later (per the
  BEAM foundation's "selective CRDT").
- **Never-delete:** deletes are soft (archive) with recovery, matching the app's existing
  `move_archive_reason` semantics.
- **Media:** content-addressed; swap-out writes a new hash, updates the index, and only then marks
  the old blob orphaned (GC is a separate, audited, non-urgent step — never inline delete).

# Make the Web a Trustworthy System-of-Record and Authoring Studio

## Summary

Turn the read-only web mirror into the place the owner can **trust as the permanent record** of the
library *and* **author from** — at a desktop, away from the phone. Three things make it "the real
product":

1. **See everything first.** The web shows *all* videos and library data (moves, combos, sets,
   notes, plans) — the complete read surface — before any write feature is turned on.
2. **Trust the writes.** When the web says it changed something, it *actually* changed the canonical
   truth — verified write-through with visible sync status, and every change recorded.
3. **Nothing is ever lost.** Every move carries its **full lifecycle** (created → edited → combined
   → reviewed → archived), and **a deleted move stays accessible in the `/web` view**. The phone is
   ephemeral and local; the web is the durable, hyperlinked record it can't be.

On that trustworthy base sit the **authoring studio** tools the owner named: a `/combo-builder`
(assemble combos as *ordered* move sequences, attach video) and a `/set-builder` (assemble decks),
both **seeded by combinatorics** — the existing `neverCombinedCandidates()` brain surfaces "moves
that want to be combined."

## Motivation

- **The owner wants to control and grow the library from the web** ("airport, on a laptop, go to
  `/web`"), not just view it. The mirror is view-only today, so authoring is impossible.
- **Trust is the product.** Web writes are only worth anything if the owner can trust they *actually
  landed* and that nothing gets silently clobbered or erased. Verified write-through + a lifecycle
  record is what earns that trust.
- **Permanence is the gain the phone can't give.** A deleted move vanishing forever is a data-loss
  liability (see `[[feedback_data_safety_protocol]]`). Keeping deleted entities visible in `/web`
  turns deletion from loss into archival — the durable, decades-spanning record the
  `[[project_archive_vision_cultural_graph]]` vision points at.
- **The combinatorial brain already exists.** `web-mirror/src/lib/graph/discovery.ts`
  (`neverCombinedCandidates()`) is written and tested; the builders give it an authoring surface
  instead of leaving it a read-only panel.

## Relationship to existing changes

- **Supersedes** `evolve-web-mirror-to-crud-platform` (owner ruling 2026-07-08). Its
  shared-truth/identity layers are owned by `migrate-canonical-backend-to-appwrite`
  (`metadata-sync-backend`, `unified-identity`); its unshipped write-scope work migrated here as
  Phases 4–6 with the `web-library-crud` and `media-governance` spec deltas. The owner chose
  **full bidirectional first**: composition writes go through canonical truth so the phone sees
  web-built combos immediately. This change does **not** introduce a parallel write path or an
  overlay store.
- **Depends on** `migrate-canonical-backend-to-appwrite` — the canonical backend (truth) and
  write-through/sync-status primitives this studio consumes (Appwrite Phase 6 targets this change).
- **Completes** `add-discovery-graph-interface`'s `combination-discovery`: that capability defines a
  candidate's "promote into a real combo through the existing, guarded flow." This change *is* that
  guarded flow on the web (the `/combo-builder` seeded with the candidate's moves).
- **Consumes** the lifecycle/provenance direction already in the repo
  (`add-provenance-ledger-and-beam-ingestion-contract`,
  `add-protobuf-event-envelope-and-upload-spool`): the move-lifecycle record is the web-facing
  *view* of that event history, not a competing ledger.
- **Reuses** the existing read path (`drive.ts`, `VideoModal`, `StatsPanel`, demo fixtures) as the
  Phase 0 display surface.

## Data safety (non-negotiable — production app with deployed data)

- **Read surface ships first, writes ship later.** Phase 0 is display-only; no write capability is
  enabled until the trust layer (verified write-through + lifecycle record) is in place.
- **Delete means archive, never erase.** "Delete" anywhere is a soft-archive/tombstone. The entity,
  its media reference, and its lifecycle remain readable in `/web`. No phase removes rows or blobs.
- **Verified write-through.** A composition write is only reported "saved" after the canonical truth
  acknowledges it; otherwise it shows pending/failed and is retryable without losing edits.
- **Video attach is reference-only.** Attaching a video to a combo references its content hash;
  it never mutates or re-encodes the blob. Media swap/replace remains `media-governance`'s
  copy-then-verify.
- **Single account, single truth.** All data and media stay in `senik456@gmail.com`'s Drive /
  canonical backend (see `[[project_web_mirror_crud_platform]]`).

## Scope

### In scope
- **Phase 0 — complete read surface:** `/web` renders *all* videos and *all* library entities
  (moves, combos with their ordered move sequences, sets/decks, notes, plans), including archived
  ones, from the canonical read path.
- **`move-lifecycle-archive`:** per-entity lifecycle timeline; deletion-resilient archive (deleted
  entities remain viewable, clearly marked, with recovery/un-archive).
- **`combo-set-composition`:** verified write contract for creating/editing **ordered** combos
  (reorder/insert/remove with sequence integrity), creating/editing **sets** (decks), and
  **attaching video** to combos — all write-through to canonical truth, single-writer optimistic.
- **`web-authoring-studio`:** the `/combo-builder` and `/set-builder` tools, **seeded by
  `neverCombinedCandidates()`** suggestions and lightweight composition analysis; serves as the
  guarded promotion target for `combination-discovery`.
- **`developer-docs` (added 2026-07-08):** an MDX docs surface inside `web-mirror/` (Next.js
  native MDX) documenting the load-bearing seams — `SyncBackend`, `Machine<S,E>`, design
  tokens, sync/LWW model — plus operational runbooks (release, provisioning, diagnostics
  export triage). The studio is the dev utility; its docs live with it and build in CI.
  - **Content ↔ hosting split (`add-engineering-manual-and-docs-ledger`, 2026-07-10):** the
    manual *content* now lives at repo-root `docs/manual/` (grep-first, agent-facing), authored
    and owned by that change. This capability keeps **rendering/hosting only** — the studio
    mounts `docs/manual/` and the broken-MDX-fails-`next build` gate still applies; it no longer
    owns the words. See that change's `specs/developer-docs/spec.md` (D1).

### Out of scope
- Standing up the canonical backend itself — owned by `migrate-canonical-backend-to-appwrite`
  (`metadata-sync-backend`); this change consumes it.
- Real-time collaborative / CRDT multi-writer editing (single-writer-at-a-time assumed).
- The provenance *ledger engine* (mobile/backend ingestion) — owned by the provenance changes; here
  we render its history as a web view.

## Impact
- **New web capabilities:** `move-lifecycle-archive`, `combo-set-composition`, `web-authoring-studio`,
  plus `web-library-crud` and `media-governance` (migrated in from the superseded CRUD change).
- **Depends on:** `migrate-canonical-backend-to-appwrite` (canonical truth + write-through must land first).
- **Reuses:** the entire read-only mirror as the Phase 0 read surface + offline cache.

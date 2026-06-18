# Design — Web Authoring Studio & Lifecycle Record

## Context

The web mirror reads a manifest from Drive and renders moves/combos read-only
(`web-mirror/src/lib/types.ts` is explicitly "read-only: never write"). The data model already
expresses everything the owner wants to author:

- `Combo` + `ComboMove { comboId, moveId, sequenceIndex }` — a combo **is** an ordered sequence.
- `Deck` + `DeckMove` — a "set" is a deck.
- `Note { comboId, kind, body, videoContentHash }` — journals already reference video.
- `Asset { contentHash, … }` — videos are content-addressed.
- `discovery.ts → neverCombinedCandidates()` — the combinatorial suggestion engine, already tested.

The only missing primitive is a **trustworthy write path**. The owner's framing makes "trustworthy"
concrete: writes must verifiably land in the canonical truth, and nothing may ever be erased.

## Goals

- Display the **complete** library (all videos + all entities, including archived) before any write.
- Make every write **verifiable** (reported saved only on canonical acknowledgement).
- Record and surface each entity's **full lifecycle**; keep **deleted entities accessible**.
- Provide **ordered combo** + **set** authoring, **video attach**, **combinatorics-seeded**.

## Non-goals

- Building the canonical backend (consumed from `shared-source-of-truth`).
- A second/overlay write store, or multi-writer CRDT merge.
- The provenance ingestion engine (consumed as a read view).

## Key decisions

### D1 — Full bidirectional first; no overlay (owner-chosen)
The owner chose one clean architecture: composition writes go **through the canonical truth** so the
phone sees web-built combos immediately. We therefore **gate this change on `shared-source-of-truth`
landing first** rather than shipping an interim web-owned overlay. Trade-off accepted: the builders
wait on the backend, in exchange for "updating everywhere" from day one and a single write path.

### D2 — Deletion is a tombstone, and the web is where tombstones live
"Delete" is modeled as a soft-archive with a `deletedAt`/archived marker (the model already carries
`Asset.deletedAt`; entities get the same treatment). The canonical truth never hard-deletes owner
content. The `/web` view explicitly renders archived/deleted entities in a distinct, recoverable
state. This is what makes the web "the durable record the phone can't be" — phone-side deletion
removes it from the phone cache but not from truth, and the web keeps showing it.

### D3 — Lifecycle is a projection of the event history, not a new ledger
The repo already commits to an event envelope + provenance ledger. The web `move-lifecycle-archive`
renders that history as a per-entity timeline (created/edited/combined/reviewed/archived). If the
ledger is not yet populated for an entity, the timeline degrades gracefully to what the manifest can
reconstruct (createdAt, current combos/decks, reviews) — additive, never blocking.

### D4 — Ordered-composition integrity belongs in the write contract
`sequenceIndex` must stay contiguous and gap-free. The composition write contract owns
reorder/insert/remove semantics and re-indexing, so the builder UI stays thin and any client gets
the same guarantees. Invalid compositions (no moves, duplicate index) are rejected before write.

### D5 — Video attach is a reference, not a media operation
Attaching a video to a combo writes a content-hash reference only. It never uploads, re-encodes, or
deletes a blob. Producing/replacing the underlying media stays with `media-governance`
(copy-then-verify). This keeps authoring cheap and safe.

### D6 — The builder is `combination-discovery`'s promotion target
`combination-discovery` requires promoting a candidate "through the existing, guarded combo-creation
flow." This change provides exactly that flow on the web: promoting a candidate opens
`/combo-builder` seeded with the candidate's moves. No separate or unguarded write path is created.

## Sequencing (risk-ordered)

1. **Phase 0 — read surface (no write risk):** render all videos + all entities incl. archived.
2. **Phase 1 — lifecycle/archive view (read of truth+history):** timelines, tombstone rendering,
   recovery affordance. Still read-only writes-wise except un-archive.
3. **Phase 2 — composition writes (gated on `shared-source-of-truth`):** verified write-through for
   ordered combos, sets, video attach; optimistic UI + sync status.
4. **Phase 3 — studio tools:** `/combo-builder` + `/set-builder` over the Phase 2 write contract,
   seeded by `neverCombinedCandidates()` and lightweight analysis.

## Open questions
- Does un-archive (recovery) count as a write that must wait for Phase 2's verified path, or can it
  ship in Phase 1 as the single allowed "write" because it only flips an archived flag? (Leaning:
  treat it as a Phase 2 write for one consistent verified path.)

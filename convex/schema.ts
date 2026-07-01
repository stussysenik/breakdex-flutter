import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

// Envelope for descriptive, last-writer-wins records. The domain fields (move
// name, combo structure, deck membership, …) live inside `json` so this schema
// stays provider-neutral and maps 1:1 onto the Dart `SyncRecord` contract in
// `lib/core/sync/sync_backend.dart`. Video bytes never land here — `json` holds
// only a Drive file-id / object-key pointer.
const descriptive = {
  // Drift row id — identity is preserved across the sync boundary.
  localId: v.string(),
  // Opaque, provider-neutral record payload (pointer only, never bytes).
  json: v.any(),
  // ms epoch — drives last-writer-wins reconciliation for descriptive records.
  updatedAt: v.number(),
  // Soft-delete marker. Deletes cross the boundary as tombstones, never hard.
  deletedAt: v.optional(v.number()),
  // Idempotency key of the write that produced this state; replay never doubles.
  clientOpId: v.string(),
};

export default defineSchema({
  // Descriptive tables — one per strangler-fig cutover unit (Decision 4). Each
  // is cut over independently: moves → combos → decks.
  moves: defineTable(descriptive)
    .index("by_localId", ["localId"])
    .index("by_updatedAt", ["updatedAt"]),
  combos: defineTable(descriptive)
    .index("by_localId", ["localId"])
    .index("by_updatedAt", ["updatedAt"]),
  comboMoves: defineTable(descriptive)
    .index("by_localId", ["localId"])
    .index("by_updatedAt", ["updatedAt"]),
  decks: defineTable(descriptive)
    .index("by_localId", ["localId"])
    .index("by_updatedAt", ["updatedAt"]),
  deckMoves: defineTable(descriptive)
    .index("by_localId", ["localId"])
    .index("by_updatedAt", ["updatedAt"]),

  // Append-only review log (Decision 7). Never mutated. FSRS scheduling state is
  // *derived* from this, so a stale concurrent write can never regress a card's
  // schedule the way a last-writer-wins overwrite would.
  reviewEvents: defineTable({
    localId: v.string(),
    entityId: v.string(),
    entityType: v.string(), // 'move' | 'combo'
    rating: v.number(), // ReviewRating index: 0=again 1=hard 2=good 3=easy
    reviewedAt: v.number(),
    clientOpId: v.string(),
  })
    .index("by_entity", ["entityType", "entityId", "reviewedAt"])
    .index("by_clientOpId", ["clientOpId"])
    .index("by_reviewedAt", ["reviewedAt"]),

  // Derived FSRS scheduling state. WRITTEN ONLY by the server-side reduce over
  // `reviewEvents` (task 2.4) — never client-pushed (Decision 7). Defined now so
  // clients can pull/subscribe it the moment the reducer lands; empty until then.
  fsrsCards: defineTable({
    entityId: v.string(),
    entityType: v.string(),
    stability: v.optional(v.number()),
    difficulty: v.optional(v.number()),
    due: v.number(),
    // fsrs State: 1=learning 2=review 3=relearning (0=new, our DB convention).
    state: v.number(),
    // Watermark: clientOpId of the last review event folded into this state.
    lastEventOpId: v.optional(v.string()),
    updatedAt: v.number(),
  })
    .index("by_entity", ["entityType", "entityId"])
    .index("by_updatedAt", ["updatedAt"]),
});

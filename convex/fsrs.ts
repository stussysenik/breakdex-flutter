import { query } from "./_generated/server";
import { v } from "convex/values";

// DERIVED FSRS scheduling state (Decision 7).
//
// `reviewEvents` is the source of truth; a card's stability/difficulty/due is a
// *reduction* of that event log, never client-pushed. Porting the `fsrs`
// scheduler math into the server-side reduce is task 2.4 — this module ships
// the two read halves that reduce will use and feed: the ordered per-entity
// event stream, and the derived-card pull. `fsrsCards` stays empty until the
// reducer lands, and `pullCards` correctly returns nothing until then.

/**
 * All review events for one entity, ordered oldest→newest (the `by_entity`
 * composite index orders by `reviewedAt`). This is the exact input the FSRS
 * reduce folds over to (re)compute a card.
 */
export const listEventsForEntity = query({
  args: { entityType: v.string(), entityId: v.string() },
  handler: async (ctx, { entityType, entityId }) => {
    return await ctx.db
      .query("reviewEvents")
      .withIndex("by_entity", (q) =>
        q.eq("entityType", entityType).eq("entityId", entityId),
      )
      .collect();
  },
});

/**
 * Pull derived cards changed since `since`. Same `SyncDelta` shape as the other
 * pulls; the Dart side treats these as read-only (it never pushes fsrsCards).
 */
export const pullCards = query({
  args: { since: v.optional(v.number()) },
  handler: async (ctx, { since }) => {
    const rows = await ctx.db
      .query("fsrsCards")
      .withIndex("by_updatedAt", (q) =>
        since === undefined ? q : q.gt("updatedAt", since),
      )
      .collect();
    return {
      upserts: rows.map((r) => ({
        id: `${r.entityType}:${r.entityId}`,
        json: r,
        updatedAt: r.updatedAt,
        clientOpId: `derived:${r.lastEventOpId ?? ""}`,
      })),
      deletes: [],
      cursor:
        rows.length > 0
          ? rows.reduce((max, r) => Math.max(max, r.updatedAt), since ?? 0)
          : (since ?? null),
    };
  },
});

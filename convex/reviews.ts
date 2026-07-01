import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

const reviewEventArg = v.object({
  localId: v.string(),
  entityId: v.string(),
  entityType: v.string(),
  rating: v.number(),
  reviewedAt: v.number(),
  clientOpId: v.string(),
});

/**
 * Append review events (Decision 7). The log is immutable — events are only
 * ever inserted, never updated or deleted. Idempotent via `clientOpId`: a
 * replayed batch skips any event already recorded, so a retry after a flaky
 * network can never double-count a rating (which would corrupt the derived
 * FSRS schedule).
 */
export const appendReviewEvents = mutation({
  args: { events: v.array(reviewEventArg) },
  handler: async (ctx, { events }) => {
    for (const e of events) {
      const dup = await ctx.db
        .query("reviewEvents")
        .withIndex("by_clientOpId", (q) => q.eq("clientOpId", e.clientOpId))
        .first();
      if (dup !== null) continue;
      await ctx.db.insert("reviewEvents", e);
    }
  },
});

/**
 * Pull review events changed since `since` (undefined = full pull). Events are
 * surfaced through the same `SyncDelta` shape as descriptive records so the
 * Dart side reconciles them uniformly; there are no deletes in an append-only
 * log.
 */
export const pullReviewEvents = query({
  args: { since: v.optional(v.number()) },
  handler: async (ctx, { since }) => {
    const rows = await ctx.db
      .query("reviewEvents")
      .withIndex("by_reviewedAt", (q) =>
        since === undefined ? q : q.gt("reviewedAt", since),
      )
      .collect();
    return {
      upserts: rows.map((r) => ({
        id: r.localId,
        json: {
          entityId: r.entityId,
          entityType: r.entityType,
          rating: r.rating,
          reviewedAt: r.reviewedAt,
        },
        updatedAt: r.reviewedAt,
        clientOpId: r.clientOpId,
      })),
      deletes: [],
      cursor:
        rows.length > 0
          ? rows.reduce((max, r) => Math.max(max, r.reviewedAt), since ?? 0)
          : (since ?? null),
    };
  },
});

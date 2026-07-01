import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

// The descriptive (last-writer-wins) tables this module serves. `reviewEvents`
// and `fsrsCards` are handled by `reviews.ts` / `fsrs.ts` because their
// semantics differ (append-only, and derived, respectively).
const descriptiveTable = v.union(
  v.literal("moves"),
  v.literal("combos"),
  v.literal("comboMoves"),
  v.literal("decks"),
  v.literal("deckMoves"),
);

const recordArg = v.object({
  localId: v.string(),
  json: v.any(),
  updatedAt: v.number(),
  clientOpId: v.string(),
});

const tombstoneArg = v.object({
  localId: v.string(),
  deletedAt: v.number(),
  clientOpId: v.string(),
});

/**
 * Push client-authored upserts and tombstones for one descriptive table.
 *
 * Reconciliation is last-writer-wins on monotonic `updatedAt`; an incoming
 * write only applies if it is at least as new as the stored row (equal
 * timestamps ⇒ an idempotent replay, which is a no-op). Deletes are soft: a
 * tombstone sets `deletedAt`, never removing the row, so state stays
 * recoverable and reconcilable across clients.
 */
export const pushRecords = mutation({
  args: {
    table: descriptiveTable,
    upserts: v.array(recordArg),
    deletes: v.array(tombstoneArg),
  },
  handler: async (ctx, { table, upserts, deletes }) => {
    for (const rec of upserts) {
      const existing = await ctx.db
        .query(table)
        .withIndex("by_localId", (q) => q.eq("localId", rec.localId))
        .unique();
      if (existing === null) {
        await ctx.db.insert(table, {
          localId: rec.localId,
          json: rec.json,
          updatedAt: rec.updatedAt,
          clientOpId: rec.clientOpId,
        });
      } else if (rec.updatedAt >= existing.updatedAt) {
        await ctx.db.patch(existing._id, {
          json: rec.json,
          updatedAt: rec.updatedAt,
          clientOpId: rec.clientOpId,
          deletedAt: undefined, // a fresh upsert un-tombstones the row
        });
      }
    }
    for (const tomb of deletes) {
      const existing = await ctx.db
        .query(table)
        .withIndex("by_localId", (q) => q.eq("localId", tomb.localId))
        .unique();
      if (existing === null) {
        await ctx.db.insert(table, {
          localId: tomb.localId,
          json: {},
          updatedAt: tomb.deletedAt,
          deletedAt: tomb.deletedAt,
          clientOpId: tomb.clientOpId,
        });
      } else if (tomb.deletedAt >= existing.updatedAt) {
        await ctx.db.patch(existing._id, {
          deletedAt: tomb.deletedAt,
          updatedAt: tomb.deletedAt,
          clientOpId: tomb.clientOpId,
        });
      }
    }
  },
});

/**
 * Pull everything for one descriptive table that changed since `since`
 * (undefined = full pull). Being a Convex query, this is reactive by
 * construction — the Dart `SyncBackend.subscribe` rides the same function, so
 * there is no separate push channel to keep in sync.
 */
export const pullRecords = query({
  args: {
    table: descriptiveTable,
    since: v.optional(v.number()),
  },
  handler: async (ctx, { table, since }) => {
    const rows = await ctx.db
      .query(table)
      .withIndex("by_updatedAt", (q) =>
        since === undefined ? q : q.gt("updatedAt", since),
      )
      .collect();
    const highWater = rows.reduce(
      (max, r) => Math.max(max, r.updatedAt),
      since ?? 0,
    );
    return {
      upserts: rows
        .filter((r) => r.deletedAt === undefined)
        .map((r) => ({
          id: r.localId,
          json: r.json,
          updatedAt: r.updatedAt,
          clientOpId: r.clientOpId,
        })),
      deletes: rows
        .filter((r) => r.deletedAt !== undefined)
        .map((r) => ({
          id: r.localId,
          deletedAt: r.deletedAt as number,
          clientOpId: r.clientOpId,
        })),
      cursor: rows.length > 0 ? highWater : (since ?? null),
    };
  },
});

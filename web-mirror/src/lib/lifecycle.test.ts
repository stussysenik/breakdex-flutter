import { describe, expect, it } from "vitest";
import type { LibraryManifest } from "./types";
import { projectLifecycle, type LifecycleEvent } from "./lifecycle";

/** A manifest with one archived move, one active move, a combo, and reviews. */
function manifest(): LibraryManifest {
  return {
    version: 2,
    exportedAt: "2026-06-18T00:00:00.000Z",
    moves: [
      { id: "m1", name: "Six Step", category: "Footwork", contentHash: "h1", createdAt: "2026-01-01T00:00:00.000Z" },
      { id: "m2", name: "Baby Freeze", category: "Freeze", contentHash: "h2", createdAt: "2026-01-05T00:00:00.000Z", deletedAt: "2026-03-01T00:00:00.000Z" },
    ],
    combos: [{ id: "c1", name: "Opener" }],
    comboMoves: [
      { comboId: "c1", moveId: "m1", sequenceIndex: 0 },
      { comboId: "c1", moveId: "m2", sequenceIndex: 1 },
    ],
    categories: [],
    fsrsCards: [],
    decks: [],
    deckMoves: [],
    reviews: [
      { id: "r1", entityId: "m1", entityType: "move", rating: "good", createdAt: "2026-02-10T00:00:00.000Z" },
      { id: "r2", entityId: "c1", entityType: "combo", rating: "hard", createdAt: "2026-02-12T00:00:00.000Z" },
    ],
    assets: [],
    notes: [],
    plans: [],
  };
}

describe("projectLifecycle", () => {
  it("does not mutate its input (read-only)", () => {
    const m = manifest();
    const snapshot = structuredClone(m);
    projectLifecycle(m, { entityType: "move", entityId: "m1" });
    projectLifecycle(m, { entityType: "combo", entityId: "c1" });
    expect(m).toEqual(snapshot);
  });

  it("reconstructs a move timeline from the manifest when no history is supplied", () => {
    const t = projectLifecycle(manifest(), { entityType: "move", entityId: "m1" });
    expect(t.reconstructed).toBe(true);
    expect(t.name).toBe("Six Step");
    expect(t.archived).toBe(false);
    const kinds = t.events.map((e) => e.kind);
    expect(kinds).toContain("created");
    expect(kinds).toContain("combined"); // member of c1
    expect(kinds).toContain("reviewed"); // r1
    // Dated events are chronological; the undated membership sorts last.
    expect(t.events[0]).toMatchObject({ kind: "created", at: "2026-01-01T00:00:00.000Z" });
    expect(t.events[t.events.length - 1].kind).toBe("combined");
  });

  it("marks an archived move and appends an archived event, still reconstructed", () => {
    const t = projectLifecycle(manifest(), { entityType: "move", entityId: "m2" });
    expect(t.archived).toBe(true);
    const archived = t.events.find((e) => e.kind === "archived");
    expect(archived).toMatchObject({ at: "2026-03-01T00:00:00.000Z" });
  });

  it("reconstructs a combo timeline, inferring creation from earliest member", () => {
    const t = projectLifecycle(manifest(), { entityType: "combo", entityId: "c1" });
    expect(t.reconstructed).toBe(true);
    const created = t.events.find((e) => e.kind === "created");
    expect(created?.at).toBe("2026-01-01T00:00:00.000Z"); // earliest member createdAt
    expect(t.events.find((e) => e.kind === "combined")?.detail).toBe("2 moves");
    expect(t.events.find((e) => e.kind === "reviewed")?.detail).toBe("Hard");
  });

  it("uses supplied event history verbatim instead of reconstructing", () => {
    const history: LifecycleEvent[] = [
      { kind: "created", at: "2026-01-01T00:00:00.000Z", label: "Created" },
      { kind: "edited", at: "2026-01-15T00:00:00.000Z", label: "Renamed" },
      { kind: "archived", at: "2026-02-01T00:00:00.000Z", label: "Archived" },
    ];
    const t = projectLifecycle(manifest(), { entityType: "move", entityId: "m1" }, { events: history });
    expect(t.reconstructed).toBe(false);
    expect(t.events.map((e) => e.kind)).toEqual(["created", "edited", "archived"]);
  });

  it("is deterministic — same input yields an equivalent timeline", () => {
    const a = projectLifecycle(manifest(), { entityType: "combo", entityId: "c1" });
    const b = projectLifecycle(manifest(), { entityType: "combo", entityId: "c1" });
    expect(a).toEqual(b);
  });
});

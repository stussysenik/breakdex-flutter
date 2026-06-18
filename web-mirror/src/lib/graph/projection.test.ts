import { describe, expect, it } from "vitest";
import type { LibraryManifest } from "../types";
import type { AuraLink } from "./model";
import { projectGraph } from "./projection";

/** A full manifest exercising every node and edge kind. */
function fullManifest(): LibraryManifest {
  return {
    version: 2,
    exportedAt: "2026-06-16T00:00:00.000Z",
    moves: [
      { id: "m1", name: "Six Step", category: "Footwork", contentHash: "h1", createdAt: "2026-01-01T00:00:00.000Z" },
      { id: "m2", name: "Baby Freeze", category: "Freeze", contentHash: null, createdAt: "2026-01-02T00:00:00.000Z" },
      { id: "m3", name: "Windmill", category: "Power", contentHash: "h3", createdAt: "2026-01-03T00:00:00.000Z" },
    ],
    combos: [{ id: "c1", name: "Opener" }],
    comboMoves: [
      { comboId: "c1", moveId: "m1", sequenceIndex: 0 },
      { comboId: "c1", moveId: "m2", sequenceIndex: 1 },
    ],
    categories: [],
    fsrsCards: [],
    decks: [{ id: "d1", name: "Warmup", deckType: "manual" }],
    deckMoves: [{ deckId: "d1", moveId: "m1" }],
    reviews: [],
    assets: [],
    notes: [
      { id: "n1", comboId: "c1", kind: "insight", body: "lead with the left", videoContentHash: null, createdAt: "2026-02-01T00:00:00.000Z" },
    ],
    plans: [
      { id: "p1", comboId: "c1", planDate: "2026-03-01", position: 0, completedAt: null },
    ],
  };
}

const auraLinks: AuraLink[] = [{ fromMoveId: "m2", toMoveId: "m3", weight: 0.8 }];

describe("projectGraph", () => {
  it("does not mutate its input (read-only)", () => {
    const manifest = fullManifest();
    const snapshot = structuredClone(manifest);
    projectGraph(manifest, { auraLinks });
    expect(manifest).toEqual(snapshot);
  });

  it("is deterministic — same input yields an equivalent model", () => {
    const a = projectGraph(fullManifest(), { auraLinks });
    const b = projectGraph(fullManifest(), { auraLinks });
    expect(a).toEqual(b);
  });

  it("covers all node kinds with id, entityId, and label", () => {
    const { nodes } = projectGraph(fullManifest(), { auraLinks });
    const kinds = new Set(nodes.map((n) => n.kind));
    expect(kinds).toEqual(new Set(["move", "combo", "deck", "note", "plan"]));

    const move = nodes.find((n) => n.kind === "move" && n.entityId === "m1");
    expect(move).toMatchObject({ id: "move:m1", entityId: "m1", label: "Six Step" });

    const combo = nodes.find((n) => n.kind === "combo");
    expect(combo).toMatchObject({ id: "combo:c1", entityId: "c1", label: "Opener" });
  });

  it("covers all edge kinds derived from existing relationships", () => {
    const { edges } = projectGraph(fullManifest(), { auraLinks });
    const kinds = new Set(edges.map((e) => e.kind));
    expect(kinds).toEqual(
      new Set(["combo-sequence", "deck-membership", "annotation", "aura-affinity"]),
    );

    // combo-sequence connects the combo to its members, carrying order.
    const seq = edges.filter((e) => e.kind === "combo-sequence");
    expect(seq).toEqual([
      { id: "combo-sequence:c1:m1:0", kind: "combo-sequence", source: "combo:c1", target: "move:m1", order: 0 },
      { id: "combo-sequence:c1:m2:1", kind: "combo-sequence", source: "combo:c1", target: "move:m2", order: 1 },
    ]);

    const aura = edges.find((e) => e.kind === "aura-affinity");
    expect(aura).toMatchObject({ source: "move:m2", target: "move:m3", weight: 0.8 });
  });

  it("degrades gracefully when aura, notes, and plans are absent", () => {
    const manifest = fullManifest();
    delete manifest.notes;
    delete manifest.plans;
    const { nodes, edges } = projectGraph(manifest); // no auraLinks

    const edgeKinds = new Set(edges.map((e) => e.kind));
    expect(edgeKinds.has("aura-affinity")).toBe(false);
    expect(edgeKinds.has("annotation")).toBe(false);
    // Remaining structure is intact.
    expect(edgeKinds).toEqual(new Set(["combo-sequence", "deck-membership"]));
    expect(nodes.some((n) => n.kind === "note" || n.kind === "plan")).toBe(false);
    expect(nodes.filter((n) => n.kind === "move")).toHaveLength(3);
  });

  it("drops edges referencing entities that do not exist", () => {
    const manifest = fullManifest();
    manifest.comboMoves.push({ comboId: "c1", moveId: "ghost", sequenceIndex: 9 });
    const { edges } = projectGraph(manifest);
    expect(edges.some((e) => e.target === "move:ghost")).toBe(false);
  });
});

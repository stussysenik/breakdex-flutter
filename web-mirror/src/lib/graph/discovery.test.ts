import { describe, expect, it } from "vitest";
import type { LibraryManifest } from "../types";
import type { AuraLink } from "./model";
import { neverCombinedCandidates, orphanNodes } from "./discovery";
import { projectGraph } from "./projection";

function baseManifest(): LibraryManifest {
  return {
    version: 2,
    exportedAt: "2026-06-16T00:00:00.000Z",
    moves: [
      { id: "m1", name: "Six Step", category: "Footwork", contentHash: null, createdAt: "2026-01-01T00:00:00.000Z" },
      { id: "m2", name: "Baby Freeze", category: "Freeze", contentHash: null, createdAt: "2026-01-02T00:00:00.000Z" },
      { id: "m3", name: "Windmill", category: "Power", contentHash: null, createdAt: "2026-01-03T00:00:00.000Z" },
      { id: "m4", name: "Orphan Move", category: "Misc", contentHash: null, createdAt: "2026-01-04T00:00:00.000Z" },
    ],
    combos: [{ id: "c1", name: "Opener" }],
    // m1 then m2 are sequenced together (adjacent).
    comboMoves: [
      { comboId: "c1", moveId: "m1", sequenceIndex: 0 },
      { comboId: "c1", moveId: "m2", sequenceIndex: 1 },
    ],
    categories: [],
    fsrsCards: [],
    decks: [],
    deckMoves: [],
    reviews: [],
    assets: [],
    notes: [],
    plans: [],
  };
}

describe("neverCombinedCandidates — aura path", () => {
  it("includes an affinity pair that was never sequenced", () => {
    // m2→m3 has affinity but is never in a combo together.
    const aura: AuraLink[] = [{ fromMoveId: "m2", toMoveId: "m3", weight: 0.9 }];
    const graph = projectGraph(baseManifest(), { auraLinks: aura });
    const candidates = neverCombinedCandidates(graph);
    expect(candidates).toEqual([
      { pair: { a: "m2", b: "m3" }, source: "aura", weight: 0.9 },
    ]);
  });

  it("excludes an affinity pair that is already sequenced", () => {
    // m1→m2 has affinity but IS already adjacent in combo c1 → excluded.
    const aura: AuraLink[] = [{ fromMoveId: "m1", toMoveId: "m2", weight: 0.5 }];
    const graph = projectGraph(baseManifest(), { auraLinks: aura });
    expect(neverCombinedCandidates(graph)).toEqual([]);
  });
});

describe("neverCombinedCandidates — co-occurrence fallback", () => {
  it("derives candidates from shared deck when no aura data exists", () => {
    const manifest = baseManifest();
    // m3 and m4 share a deck but were never sequenced.
    manifest.decks = [{ id: "d1", name: "Power", deckType: "manual" }];
    manifest.deckMoves = [
      { deckId: "d1", moveId: "m3" },
      { deckId: "d1", moveId: "m4" },
    ];
    const graph = projectGraph(manifest); // no aura
    const candidates = neverCombinedCandidates(graph);
    expect(candidates).toEqual([
      { pair: { a: "m3", b: "m4" }, source: "co-occurrence" },
    ]);
  });

  it("excludes already-adjacent pairs in the fallback path", () => {
    const manifest = baseManifest();
    // Put the already-sequenced m1,m2 into a shared deck too.
    manifest.decks = [{ id: "d1", name: "All", deckType: "manual" }];
    manifest.deckMoves = [
      { deckId: "d1", moveId: "m1" },
      { deckId: "d1", moveId: "m2" },
    ];
    const graph = projectGraph(manifest);
    // m1,m2 co-occur but are adjacent → excluded → no candidates.
    expect(neverCombinedCandidates(graph)).toEqual([]);
  });
});

describe("orphanNodes", () => {
  it("returns nodes with no incident edges", () => {
    const graph = projectGraph(baseManifest());
    const orphans = orphanNodes(graph).map((n) => n.entityId);
    // m4 is in no combo/deck; m3 likewise. m1,m2 are in combo c1.
    expect(orphans).toContain("m4");
    expect(orphans).toContain("m3");
    expect(orphans).not.toContain("m1");
    expect(orphans).not.toContain("m2");
  });
});

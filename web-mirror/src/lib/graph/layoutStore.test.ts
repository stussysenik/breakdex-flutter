import { describe, expect, it } from "vitest";
import type { Graph } from "./model";
import {
  type CanvasLayout,
  type StorageLike,
  deleteLayout,
  loadLayouts,
  partitionLayout,
  pruneGhosts,
  saveLayout,
} from "./layoutStore";

function memStorage(): StorageLike & { dump: Record<string, string> } {
  const dump: Record<string, string> = {};
  return {
    dump,
    getItem: (k) => (k in dump ? dump[k] : null),
    setItem: (k, v) => {
      dump[k] = v;
    },
  };
}

function layout(id: string, positions: Record<string, { x: number; y: number }>): CanvasLayout {
  return { id, name: `Layout ${id}`, positions, updatedAt: "2026-06-16T00:00:00.000Z" };
}

const graph: Graph = {
  nodes: [
    { id: "move:m1", kind: "move", entityId: "m1", label: "A" },
    { id: "move:m2", kind: "move", entityId: "m2", label: "B" },
  ],
  edges: [],
};

describe("layout persistence", () => {
  it("round-trips a saved layout (save → reopen)", () => {
    const s = memStorage();
    const l = layout("L1", { "move:m1": { x: 10, y: 20 } });
    saveLayout(l, s);
    expect(loadLayouts(s)).toEqual([l]);
  });

  it("upserts by id rather than duplicating", () => {
    const s = memStorage();
    saveLayout(layout("L1", { "move:m1": { x: 1, y: 1 } }), s);
    saveLayout(layout("L1", { "move:m1": { x: 9, y: 9 } }), s);
    const all = loadLayouts(s);
    expect(all).toHaveLength(1);
    expect(all[0].positions["move:m1"]).toEqual({ x: 9, y: 9 });
  });

  it("deleting a layout leaves other layouts intact", () => {
    const s = memStorage();
    saveLayout(layout("L1", {}), s);
    saveLayout(layout("L2", {}), s);
    const remaining = deleteLayout("L1", s);
    expect(remaining.map((l) => l.id)).toEqual(["L2"]);
  });

  it("tolerates corrupt storage without throwing", () => {
    const s = memStorage();
    s.dump["breakdex.canvasLayouts.v1"] = "{not json";
    expect(loadLayouts(s)).toEqual([]);
  });
});

describe("ghost handling", () => {
  it("flags positions whose entity no longer exists", () => {
    const l = layout("L1", {
      "move:m1": { x: 0, y: 0 },
      "move:gone": { x: 5, y: 5 },
    });
    const { live, ghosts } = partitionLayout(l, graph);
    expect(Object.keys(live)).toEqual(["move:m1"]);
    expect(ghosts).toEqual(["move:gone"]);
  });

  it("pruning removes only ghosts, never live entries", () => {
    const l = layout("L1", {
      "move:m1": { x: 0, y: 0 },
      "move:gone": { x: 5, y: 5 },
    });
    const pruned = pruneGhosts(l, graph);
    expect(pruned.positions).toEqual({ "move:m1": { x: 0, y: 0 } });
    expect(pruned.id).toBe("L1");
  });
});

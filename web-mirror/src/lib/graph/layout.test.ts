import { describe, expect, it } from "vitest";
import type { Graph } from "./model";
import { computeLayout } from "./layout";

function ring(n: number): Graph {
  const nodes = Array.from({ length: n }, (_, i) => ({
    id: `move:m${i}`,
    kind: "move" as const,
    entityId: `m${i}`,
    label: `m${i}`,
  }));
  const edges = Array.from({ length: n }, (_, i) => ({
    id: `e${i}`,
    kind: "combo-sequence" as const,
    source: `move:m${i}`,
    target: `move:m${(i + 1) % n}`,
  }));
  return { nodes, edges };
}

describe("computeLayout", () => {
  it("returns a position for every node", () => {
    const g = ring(8);
    const pos = computeLayout(g);
    expect(pos.size).toBe(8);
    for (const node of g.nodes) {
      const p = pos.get(node.id)!;
      expect(Number.isFinite(p.x)).toBe(true);
      expect(Number.isFinite(p.y)).toBe(true);
    }
  });

  it("is deterministic — same graph yields identical positions", () => {
    const a = computeLayout(ring(10));
    const b = computeLayout(ring(10));
    expect([...a.entries()]).toEqual([...b.entries()]);
  });

  it("handles empty and single-node graphs without crashing", () => {
    expect(computeLayout({ nodes: [], edges: [] }).size).toBe(0);
    const one = computeLayout({
      nodes: [{ id: "move:m0", kind: "move", entityId: "m0", label: "m0" }],
      edges: [],
    });
    expect(one.size).toBe(1);
  });

  it("separates nodes (no two land on the same point)", () => {
    const pos = computeLayout(ring(12));
    const keys = new Set([...pos.values()].map((p) => `${Math.round(p.x)},${Math.round(p.y)}`));
    expect(keys.size).toBe(12);
  });
});

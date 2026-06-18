// Minimal in-house force-directed layout. No external dependency: for a
// single-user library (dozens–low-hundreds of nodes) an O(n²) simulation with a
// hard iteration cap settles in milliseconds. Deterministic — initial positions
// are seeded from node index (no randomness), so the same graph always lays out
// the same way, which keeps the view stable and tests reproducible.

import type { Graph } from "./model";

export interface Vec {
  x: number;
  y: number;
}

export interface LayoutOptions {
  /** Hard cap on simulation steps (settle-and-freeze). */
  iterations?: number;
  /** Repulsion strength between every pair of nodes. */
  repulsion?: number;
  /** Spring stiffness along edges. */
  attraction?: number;
  /** Natural spring rest length along edges. */
  linkDistance?: number;
  /** Pull toward the origin, keeping disconnected clusters on screen. */
  centering?: number;
}

const DEFAULTS: Required<LayoutOptions> = {
  iterations: 320,
  repulsion: 6000,
  attraction: 0.02,
  linkDistance: 90,
  centering: 0.015,
};

/**
 * Compute frozen 2D positions for every node, centered roughly on the origin.
 * Returns a map keyed by node id. Pure and deterministic for a given graph.
 */
export function computeLayout(graph: Graph, options: LayoutOptions = {}): Map<string, Vec> {
  const opts = { ...DEFAULTS, ...options };
  const n = graph.nodes.length;
  const pos = new Map<string, Vec>();
  if (n === 0) return pos;

  // Deterministic seed: spread nodes on a circle by index.
  const radius = Math.max(120, n * 12);
  graph.nodes.forEach((node, i) => {
    const angle = (i / n) * Math.PI * 2;
    pos.set(node.id, { x: Math.cos(angle) * radius, y: Math.sin(angle) * radius });
  });

  if (n === 1) return pos;

  const ids = graph.nodes.map((node) => node.id);
  const edges = graph.edges.filter((e) => pos.has(e.source) && pos.has(e.target));

  for (let step = 0; step < opts.iterations; step++) {
    const cooling = 1 - step / opts.iterations; // anneal toward freeze
    const disp = new Map<string, Vec>();
    for (const id of ids) disp.set(id, { x: 0, y: 0 });

    // Repulsion: every pair pushes apart (Coulomb-like).
    for (let i = 0; i < n; i++) {
      const a = pos.get(ids[i])!;
      for (let j = i + 1; j < n; j++) {
        const b = pos.get(ids[j])!;
        let dx = a.x - b.x;
        let dy = a.y - b.y;
        let distSq = dx * dx + dy * dy;
        if (distSq < 0.01) {
          // Coincident: nudge deterministically by index so they separate.
          dx = (i - j) * 0.1 + 0.1;
          dy = (i + j) * 0.1 + 0.1;
          distSq = dx * dx + dy * dy;
        }
        const force = opts.repulsion / distSq;
        const dist = Math.sqrt(distSq);
        const fx = (dx / dist) * force;
        const fy = (dy / dist) * force;
        const da = disp.get(ids[i])!;
        const db = disp.get(ids[j])!;
        da.x += fx;
        da.y += fy;
        db.x -= fx;
        db.y -= fy;
      }
    }

    // Attraction: edges pull endpoints toward the rest length.
    for (const e of edges) {
      const a = pos.get(e.source)!;
      const b = pos.get(e.target)!;
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const dist = Math.sqrt(dx * dx + dy * dy) || 0.01;
      const force = (dist - opts.linkDistance) * opts.attraction;
      const fx = (dx / dist) * force;
      const fy = (dy / dist) * force;
      const da = disp.get(e.source)!;
      const db = disp.get(e.target)!;
      da.x += fx;
      da.y += fy;
      db.x -= fx;
      db.y -= fy;
    }

    // Apply displacement + centering, scaled by the cooling schedule.
    for (const id of ids) {
      const p = pos.get(id)!;
      const d = disp.get(id)!;
      const maxStep = 30 * cooling;
      const dlen = Math.sqrt(d.x * d.x + d.y * d.y) || 1;
      const scale = Math.min(maxStep, dlen) / dlen;
      p.x += d.x * scale - p.x * opts.centering * cooling;
      p.y += d.y * scale - p.y * opts.centering * cooling;
    }
  }

  return pos;
}

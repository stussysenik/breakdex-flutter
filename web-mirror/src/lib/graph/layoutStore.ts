// Persistence for spatial-canvas layouts. ADDITIVE ONLY: a layout records node
// positions by id; it never holds or mutates entity content. Deleting a layout
// removes only the layout record, never the moves/combos it referenced. Stored
// in localStorage today; the record shape (id, name, positions-by-node-id) is
// kept backend-friendly so it can migrate to the CRUD platform's layout store
// later without reshaping.

import type { Graph } from "./model";
import type { Vec } from "./layout";

export interface CanvasLayout {
  id: string;
  name: string;
  /** node id (`move:<id>` / `combo:<id>` / …) → position. References ids only. */
  positions: Record<string, Vec>;
  updatedAt: string;
}

/** Minimal storage contract so the store is testable without a real DOM. */
export interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
}

const KEY = "breakdex.canvasLayouts.v1";

function defaultStorage(): StorageLike | null {
  if (typeof window === "undefined") return null;
  try {
    return window.localStorage;
  } catch {
    return null; // storage disabled (e.g. privacy mode)
  }
}

/** Load all saved layouts. Returns [] when storage is unavailable or empty. */
export function loadLayouts(storage: StorageLike | null = defaultStorage()): CanvasLayout[] {
  if (!storage) return [];
  const raw = storage.getItem(KEY);
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? (parsed as CanvasLayout[]) : [];
  } catch {
    return [];
  }
}

function writeAll(layouts: CanvasLayout[], storage: StorageLike | null): void {
  if (!storage) return;
  storage.setItem(KEY, JSON.stringify(layouts));
}

/** Upsert a layout by id (newest-first ordering). */
export function saveLayout(
  layout: CanvasLayout,
  storage: StorageLike | null = defaultStorage(),
): CanvasLayout[] {
  const others = loadLayouts(storage).filter((l) => l.id !== layout.id);
  const next = [layout, ...others];
  writeAll(next, storage);
  return next;
}

/** Remove a layout record. Entities are untouched — only the layout is deleted. */
export function deleteLayout(
  id: string,
  storage: StorageLike | null = defaultStorage(),
): CanvasLayout[] {
  const next = loadLayouts(storage).filter((l) => l.id !== id);
  writeAll(next, storage);
  return next;
}

export interface PartitionedLayout {
  /** Positions whose node still exists in the current graph. */
  live: Record<string, Vec>;
  /** Node ids saved in the layout but no longer present (ghosts/tombstones). */
  ghosts: string[];
}

/** Split a layout's positions into live entries and ghosts (entity removed). */
export function partitionLayout(layout: CanvasLayout, graph: Graph): PartitionedLayout {
  const present = new Set(graph.nodes.map((n) => n.id));
  const live: Record<string, Vec> = {};
  const ghosts: string[] = [];
  for (const [nodeId, vec] of Object.entries(layout.positions)) {
    if (present.has(nodeId)) live[nodeId] = vec;
    else ghosts.push(nodeId);
  }
  return { live, ghosts };
}

/** Return a copy of the layout with ghost entries removed. Pure. */
export function pruneGhosts(layout: CanvasLayout, graph: Graph): CanvasLayout {
  const { live } = partitionLayout(layout, graph);
  return { ...layout, positions: live };
}

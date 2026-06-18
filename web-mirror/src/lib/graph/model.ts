// Graph model for the discovery interface.
//
// This is a *view* over the existing library, not a new store. A `Graph` is a
// pure projection of the manifest (see `projection.ts`); nothing here writes or
// mutates an entity. Node ids are namespaced by kind (`move:<id>`) so a move and
// a combo that happen to share a raw id can never collide.

export type NodeKind = "move" | "combo" | "note" | "plan" | "deck";

export type EdgeKind =
  | "combo-sequence"
  | "aura-affinity"
  | "deck-membership"
  | "annotation";

export interface GraphNode {
  /** Stable, globally-unique node id: `${kind}:${entityId}`. */
  id: string;
  kind: NodeKind;
  /** The source entity's own id (move.id, combo.id, …). */
  entityId: string;
  /** Human-readable label for rendering. */
  label: string;
}

export interface GraphEdge {
  /** Stable, deterministic edge id derived from kind + endpoints. */
  id: string;
  kind: EdgeKind;
  /** Source node id. */
  source: string;
  /** Target node id. */
  target: string;
  /** Sequence position, present on `combo-sequence` edges. */
  order?: number;
  /** Affinity strength, present on `aura-affinity` edges. */
  weight?: number;
}

export interface Graph {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

/** Namespaced node id for a given kind + entity id. */
export function nodeId(kind: NodeKind, entityId: string): string {
  return `${kind}:${entityId}`;
}

/** Optional move→move transition affinity, sourced from the labs aura model. */
export interface AuraLink {
  fromMoveId: string;
  toMoveId: string;
  weight?: number;
}

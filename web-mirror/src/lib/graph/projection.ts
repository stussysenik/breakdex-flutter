// Pure, read-only projection from the library manifest to a `{nodes, edges}`
// graph model. This function MUST NOT mutate its input or any entity — it only
// reads. The same input always yields an equivalent model (deterministic), and
// missing optional data (aura links, notes, plans) simply omits the
// corresponding edge kinds rather than failing.

import type { LibraryManifest } from "../types";
import {
  type AuraLink,
  type Graph,
  type GraphEdge,
  type GraphNode,
  nodeId,
} from "./model";

export interface ProjectGraphOptions {
  /**
   * Move→move transition affinities from the labs aura model. Absent today
   * (the manifest does not carry them yet); when supplied, they become
   * `aura-affinity` edges. Omitted entirely when undefined/empty.
   */
  auraLinks?: AuraLink[];
}

/**
 * Build the discovery graph from existing library data. Read-only and
 * deterministic: nodes and edges are emitted in a stable order derived from the
 * input arrays, and edge ids are content-derived so repeated runs are equivalent.
 */
export function projectGraph(
  manifest: LibraryManifest,
  options: ProjectGraphOptions = {},
): Graph {
  const nodes: GraphNode[] = [];
  const edges: GraphEdge[] = [];

  // --- Nodes -------------------------------------------------------------
  const moveExists = new Set<string>();
  for (const mv of manifest.moves) {
    moveExists.add(mv.id);
    nodes.push({ id: nodeId("move", mv.id), kind: "move", entityId: mv.id, label: mv.name });
  }

  const comboExists = new Set<string>();
  for (const c of manifest.combos) {
    comboExists.add(c.id);
    nodes.push({ id: nodeId("combo", c.id), kind: "combo", entityId: c.id, label: c.name });
  }

  for (const d of manifest.decks) {
    nodes.push({ id: nodeId("deck", d.id), kind: "deck", entityId: d.id, label: d.name });
  }

  const notes = manifest.notes ?? [];
  for (const n of notes) {
    nodes.push({
      id: nodeId("note", n.id),
      kind: "note",
      entityId: n.id,
      label: noteLabel(n.kind, n.body),
    });
  }

  const plans = manifest.plans ?? [];
  for (const p of plans) {
    nodes.push({
      id: nodeId("plan", p.id),
      kind: "plan",
      entityId: p.id,
      label: `Plan · ${p.planDate}`,
    });
  }

  // --- Edges -------------------------------------------------------------
  // combo-sequence: combo → member move, carrying the sequence position so the
  // ordering of a combo's moves is recoverable (used by combination discovery).
  for (const cm of manifest.comboMoves) {
    if (!comboExists.has(cm.comboId) || !moveExists.has(cm.moveId)) continue;
    const source = nodeId("combo", cm.comboId);
    const target = nodeId("move", cm.moveId);
    edges.push({
      id: `combo-sequence:${cm.comboId}:${cm.moveId}:${cm.sequenceIndex}`,
      kind: "combo-sequence",
      source,
      target,
      order: cm.sequenceIndex,
    });
  }

  // deck-membership: deck → member move.
  const deckExists = new Set(manifest.decks.map((d) => d.id));
  for (const dm of manifest.deckMoves) {
    if (!deckExists.has(dm.deckId) || !moveExists.has(dm.moveId)) continue;
    edges.push({
      id: `deck-membership:${dm.deckId}:${dm.moveId}`,
      kind: "deck-membership",
      source: nodeId("deck", dm.deckId),
      target: nodeId("move", dm.moveId),
    });
  }

  // annotation: note/plan → the combo it is attached to.
  for (const n of notes) {
    if (!comboExists.has(n.comboId)) continue;
    edges.push({
      id: `annotation:${n.id}`,
      kind: "annotation",
      source: nodeId("note", n.id),
      target: nodeId("combo", n.comboId),
    });
  }
  for (const p of plans) {
    if (!comboExists.has(p.comboId)) continue;
    edges.push({
      id: `annotation:${p.id}`,
      kind: "annotation",
      source: nodeId("plan", p.id),
      target: nodeId("combo", p.comboId),
    });
  }

  // aura-affinity: move → move transition affinity. Omitted when no aura data
  // is supplied (graceful degradation).
  for (const link of options.auraLinks ?? []) {
    if (!moveExists.has(link.fromMoveId) || !moveExists.has(link.toMoveId)) continue;
    edges.push({
      id: `aura-affinity:${link.fromMoveId}:${link.toMoveId}`,
      kind: "aura-affinity",
      source: nodeId("move", link.fromMoveId),
      target: nodeId("move", link.toMoveId),
      weight: link.weight,
    });
  }

  return { nodes, edges };
}

function noteLabel(kind: string, body: string): string {
  const trimmed = body.trim().replace(/\s+/g, " ");
  const snippet = trimmed.length > 40 ? `${trimmed.slice(0, 39)}…` : trimmed;
  return snippet ? `${kind}: ${snippet}` : kind;
}

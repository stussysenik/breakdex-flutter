// Shared styling + labels for node and edge kinds, used across the graph view,
// spatial canvas, and discovery panel so the visual language stays consistent.

import type { EdgeKind, NodeKind } from "@/lib/graph/model";

export const NODE_KINDS: NodeKind[] = ["move", "combo", "deck", "note", "plan"];
export const EDGE_KINDS: EdgeKind[] = [
  "combo-sequence",
  "aura-affinity",
  "deck-membership",
  "annotation",
];

export const NODE_COLOR: Record<NodeKind, string> = {
  move: "#2563eb", // blue
  combo: "#7c3aed", // violet
  deck: "#0891b2", // cyan
  note: "#d97706", // amber
  plan: "#059669", // green
};

export const NODE_LABEL: Record<NodeKind, string> = {
  move: "Moves",
  combo: "Combos",
  deck: "Decks",
  note: "Notes",
  plan: "Plans",
};

export const EDGE_COLOR: Record<EdgeKind, string> = {
  "combo-sequence": "#7c3aed",
  "aura-affinity": "#db2777",
  "deck-membership": "#0891b2",
  annotation: "#d97706",
};

export const EDGE_LABEL: Record<EdgeKind, string> = {
  "combo-sequence": "Combo sequence",
  "aura-affinity": "Aura affinity",
  "deck-membership": "Deck membership",
  annotation: "Annotation",
};

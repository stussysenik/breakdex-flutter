"use client";

import { useMemo, useState } from "react";
import type { LibraryManifest, Move } from "@/lib/types";
import type { GraphNode } from "@/lib/graph/model";
import type { MovePair } from "@/lib/graph/discovery";
import { projectGraph } from "@/lib/graph/projection";
import GraphView from "./GraphView";
import SpatialCanvas from "./SpatialCanvas";
import DiscoveryPanel from "./DiscoveryPanel";

// Discovery section container: builds the read-only graph projection once and
// hosts the three exploratory surfaces (graph / canvas / suggestions). Resolves
// move nodes back to Move records so click-through reuses the existing playback
// modal (owned by the parent Mirror).

type SubView = "graph" | "canvas" | "suggest";

const SUBVIEWS: { id: SubView; label: string }[] = [
  { id: "graph", label: "Graph" },
  { id: "canvas", label: "Canvas" },
  { id: "suggest", label: "Suggestions" },
];

export default function Discover({
  manifest,
  onOpenMove,
}: {
  manifest: LibraryManifest;
  onOpenMove: (move: Move) => void;
}) {
  const [view, setView] = useState<SubView>("graph");
  const [promoted, setPromoted] = useState<MovePair | null>(null);

  // The graph carries no aura links today (the manifest does not export them);
  // discovery degrades to co-occurrence automatically. Pass auraLinks here when
  // the labs model lands.
  const graph = useMemo(() => projectGraph(manifest), [manifest]);

  const moveByEntityId = useMemo(() => {
    const m = new Map<string, Move>();
    for (const mv of manifest.moves) m.set(mv.id, mv);
    return m;
  }, [manifest.moves]);

  const handleSelectNode = (node: GraphNode) => {
    if (node.kind !== "move") return;
    const move = moveByEntityId.get(node.entityId);
    if (move) onOpenMove(move);
  };

  const moveName = (id: string) => moveByEntityId.get(id)?.name ?? id;

  return (
    <div flex="~ col" gap="4">
      <div flex="~" gap="1" className="self-start rounded-lg border border-line p-0.5 bg-surface">
        {SUBVIEWS.map((s) => {
          const active = view === s.id;
          return (
            <button
              key={s.id}
              type="button"
              onClick={() => setView(s.id)}
              aria-pressed={active}
              p="x-3 y-1.5"
              rounded="md"
              text={active ? "sm ink" : "sm muted"}
              font="medium"
              className={`focus-ring transition-colors ${
                active ? "bg-white shadow-sm" : "hover:text-ink"
              }`}
            >
              {s.label}
            </button>
          );
        })}
      </div>

      {promoted ? (
        <div
          flex="~"
          items="center"
          gap="3"
          p="3"
          rounded="lg"
          className="border border-line bg-white"
        >
          <span text="sm ink" flex="1">
            Combine <strong>{moveName(promoted.a)}</strong> +{" "}
            <strong>{moveName(promoted.b)}</strong> — combo creation opens here once editing is
            enabled on the web (read-only mirror today).
          </span>
          <button
            type="button"
            onClick={() => setPromoted(null)}
            text="xs faint"
            className="focus-ring hover:text-ink shrink-0"
          >
            Dismiss
          </button>
        </div>
      ) : null}

      {view === "graph" ? (
        <GraphView graph={graph} onSelectNode={handleSelectNode} />
      ) : view === "canvas" ? (
        <SpatialCanvas graph={graph} onSelectNode={handleSelectNode} />
      ) : (
        <DiscoveryPanel graph={graph} onSelectNode={handleSelectNode} onPromote={setPromoted} />
      )}
    </div>
  );
}

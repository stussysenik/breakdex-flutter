"use client";

import { useMemo } from "react";
import type { Graph, GraphNode } from "@/lib/graph/model";
import { type MovePair, neverCombinedCandidates, orphanNodes } from "@/lib/graph/discovery";
import { NODE_COLOR } from "./kinds";

// Combination discovery: surfaces move pairs you've never sequenced (aura
// affinity, or co-occurrence as a fallback) and isolated nodes. Strictly
// read-only — the only write is the explicit "promote" action, which is routed
// to the parent (the existing combo-creation flow) rather than mutating here.

export default function DiscoveryPanel({
  graph,
  onPromote,
  onSelectNode,
}: {
  graph: Graph;
  /** Seed the existing combo-creation flow with a candidate's two moves. */
  onPromote?: (pair: MovePair) => void;
  onSelectNode?: (node: GraphNode) => void;
}) {
  const moveLabel = useMemo(() => {
    const m = new Map<string, string>();
    for (const n of graph.nodes) if (n.kind === "move") m.set(n.entityId, n.label);
    return (id: string) => m.get(id) ?? id;
  }, [graph.nodes]);

  const candidates = useMemo(() => neverCombinedCandidates(graph), [graph]);
  const orphans = useMemo(() => orphanNodes(graph), [graph]);

  const sourceNote =
    candidates.length > 0 && candidates[0].source === "co-occurrence"
      ? "No aura data yet — suggestions come from moves that share a combo or deck."
      : candidates.length > 0
        ? "Suggestions ranked by natural aura affinity."
        : null;

  return (
    <div flex="~ col" gap="6">
      <section>
        <SectionHeader title="Never combined" count={candidates.length} hint={sourceNote} />
        {candidates.length === 0 ? (
          <Empty>No new combinations to suggest — everything with an affinity is already sequenced.</Empty>
        ) : (
          <ul className="list-none p-0 grid gap-2 sm:grid-cols-2">
            {candidates.map(({ pair, source, weight }) => (
              <li
                key={`${pair.a}-${pair.b}`}
                flex="~"
                items="center"
                gap="3"
                p="3"
                rounded="lg"
                className="border border-line bg-white"
              >
                <div flex="1 ~ col" gap="0.5" className="min-w-0">
                  <span text="sm ink" font="medium" className="truncate">
                    {moveLabel(pair.a)} <span text="faint">+</span> {moveLabel(pair.b)}
                  </span>
                  <span text="xs faint">
                    {source === "aura"
                      ? `aura affinity${weight != null ? ` · ${weight.toFixed(2)}` : ""}`
                      : "shares a combo or deck"}
                  </span>
                </div>
                {onPromote ? (
                  <button
                    type="button"
                    onClick={() => onPromote(pair)}
                    p="x-3 y-1.5"
                    rounded="md"
                    text="xs white"
                    font="medium"
                    className="focus-ring bg-ink hover:opacity-90 transition-opacity shrink-0"
                  >
                    Make combo
                  </button>
                ) : null}
              </li>
            ))}
          </ul>
        )}
      </section>

      <section>
        <SectionHeader title="Isolated nodes" count={orphans.length} hint="Nothing connects to these yet." />
        {orphans.length === 0 ? (
          <Empty>Nothing is isolated — every node has at least one relationship.</Empty>
        ) : (
          <ul className="list-none p-0 flex flex-wrap gap-2">
            {orphans.map((n) => (
              <li key={n.id}>
                <button
                  type="button"
                  onClick={() => onSelectNode?.(n)}
                  flex="~"
                  items="center"
                  gap="1.5"
                  p="x-2.5 y-1"
                  rounded="full"
                  className="border border-line bg-white focus-ring hover:bg-surface transition-colors"
                  title={n.kind}
                >
                  <span
                    w="2"
                    h="2"
                    rounded="full"
                    className="shrink-0"
                    style={{ background: NODE_COLOR[n.kind] }}
                    aria-hidden="true"
                  />
                  <span text="xs ink">{n.label}</span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function SectionHeader({ title, count, hint }: { title: string; count: number; hint?: string | null }) {
  return (
    <div m="b-3">
      <div flex="~" items="baseline" gap="2">
        <h2 text="sm ink" font="semibold">
          {title}
        </h2>
        <span text="xs muted" className="tnum">
          {count}
        </span>
      </div>
      {hint ? (
        <p text="xs faint" m="t-0.5">
          {hint}
        </p>
      ) : null}
    </div>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return (
    <p text="sm muted" p="y-6">
      {children}
    </p>
  );
}

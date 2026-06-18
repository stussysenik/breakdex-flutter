"use client";

import { useMemo, useState } from "react";
import type { EdgeKind, Graph, GraphNode, NodeKind } from "@/lib/graph/model";
import { computeLayout } from "@/lib/graph/layout";
import {
  EDGE_COLOR,
  EDGE_KINDS,
  EDGE_LABEL,
  NODE_COLOR,
  NODE_KINDS,
  NODE_LABEL,
} from "./kinds";

// Dynamic discovery graph: force-directed layout of the projected library, with
// kind filters, focus/neighborhood emphasis, and click-through to playback
// (delegated to the parent via onSelectNode). Read-only over the data.

export default function GraphView({
  graph,
  onSelectNode,
}: {
  graph: Graph;
  /** Called when a node is opened (parent decides how to show detail/playback). */
  onSelectNode?: (node: GraphNode) => void;
}) {
  const [nodeKinds, setNodeKinds] = useState<Set<NodeKind>>(new Set(NODE_KINDS));
  const [edgeKinds, setEdgeKinds] = useState<Set<EdgeKind>>(new Set(EDGE_KINDS));
  const [focusId, setFocusId] = useState<string | null>(null);

  // Visible subgraph recomputed whenever filters change.
  const visible = useMemo<Graph>(() => {
    const nodes = graph.nodes.filter((n) => nodeKinds.has(n.kind));
    const present = new Set(nodes.map((n) => n.id));
    const edges = graph.edges.filter(
      (e) => edgeKinds.has(e.kind) && present.has(e.source) && present.has(e.target),
    );
    return { nodes, edges };
  }, [graph, nodeKinds, edgeKinds]);

  const layout = useMemo(() => computeLayout(visible), [visible]);

  // Neighborhood of the focused node (itself + direct neighbors).
  const neighborhood = useMemo(() => {
    if (!focusId) return null;
    const set = new Set<string>([focusId]);
    for (const e of visible.edges) {
      if (e.source === focusId) set.add(e.target);
      if (e.target === focusId) set.add(e.source);
    }
    return set;
  }, [focusId, visible.edges]);

  const bounds = useMemo(() => {
    const pts = [...layout.values()];
    if (pts.length === 0) return { minX: -100, minY: -100, w: 200, h: 200 };
    const xs = pts.map((p) => p.x);
    const ys = pts.map((p) => p.y);
    const pad = 60;
    const minX = Math.min(...xs) - pad;
    const minY = Math.min(...ys) - pad;
    return {
      minX,
      minY,
      w: Math.max(...xs) - minX + pad,
      h: Math.max(...ys) - minY + pad,
    };
  }, [layout]);

  const focusNode = focusId ? visible.nodes.find((n) => n.id === focusId) ?? null : null;

  const toggle = <T,>(set: Set<T>, value: T, apply: (s: Set<T>) => void) => {
    const next = new Set(set);
    if (next.has(value)) next.delete(value);
    else next.add(value);
    apply(next);
  };

  if (graph.nodes.length === 0) {
    return (
      <div text="sm muted center" p="y-20">
        Nothing to graph yet — add moves and combos to see relationships here.
      </div>
    );
  }

  return (
    <div flex="~ col" gap="3">
      <Filters
        nodeKinds={nodeKinds}
        edgeKinds={edgeKinds}
        onToggleNode={(k) => toggle(nodeKinds, k, setNodeKinds)}
        onToggleEdge={(k) => toggle(edgeKinds, k, setEdgeKinds)}
      />

      <div
        className="relative overflow-hidden rounded-lg border border-line bg-surface"
        style={{ height: "62vh", minHeight: 360 }}
      >
        {visible.nodes.length === 0 ? (
          <div text="sm muted center" className="absolute inset-0 flex items-center justify-center">
            No nodes match the current filters.
          </div>
        ) : (
          <svg
            width="100%"
            height="100%"
            viewBox={`${bounds.minX} ${bounds.minY} ${bounds.w} ${bounds.h}`}
            role="img"
            aria-label="Library relationship graph"
          >
            {visible.edges.map((e) => {
              const a = layout.get(e.source);
              const b = layout.get(e.target);
              if (!a || !b) return null;
              const dim = neighborhood
                ? !(neighborhood.has(e.source) && neighborhood.has(e.target))
                : false;
              return (
                <line
                  key={e.id}
                  x1={a.x}
                  y1={a.y}
                  x2={b.x}
                  y2={b.y}
                  stroke={EDGE_COLOR[e.kind]}
                  strokeWidth={1.4}
                  strokeOpacity={dim ? 0.07 : e.kind === "aura-affinity" ? 0.7 : 0.4}
                  strokeDasharray={e.kind === "aura-affinity" ? "4 3" : undefined}
                />
              );
            })}
            {visible.nodes.map((n) => {
              const p = layout.get(n.id);
              if (!p) return null;
              const dim = neighborhood ? !neighborhood.has(n.id) : false;
              const active = focusId === n.id;
              return (
                <g
                  key={n.id}
                  transform={`translate(${p.x},${p.y})`}
                  className="cursor-pointer"
                  opacity={dim ? 0.18 : 1}
                  onClick={() => setFocusId(active ? null : n.id)}
                >
                  <circle
                    r={active ? 9 : 6}
                    fill={NODE_COLOR[n.kind]}
                    stroke="#fff"
                    strokeWidth={1.5}
                  />
                  <text
                    x={10}
                    y={4}
                    fontSize={11}
                    fill="#1f2937"
                    style={{ pointerEvents: "none" }}
                  >
                    {n.label.length > 22 ? `${n.label.slice(0, 21)}…` : n.label}
                  </text>
                </g>
              );
            })}
          </svg>
        )}

        {focusNode ? (
          <FocusCard
            node={focusNode}
            onOpen={onSelectNode ? () => onSelectNode(focusNode) : undefined}
            onClear={() => setFocusId(null)}
          />
        ) : null}
      </div>
    </div>
  );
}

function Filters({
  nodeKinds,
  edgeKinds,
  onToggleNode,
  onToggleEdge,
}: {
  nodeKinds: Set<NodeKind>;
  edgeKinds: Set<EdgeKind>;
  onToggleNode: (k: NodeKind) => void;
  onToggleEdge: (k: EdgeKind) => void;
}) {
  return (
    <div flex="~ wrap" gap="3" items="center">
      <div flex="~ wrap" gap="1.5" items="center">
        <span text="xs faint" font="medium" className="uppercase tracking-wide mr-1">
          Nodes
        </span>
        {NODE_KINDS.map((k) => (
          <Chip
            key={k}
            label={NODE_LABEL[k]}
            color={NODE_COLOR[k]}
            on={nodeKinds.has(k)}
            onClick={() => onToggleNode(k)}
          />
        ))}
      </div>
      <div flex="~ wrap" gap="1.5" items="center">
        <span text="xs faint" font="medium" className="uppercase tracking-wide mr-1">
          Edges
        </span>
        {EDGE_KINDS.map((k) => (
          <Chip
            key={k}
            label={EDGE_LABEL[k]}
            color={EDGE_COLOR[k]}
            on={edgeKinds.has(k)}
            onClick={() => onToggleEdge(k)}
          />
        ))}
      </div>
    </div>
  );
}

function Chip({
  label,
  color,
  on,
  onClick,
}: {
  label: string;
  color: string;
  on: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={on}
      flex="~"
      items="center"
      gap="1.5"
      p="x-2 y-1"
      rounded="full"
      text="xs"
      className={`focus-ring border transition-colors ${
        on ? "border-line text-ink bg-white" : "border-transparent text-faint bg-transparent"
      }`}
    >
      <span
        w="2"
        h="2"
        rounded="full"
        className="shrink-0"
        style={{ background: on ? color : "#cbd5e1" }}
        aria-hidden="true"
      />
      {label}
    </button>
  );
}

function FocusCard({
  node,
  onOpen,
  onClear,
}: {
  node: GraphNode;
  onOpen?: () => void;
  onClear: () => void;
}) {
  return (
    <div
      className="absolute bottom-3 left-3 right-3 sm:right-auto sm:max-w-xs rounded-lg border border-line bg-white shadow-sm"
      p="3"
    >
      <div flex="~" items="center" gap="2">
        <span
          w="2.5"
          h="2.5"
          rounded="full"
          className="shrink-0"
          style={{ background: NODE_COLOR[node.kind] }}
          aria-hidden="true"
        />
        <span text="xs muted" font="medium" className="uppercase tracking-wide">
          {node.kind}
        </span>
        <button
          type="button"
          onClick={onClear}
          text="xs faint"
          m="l-auto"
          className="focus-ring hover:text-ink"
        >
          Clear
        </button>
      </div>
      <p text="sm ink" m="t-1" font="medium">
        {node.label}
      </p>
      {onOpen && node.kind === "move" ? (
        <button
          type="button"
          onClick={onOpen}
          m="t-2"
          p="x-3 y-1.5"
          rounded="md"
          text="xs white"
          font="medium"
          className="focus-ring bg-ink hover:opacity-90 transition-opacity"
        >
          Open video
        </button>
      ) : null}
    </div>
  );
}

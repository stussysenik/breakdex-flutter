"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { Graph, GraphNode } from "@/lib/graph/model";
import { type Vec, computeLayout } from "@/lib/graph/layout";
import {
  type CanvasLayout,
  deleteLayout,
  loadLayouts,
  partitionLayout,
  saveLayout,
} from "@/lib/graph/layoutStore";
import { NODE_COLOR } from "./kinds";

// Static spatial canvas: the owner drags nodes to arbitrary positions and saves
// named layouts. Layouts are ADDITIVE — they store positions by node id and
// never touch entities. Entries whose entity was deleted render as tombstone
// ghosts that can be pruned (from the layout only).

function newId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) return crypto.randomUUID();
  return `layout-${Date.now()}`;
}

export default function SpatialCanvas({
  graph,
  onSelectNode,
}: {
  graph: Graph;
  onSelectNode?: (node: GraphNode) => void;
}) {
  const nodeById = useMemo(() => {
    const m = new Map<string, GraphNode>();
    for (const n of graph.nodes) m.set(n.id, n);
    return m;
  }, [graph.nodes]);

  // Seed positions from the force layout so a fresh canvas isn't a pile.
  const seeded = useMemo(() => computeLayout(graph), [graph]);

  const [positions, setPositions] = useState<Record<string, Vec>>({});
  const [ghosts, setGhosts] = useState<{ id: string; pos: Vec }[]>([]);
  const [saved, setSaved] = useState<CanvasLayout[]>([]);
  const [currentId, setCurrentId] = useState<string | null>(null);

  // Initialize seeded positions and load saved layouts once the graph is known.
  useEffect(() => {
    const seedRecord: Record<string, Vec> = {};
    for (const [id, p] of seeded) seedRecord[id] = { x: p.x, y: p.y };
    setPositions(seedRecord);
    setGhosts([]);
    setCurrentId(null);
    setSaved(loadLayouts());
  }, [seeded]);

  const openLayout = useCallback(
    (layout: CanvasLayout) => {
      const { live, ghosts: ghostIds } = partitionLayout(layout, graph);
      // Live saved positions win; nodes absent from the layout keep their seed.
      const next: Record<string, Vec> = {};
      for (const [id, p] of seeded) next[id] = { x: p.x, y: p.y };
      for (const [id, p] of Object.entries(live)) next[id] = p;
      setPositions(next);
      setGhosts(ghostIds.map((id) => ({ id, pos: layout.positions[id] })));
      setCurrentId(layout.id);
    },
    [graph, seeded],
  );

  const persist = useCallback(
    (name: string, id: string) => {
      // Only persist positions for nodes that currently exist (no resurrecting ghosts).
      const livePositions: Record<string, Vec> = {};
      for (const [nodeId, p] of Object.entries(positions)) {
        if (nodeById.has(nodeId)) livePositions[nodeId] = p;
      }
      const layout: CanvasLayout = {
        id,
        name,
        positions: livePositions,
        updatedAt: new Date().toISOString(),
      };
      setSaved(saveLayout(layout));
      setCurrentId(id);
    },
    [positions, nodeById],
  );

  const onSaveAs = useCallback(() => {
    const name = window.prompt("Name this layout:");
    if (!name?.trim()) return;
    persist(name.trim(), newId());
  }, [persist]);

  const onSaveCurrent = useCallback(() => {
    const existing = saved.find((l) => l.id === currentId);
    if (!existing) return onSaveAs();
    persist(existing.name, existing.id);
  }, [saved, currentId, persist, onSaveAs]);

  const onDelete = useCallback(() => {
    if (!currentId) return;
    setSaved(deleteLayout(currentId)); // removes the layout record only
    setCurrentId(null);
    setGhosts([]);
  }, [currentId]);

  const onPrune = useCallback(() => {
    setGhosts([]); // drop tombstones from the view
    if (currentId) {
      const existing = saved.find((l) => l.id === currentId);
      if (existing) persist(existing.name, existing.id); // re-save without ghosts
    }
  }, [currentId, saved, persist]);

  // --- Dragging ---------------------------------------------------------
  const surfaceRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<{ id: string; dx: number; dy: number } | null>(null);

  const toLocal = (clientX: number, clientY: number): Vec => {
    const rect = surfaceRef.current?.getBoundingClientRect();
    return { x: clientX - (rect?.left ?? 0), y: clientY - (rect?.top ?? 0) };
  };

  const onPointerDown = (e: React.PointerEvent, id: string) => {
    const local = toLocal(e.clientX, e.clientY);
    const p = positions[id] ?? { x: local.x, y: local.y };
    dragRef.current = { id, dx: local.x - p.x, dy: local.y - p.y };
    (e.target as Element).setPointerCapture?.(e.pointerId);
  };

  const onPointerMove = (e: React.PointerEvent) => {
    const drag = dragRef.current;
    if (!drag) return;
    const local = toLocal(e.clientX, e.clientY);
    setPositions((prev) => ({
      ...prev,
      [drag.id]: { x: local.x - drag.dx, y: local.y - drag.dy },
    }));
  };

  const onPointerUp = () => {
    dragRef.current = null;
  };

  if (graph.nodes.length === 0) {
    return (
      <div text="sm muted center" p="y-20">
        Nothing to arrange yet — add moves and combos first.
      </div>
    );
  }

  return (
    <div flex="~ col" gap="3">
      <div flex="~ wrap" gap="2" items="center">
        <select
          value={currentId ?? ""}
          onChange={(e) => {
            const l = saved.find((x) => x.id === e.target.value);
            if (l) openLayout(l);
          }}
          text="sm ink"
          p="x-2 y-1"
          rounded="md"
          className="border border-line bg-white focus-ring"
          aria-label="Open a saved layout"
        >
          <option value="">Unsaved arrangement</option>
          {saved.map((l) => (
            <option key={l.id} value={l.id}>
              {l.name}
            </option>
          ))}
        </select>
        <CanvasBtn onClick={onSaveCurrent} label={currentId ? "Save" : "Save as…"} primary />
        {currentId ? <CanvasBtn onClick={onSaveAs} label="Save as new" /> : null}
        {currentId ? <CanvasBtn onClick={onDelete} label="Delete" /> : null}
        {ghosts.length > 0 ? (
          <CanvasBtn onClick={onPrune} label={`Prune ${ghosts.length} ghost${ghosts.length > 1 ? "s" : ""}`} />
        ) : null}
        <span text="xs faint" m="l-auto" className="hidden sm:inline">
          Drag nodes to arrange · layouts never change your data
        </span>
      </div>

      <div
        ref={surfaceRef}
        className="relative overflow-hidden rounded-lg border border-line bg-surface touch-none"
        style={{ height: "62vh", minHeight: 360 }}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerLeave={onPointerUp}
      >
        {ghosts.map((g) => (
          <div
            key={g.id}
            className="absolute -translate-x-1/2 -translate-y-1/2 rounded-md border border-dashed border-line bg-white/60"
            style={{ left: g.pos.x, top: g.pos.y }}
            p="x-2 y-1"
            title="Entity no longer exists"
          >
            <span text="xs faint" className="line-through">
              {g.id.split(":").slice(1).join(":") || g.id}
            </span>
          </div>
        ))}

        {graph.nodes.map((n) => {
          const p = positions[n.id];
          if (!p) return null;
          return (
            <button
              key={n.id}
              type="button"
              onPointerDown={(e) => onPointerDown(e, n.id)}
              onDoubleClick={() => onSelectNode?.(n)}
              className="absolute -translate-x-1/2 -translate-y-1/2 cursor-grab active:cursor-grabbing rounded-full border border-line bg-white shadow-sm focus-ring"
              style={{ left: p.x, top: p.y }}
              flex="~"
              items="center"
              gap="1.5"
              p="x-2.5 y-1"
              title={`${n.kind} · double-click to open`}
            >
              <span
                w="2"
                h="2"
                rounded="full"
                className="shrink-0"
                style={{ background: NODE_COLOR[n.kind] }}
                aria-hidden="true"
              />
              <span text="xs ink" className="whitespace-nowrap select-none">
                {n.label.length > 24 ? `${n.label.slice(0, 23)}…` : n.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function CanvasBtn({
  onClick,
  label,
  primary,
}: {
  onClick: () => void;
  label: string;
  primary?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      p="x-3 y-1"
      rounded="md"
      text={primary ? "sm white" : "sm muted"}
      font="medium"
      className={`focus-ring transition-colors ${
        primary ? "bg-ink hover:opacity-90" : "border border-line hover:text-ink hover:bg-white"
      }`}
    >
      {label}
    </button>
  );
}

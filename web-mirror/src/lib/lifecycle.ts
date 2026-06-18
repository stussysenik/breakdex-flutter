// Pure, read-only projection from the library manifest to a per-entity
// lifecycle timeline. Like `projectGraph`, this MUST NOT mutate its input and
// is deterministic. Lifecycle is a *projection of recorded history* (D3): when
// a caller supplies an entity's event history it is used verbatim; otherwise
// the timeline degrades gracefully to what the manifest can reconstruct
// (creation, current memberships, reviews, archival) rather than failing.

import type { LibraryManifest, Move } from "./types";

export type LifecycleEventKind =
  | "created"
  | "edited"
  | "combined"
  | "reviewed"
  | "archived";

export interface LifecycleEvent {
  kind: LifecycleEventKind;
  /** ISO timestamp, or null when the source carries no date (e.g. a membership
   *  link the manifest does not timestamp). Null events sort last, stably. */
  at: string | null;
  label: string;
  detail?: string;
}

export interface EntityRef {
  entityType: "move" | "combo";
  entityId: string;
}

export interface LifecycleTimeline {
  ref: EntityRef;
  name: string;
  archived: boolean;
  /** Chronological (ascending); undated events kept last in insertion order. */
  events: LifecycleEvent[];
  /** True when degraded from the manifest because no recorded history existed. */
  reconstructed: boolean;
}

export interface ProjectLifecycleOptions {
  /**
   * Recorded event history for this entity from the provenance ledger. Absent
   * today (the manifest does not carry it yet); when supplied and non-empty it
   * is used as the source of truth instead of manifest reconstruction.
   */
  events?: LifecycleEvent[];
}

const RATING_LABEL: Record<string, string> = {
  again: "Again",
  hard: "Hard",
  good: "Good",
  easy: "Easy",
};

/** Stable chronological sort: dated events ascending, undated events kept last. */
function sortChronological(events: LifecycleEvent[]): LifecycleEvent[] {
  return events
    .map((e, i) => ({ e, i }))
    .sort((a, b) => {
      const ta = a.e.at ? Date.parse(a.e.at) : NaN;
      const tb = b.e.at ? Date.parse(b.e.at) : NaN;
      const aBad = Number.isNaN(ta);
      const bBad = Number.isNaN(tb);
      if (aBad && bBad) return a.i - b.i; // both undated → preserve order
      if (aBad) return 1; // undated sorts after dated
      if (bBad) return -1;
      return ta - tb || a.i - b.i;
    })
    .map(({ e }) => e);
}

/**
 * Build the lifecycle timeline for a single move or combo. Read-only and
 * deterministic. When `options.events` is supplied it is the source of truth;
 * otherwise the timeline is reconstructed from the manifest.
 */
export function projectLifecycle(
  manifest: LibraryManifest,
  ref: EntityRef,
  options: ProjectLifecycleOptions = {},
): LifecycleTimeline {
  const movesById = new Map<string, Move>();
  for (const mv of manifest.moves) movesById.set(mv.id, mv);

  const name =
    ref.entityType === "move"
      ? movesById.get(ref.entityId)?.name ?? ref.entityId
      : manifest.combos.find((c) => c.id === ref.entityId)?.name ?? ref.entityId;

  const archived =
    ref.entityType === "move"
      ? !!movesById.get(ref.entityId)?.deletedAt
      : !!manifest.combos.find((c) => c.id === ref.entityId)?.deletedAt;

  // Recorded history wins when present.
  const recorded = options.events ?? [];
  if (recorded.length > 0) {
    return {
      ref,
      name,
      archived,
      events: sortChronological(recorded),
      reconstructed: false,
    };
  }

  const events: LifecycleEvent[] =
    ref.entityType === "move"
      ? reconstructMove(manifest, movesById, ref.entityId)
      : reconstructCombo(manifest, movesById, ref.entityId);

  return { ref, name, archived, events: sortChronological(events), reconstructed: true };
}

function reconstructMove(
  manifest: LibraryManifest,
  movesById: Map<string, Move>,
  moveId: string,
): LifecycleEvent[] {
  const events: LifecycleEvent[] = [];
  const move = movesById.get(moveId);

  if (move?.createdAt) {
    events.push({ kind: "created", at: move.createdAt, label: "Created", detail: move.category });
  }

  // combined/used: membership in each combo (the manifest does not timestamp
  // the link, so these are undated).
  const comboName = new Map(manifest.combos.map((c) => [c.id, c.name]));
  const seen = new Set<string>();
  for (const cm of manifest.comboMoves) {
    if (cm.moveId !== moveId || seen.has(cm.comboId)) continue;
    seen.add(cm.comboId);
    events.push({
      kind: "combined",
      at: null,
      label: "Added to combo",
      detail: comboName.get(cm.comboId) ?? cm.comboId,
    });
  }

  events.push(...reviewEvents(manifest, "move", moveId));

  if (move?.deletedAt) {
    events.push(archivedEvent(move.deletedAt));
  }
  return events;
}

function reconstructCombo(
  manifest: LibraryManifest,
  movesById: Map<string, Move>,
  comboId: string,
): LifecycleEvent[] {
  const events: LifecycleEvent[] = [];
  const combo = manifest.combos.find((c) => c.id === comboId);

  const members = manifest.comboMoves
    .filter((cm) => cm.comboId === comboId)
    .sort((a, b) => a.sequenceIndex - b.sequenceIndex);

  // Combos carry no createdAt; reconstruct creation from the earliest member
  // move's createdAt as a best-effort anchor.
  const memberCreatedAts = members
    .map((cm) => movesById.get(cm.moveId)?.createdAt)
    .filter((d): d is string => !!d)
    .sort();
  const createdAt = memberCreatedAts[0] ?? null;
  events.push({
    kind: "created",
    at: createdAt,
    label: "Created",
    detail: createdAt ? "inferred from members" : undefined,
  });

  if (members.length > 0) {
    events.push({
      kind: "combined",
      at: null,
      label: "Sequenced moves",
      detail: `${members.length} move${members.length === 1 ? "" : "s"}`,
    });
  }

  events.push(...reviewEvents(manifest, "combo", comboId));

  if (combo?.deletedAt) {
    events.push(archivedEvent(combo.deletedAt));
  }
  return events;
}

function reviewEvents(
  manifest: LibraryManifest,
  entityType: "move" | "combo",
  entityId: string,
): LifecycleEvent[] {
  return manifest.reviews
    .filter((r) => r.entityType === entityType && r.entityId === entityId)
    .map((r) => ({
      kind: "reviewed" as const,
      at: r.createdAt,
      label: "Reviewed",
      detail: RATING_LABEL[r.rating] ?? r.rating,
    }));
}

function archivedEvent(at: string): LifecycleEvent {
  return { kind: "archived", at, label: "Archived", detail: "soft-deleted · recoverable" };
}

// Provider-agnostic sync contract — the boundary that lets the web (and, in
// concept, the Flutter app) treat a canonical backend as the source of truth
// while every local store is a cache. NO backend types (Firestore, Postgres,
// Drive) may leak across this interface; that is the whole point — the concrete
// provider is swappable without re-spec.
//
// Spec: openspec/changes/evolve-web-mirror-to-crud-platform/specs/
//       shared-source-of-truth/spec.md  (Phase 1.1)
//
// This file is types + contract only. It performs NO I/O and is safe to import
// anywhere. Implementations (Firestore adapter, IndexedDB cache, reconciler)
// land in later Phase 1 tasks behind these interfaces.

/** Entity kinds that live in the canonical truth (media blobs stay in Drive). */
export type EntityKind =
  | "move"
  | "combo"
  | "comboMove"
  | "deck"
  | "deckMove"
  | "note"
  | "plan"
  | "review"
  | "fsrsCard";

/**
 * The sync envelope every truth record carries. Wraps an arbitrary payload with
 * the two fields the contract reconciles on:
 *
 * - `updatedAt`: monotonic last-write timestamp (epoch ms). Drives last-writer-
 *   wins per field. MUST never move backwards for a given (kind,id).
 * - `deletedAt`: soft-delete tombstone. A non-null value means archived, never
 *   erased — the record, its media reference, and its history stay readable.
 *
 * The contract is deliberately field-agnostic about `data`; per-entity shapes
 * live in `@/lib/types`. Reconciliation is per-field LWW over `data`.
 */
export interface Versioned<T = Record<string, unknown>> {
  kind: EntityKind;
  id: string;
  data: T;
  /** Epoch ms, monotonic per (kind,id). */
  updatedAt: number;
  /** Soft-delete marker (epoch ms) or null when active. */
  deletedAt: number | null;
}

/** A single field-level edit, applied optimistically then written through. */
export interface Mutation<T = Record<string, unknown>> {
  kind: EntityKind;
  id: string;
  /** Partial payload to merge into the record's `data`. */
  patch: Partial<T>;
  /** Client-stamped write time (epoch ms) — becomes the record `updatedAt`. */
  updatedAt: number;
  /** Set to archive (soft-delete); omit to leave lifecycle unchanged. */
  archive?: boolean;
}

/** Lifecycle of a single write as it travels to canonical truth. */
export type WriteStatus = "pending" | "saved" | "failed";

/** Observable status of one in-flight or settled mutation, for optimistic UI. */
export interface WriteRecord {
  mutation: Mutation;
  status: WriteStatus;
  /** Present only when `status === "failed"`; the write is retryable. */
  error?: string;
}

/**
 * The canonical truth store, provider-agnostic. A concrete adapter (e.g.
 * Firestore behind this interface) implements it; clients never see provider
 * types. All reads return sync envelopes so the caller can reconcile.
 */
export interface TruthStore {
  /** Read every record of a kind, including tombstones (callers filter). */
  readAll(kind: EntityKind): Promise<Versioned[]>;

  /**
   * Write-through a mutation. Resolves with the acknowledged record only after
   * the backend confirms — i.e. "saved" means it actually landed. Rejects
   * (leaving the caller to mark the write `failed` and retry) otherwise.
   */
  write(mutation: Mutation): Promise<Versioned>;

  /**
   * Records changed at/after `since` (epoch ms) — the incremental pull the
   * reconciler uses. Implementations MAY return all records when they cannot
   * filter server-side; reconcile stays correct either way.
   */
  changedSince(since: number): Promise<Versioned[]>;
}

/** Local cache of truth (IndexedDB on web, Drift on Flutter — in concept). */
export interface CacheStore {
  readAll(kind: EntityKind): Promise<Versioned[]>;
  /** Upsert reconciled records; MUST preserve tombstones, never hard-delete. */
  upsert(records: Versioned[]): Promise<void>;
  /** Highest `updatedAt` the cache has seen — the reconcile watermark. */
  highWaterMark(): Promise<number>;
}

/** Outcome of one reconcile pass, for status surfacing and tests. */
export interface ReconcileResult {
  pulled: number;
  pushed: number;
  /** Conflicts resolved by last-writer-wins; superseded values kept in history. */
  conflictsResolved: number;
}

/**
 * Two-way reconciler between a {@link CacheStore} and a {@link TruthStore}.
 * Resolution is last-writer-wins per field on `updatedAt`, under a
 * single-writer-at-a-time assumption. Until reconcile is verified end-to-end
 * (Phase 1.7), the local cache stays authoritative and the backend is a shadow.
 */
export interface Reconciler {
  reconcile(): Promise<ReconcileResult>;
}

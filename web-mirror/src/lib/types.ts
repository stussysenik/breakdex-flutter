// Mirrors lib/core/web/library_manifest.dart (LibraryManifest.toJson, version 2).
// The web mirror is read-only: these types describe what we READ, never write.

export interface Move {
  id: string;
  name: string;
  category: string;
  contentHash: string | null;
  createdAt: string;
  // Soft-archive marker (forward-looking, manifest-optional). When present the
  // move is a tombstone: still listed and playable, but rendered as archived.
  // Older manifests omit it → active. The canonical truth never hard-deletes.
  deletedAt?: string | null;
}

export interface Combo {
  id: string;
  name: string;
  // Soft-archive marker; see Move.deletedAt.
  deletedAt?: string | null;
}

export interface ComboMove {
  comboId: string;
  moveId: string;
  sequenceIndex: number;
}

export interface Category {
  name: string;
  colorValue: number;
  isDefault: boolean;
}

export interface FsrsCard {
  entityId: string;
  entityType: string;
  state: number;
  stability: number | null;
  difficulty: number | null;
  due: string;
}

export interface Deck {
  id: string;
  name: string;
  deckType: string;
}

export interface DeckMove {
  deckId: string;
  moveId: string;
}

export interface Review {
  id: string;
  entityId: string;
  entityType: string;
  rating: string;
  createdAt: string;
}

export interface Asset {
  contentHash: string;
  fileSizeBytes: number;
  mimeType: string;
  durationMs: number | null;
  width: number | null;
  height: number | null;
  importedAt: string;
  sourceType: string;
  sourceName: string | null;
  deletedAt: string | null;
}

export interface Note {
  id: string;
  comboId: string;
  kind: string;
  body: string;
  videoContentHash: string | null;
  createdAt: string;
}

export interface Plan {
  id: string;
  comboId: string;
  planDate: string;
  position: number;
  completedAt: string | null;
}

export interface LibraryManifest {
  version: number;
  exportedAt: string;
  moves: Move[];
  combos: Combo[];
  comboMoves: ComboMove[];
  categories: Category[];
  fsrsCards: FsrsCard[];
  decks: Deck[];
  deckMoves: DeckMove[];
  reviews: Review[];
  assets: Asset[];
  // Added in manifest v2 — older manifests omit these; default to [].
  notes?: Note[];
  plans?: Plan[];
}

/** Normalize a parsed manifest so optional v2 fields are always arrays. */
export function normalizeManifest(raw: LibraryManifest): LibraryManifest {
  return { ...raw, notes: raw.notes ?? [], plans: raw.plans ?? [] };
}

/**
 * Resolves a move/note content hash to a playable URL (or null if unavailable).
 * Async because the Drive source fetches authenticated bytes on demand; the demo
 * source resolves synchronously but conforms to the same contract.
 */
export type VideoResolver = (
  contentHash: string | null,
) => Promise<string | null>;

/** A loaded library plus the means to resolve its videos. */
export interface MirrorData {
  manifest: LibraryManifest;
  resolveVideo: VideoResolver;
  sourceLabel: string;
}

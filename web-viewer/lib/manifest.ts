/** Manifest schema v1 — matches the Flutter ManifestSerializer output. */

export interface Manifest {
  version: number
  exportedAt: string
  moves: ManifestMove[]
  combos: ManifestCombo[]
  comboMoves: ManifestComboMove[]
  categories: ManifestCategory[]
  fsrsCards: ManifestFsrsCard[]
  decks: ManifestDeck[]
  deckMoves: ManifestDeckMove[]
  reviews: ManifestReview[]
}

export interface ManifestMove {
  id: string
  name: string
  category: string
  contentHash: string | null
  createdAt: string
}

export interface ManifestCombo {
  id: string
  name: string
}

export interface ManifestComboMove {
  comboId: string
  moveId: string
  sequenceIndex: number
}

export interface ManifestCategory {
  name: string
  colorValue: number
  isDefault: boolean
}

export interface ManifestFsrsCard {
  entityId: string
  entityType: string
  state: number
  stability: number | null
  difficulty: number | null
  due: string
}

export interface ManifestDeck {
  id: string
  name: string
  deckType: string
}

export interface ManifestDeckMove {
  deckId: string
  moveId: string
}

export interface ManifestReview {
  id: string
  entityId: string
  entityType: string
  rating: string
  createdAt: string
}

/** FSRS state labels matching the Flutter convention. */
export const FSRS_STATE_LABELS: Record<number, string> = {
  0: 'New',
  1: 'Learning',
  2: 'Review',
  3: 'Relearning',
}

/** Convert a category colorValue (ARGB int) to CSS hex color. */
export function categoryColor(colorValue: number): string {
  const hex = (colorValue & 0xFFFFFF).toString(16).padStart(6, '0')
  return `#${hex}`
}

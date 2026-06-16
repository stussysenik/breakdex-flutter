// Local analytics over the manifest. Kept behind a plain interface so the
// engine can be swapped (e.g. DuckDB-WASM) without touching the views.
import type { LibraryManifest } from "./types";

export type Tone = "good" | "warn" | "bad" | "accent" | "muted";

export interface Bar {
  key: string;
  label: string;
  value: number;
  tone: Tone;
}

export interface DueBucket {
  label: string;
  value: number;
  overdue: boolean;
}

export interface Stats {
  totals: {
    moves: number;
    withVideo: number;
    combos: number;
    notes: number;
    plans: number;
    reviews: number;
    cards: number;
  };
  ratings: Bar[];
  mastery: Bar[];
  due: DueBucket[];
  categories: { name: string; count: number }[];
  avgStability: number | null;
  dueNow: number;
}

const RATING_TONE: Record<string, Tone> = {
  again: "bad",
  hard: "warn",
  good: "good",
  easy: "accent",
};

const STATE_LABEL: { key: string; label: string; tone: Tone }[] = [
  { key: "0", label: "New", tone: "muted" },
  { key: "1", label: "Learning", tone: "warn" },
  { key: "2", label: "Review", tone: "good" },
  { key: "3", label: "Relearning", tone: "bad" },
];

function startOfToday(now: Date): Date {
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function dayOffset(iso: string, base: Date): number {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return Infinity;
  const sd = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  return Math.round((sd.getTime() - base.getTime()) / 86_400_000);
}

export function computeStats(manifest: LibraryManifest, now = new Date()): Stats {
  const notes = manifest.notes ?? [];
  const plans = manifest.plans ?? [];
  const cards = manifest.fsrsCards;
  const base = startOfToday(now);

  // Ratings ─────────────────────────────────────────────
  const ratingCount = new Map<string, number>();
  for (const r of manifest.reviews) {
    ratingCount.set(r.rating, (ratingCount.get(r.rating) ?? 0) + 1);
  }
  const ratings: Bar[] = ["again", "hard", "good", "easy"].map((k) => ({
    key: k,
    label: k[0].toUpperCase() + k.slice(1),
    value: ratingCount.get(k) ?? 0,
    tone: RATING_TONE[k] ?? "muted",
  }));

  // Mastery (FSRS state distribution) ───────────────────
  const stateCount = new Map<number, number>();
  for (const c of cards) {
    stateCount.set(c.state, (stateCount.get(c.state) ?? 0) + 1);
  }
  const mastery: Bar[] = STATE_LABEL.map((s) => ({
    key: s.key,
    label: s.label,
    value: stateCount.get(Number(s.key)) ?? 0,
    tone: s.tone,
  }));

  // Due timeline ────────────────────────────────────────
  const dueRaw = [
    { label: "Overdue", off: -1, overdue: true },
    { label: "Today", off: 0, overdue: false },
    { label: "Tomorrow", off: 1, overdue: false },
    { label: "+2d", off: 2, overdue: false },
    { label: "+3d", off: 3, overdue: false },
    { label: "+4d", off: 4, overdue: false },
    { label: "+5d", off: 5, overdue: false },
    { label: "Later", off: 6, overdue: false },
  ];
  const dueCount = new Array(dueRaw.length).fill(0);
  for (const c of cards) {
    const off = dayOffset(c.due, base);
    if (off < 0) dueCount[0] += 1;
    else if (off === 0) dueCount[1] += 1;
    else if (off >= 1 && off <= 5) dueCount[1 + off] += 1;
    else dueCount[7] += 1;
  }
  const due: DueBucket[] = dueRaw.map((d, i) => ({
    label: d.label,
    value: dueCount[i],
    overdue: d.overdue,
  }));
  const dueNow = dueCount[0] + dueCount[1];

  // Categories ──────────────────────────────────────────
  const catCount = new Map<string, number>();
  for (const m of manifest.moves) {
    catCount.set(m.category, (catCount.get(m.category) ?? 0) + 1);
  }
  const categories = [...catCount.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count);

  // Avg recall strength (stability) ─────────────────────
  const stabilities = cards
    .map((c) => c.stability)
    .filter((s): s is number => typeof s === "number");
  const avgStability =
    stabilities.length === 0
      ? null
      : stabilities.reduce((a, b) => a + b, 0) / stabilities.length;

  return {
    totals: {
      moves: manifest.moves.length,
      withVideo: manifest.moves.filter((m) => m.contentHash).length,
      combos: manifest.combos.length,
      notes: notes.length,
      plans: plans.length,
      reviews: manifest.reviews.length,
      cards: cards.length,
    },
    ratings,
    mastery,
    due,
    categories,
    avgStability,
    dueNow,
  };
}

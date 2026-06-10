# Design — Combo Journey System

## Context

Converged over 13 interactive prototypes (final: `.superpowers/brainstorm/25976-1781131508/content/13-three-tabs.html`). Constraints set by the user during brainstorming, in priority order:

1. **Data is in production. Never doom it.** Additive migrations only; journal is append-only; videos are referenced, never copied per-combo.
2. **Memorable model**: a combo is a sequence with a tag and a journal. If a screen can't be recited from memory, it's too complex.
3. **Faithful to existing design system**: AppSpacing/AppTypography/AppColors, 60/30/10 color rule, existing widgets (`ComboStepLine`, `AppSegmentedControl`, calendar pattern, `ActionTile`).
4. **Text is the signifier** (Norman): words label everything; color only reinforces.
5. **Real-time everything**: Drift streams drive all surfaces; progress is determinate and monotone.

## Data Model (schema v21 → v22, all additive)

```text
combos
  + status     TEXT NOT NULL DEFAULT 'idea'     -- idea|attempting|landed|clean
  + createdAt  DATETIME NOT NULL DEFAULT now    -- drives Library auto-grouping

combo_note_entries                               -- EXISTING append-only ledger
  + kind       TEXT NOT NULL DEFAULT 'jot'      -- jot|status|plan|duplicate
  + videoPath  TEXT NULL                        -- relative ref into Documents/Moves/…
  + videoHash  TEXT NULL                        -- content hash into .breakdex-master

combo_plans (NEW)
  id          TEXT PK
  comboId     TEXT NOT NULL REFERENCES combos(id) ON DELETE CASCADE
  planDate    DATETIME NOT NULL                 -- the day it's planned for (date-only semantics)
  position    INTEGER NOT NULL DEFAULT 0        -- the dancer's sequence within a day/queue
  createdAt   DATETIME NOT NULL DEFAULT now
  completedAt DATETIME NULL                     -- set by evidence, never required
```

### Decisions & tradeoffs

- **Status lives on the combo, not in entry types.** Earlier prototypes (08/09) used typed entries (`NOTE/ATTEMPT/LANDED`); the user rejected the ceremony. Final model: tag is current truth (mutable, one column); history is the auto-appended `kind='status'` journal row (`"attempting → landed"` in body). One source for "now", one ledger for "forever". Reuses the exact `labs.status` vocabulary — zero new words.
- **`createdAt` backfill**: existing combos get `MIN(combo_note_entries.createdAt)` when entries exist, else migration time. Never NULL, never guessed beyond that.
- **`status` backfill**: all existing combos default `'idea'`. No heuristic promotion — the tag is the user's judgment; a wrong automatic "landed" is worse than a re-tap.
- **Videos by reference**: a jot's video is `videoPath` (+ `videoHash` when known) pointing at the *existing* sandbox/master copy. The write guard (`VideoStorageGate`) already forbids stray copies; this change adds **zero** new video files for combo usage. Deleting a move that a jot references: jot keeps the row; UI renders "video no longer available — was windmill_03.MOV" (resolver miss is non-fatal, logged).
- **Plans are intentions, not history** — hence a separate small table, NOT ledger rows. `completedAt` is stamped when a jot for that combo lands on `planDate` (evidence-based completion, checked by a rollup query, not a trigger). Plans may be deleted freely; the practice evidence lives in the journal regardless.
- **No new color vocabulary**: tag colors map `idea`(neutral dashed) / `attempting`(stateLearning) / `landed`(stateMastery border) / `clean`(stateMastery filled).

### Migration safety (the "don't doom data" proof)

- v22 `onUpgrade`: 4 × `addColumn` + 1 × `createTable` — no row rewrites, no drops, no type changes.
- Migration test: seed a v21 database with combos + note entries + moves, upgrade, assert: row counts identical, bodies byte-identical, new columns at defaults, `createdAt` backfill correct.
- Export schema bumps to v7 (adds status/createdAt/kind/video refs/plans); import accepts v6 (missing fields → defaults). Round-trip test required.

## UI Architecture

All views are pure projections of streams. No view owns derived state.

```text
CombosScreen (tab host, AppSegmentedControl: Library | Planned | Calendar)
├── LibraryView          watchCombosWithMeta()        — auto-grouped by createdAt month
├── PlannedView          watchPlansQueue()            — ordered queue + progress strip
├── ComboCalendarView    watchActivityRollup()        — past heat + future plans
ComboDetailScreen        watchCombo(id) + watchEntries(id)
├── header: back · title(titleLarge) · transition chain · StatusTag
├── RobustVideoPlayer (active step's move video — existing behavior)
├── ComboStepLine (existing widget, names under numbers, scrolls to 10+)
├── JournalList (56/16/fluid grid; fluid type 14/16 by length; kind='status' rows muted)
├── JotComposer (pinned bottom: text field · "+ video" · send)
└── ⋯ sheet: Plan for a day… · Duplicate · Edit · Share · Save to Album · Delete
LibraryVideoPickerSheet  watchComboMoveVideos(id) + watchRecentTakeRefs(id)
```

### CTA & orientation rules (Flutter/Material philosophy)

- **One primary action per screen**: Library → FAB "+" (new combo); Planned → filled button "Plan a combo"; Calendar future-day → "+ Plan"; Detail → the jot field is the always-visible primary affordance.
- Every screen states where you are: `titleLarge` header on tabs; `‹ COMBOS` breadcrumb + combo name on detail.
- Touch targets ≥ 48dp (step nodes 36dp visual inside ≥48dp hit area — matches existing `TimelineNode` hit handling).
- Size-up ramp: prefer the larger type style when in doubt (`titleLarge` headers, `bodyMedium` defaults); secondary data in `caption`/mono.
- Verbs on controls: "Plan a combo", "+ video", "Log", "tap to change" — no icon-only primary actions.
- 60/30/10: accent appears only at — segmented selection, FAB/primary button, active step node, leading bar, send. Counted and enforced in review.

### Loading & progress contract

- Every list: Drift `watch()` → `StreamProvider`; first frame shows skeleton ≤ 1 frame when cache is warm (moves are already materialized — combos compose local files; there is no network).
- Every sizable operation (Photos import, thumbnail generation, export) reports **determinate, monotone** progress from byte/frame counts. Indeterminate spinners are forbidden where size is knowable. A progress value that hasn't advanced in 2s logs a `StageLogger.stage('stalled')` diagnostic.
- Stale-UI ban: no `FutureProvider` for data that can change; replaced views are deleted, not orphaned (zombie audit via `ast-grep` for unreferenced widget classes).

## Storage Hygiene design

Extends existing healers (no new subsystem):
- `VideoPathHealer` gains a **stale-folder sweep**: empty dirs under `Moves/` (exists), plus legacy `Documents/videos/` migration-then-prune, plus temp export dirs older than 24h.
- `CanonicalFolderService` ledger-consistency pass: every master hash file referenced by ≥1 row in `asset_manifest`/`moves`/`combo_note_entries.videoHash`; unreferenced → quarantine to `Moves/Archive/` (never hard-delete), counted in diagnostics.
- All sweeps idempotent (run-twice test) and reported on the diagnostics screen as counters: `staleFoldersRemoved`, `orphansQuarantined`, `pathsHealed`.

## Files Deep Link design

- Info.plist: declare viewer role for `public.movie` + `LSSupportsOpeningDocumentsInPlace=NO` (Breakdex owns sandbox copies; opening *in place* would bypass the storage gate).
- `application(_:open:options:)` → `DeepLinkResolver`: compute content hash (stream, first/last 1MB + size fast-hash, fall back to full hash) → match `asset_manifest`/`moves.contentHash` → route `/moves/{id}`; if the file matches a combo-linked take, land on the combo step. No match → offer the existing import flow with the file pre-selected.
- Resolution and routing fully logged via StageLogger for physical-device debugging.

## Testing strategy (time/money-weighted)

1. **Unit (cheap, mandatory)**: migration v21→v22 with seeded data; DAO CRUD + streams for plans; status-change appends ledger row; evidence-completion rollup; duplicate provenance; healer idempotency; deep-link resolver matching.
2. **Widget (targeted)**: tag picker writes status row; journal grid renders kinds; planner reorder persists positions.
3. **Device (manual, logged)**: physical test pass relies on StageLogger/blackbox — every new flow logs begin/stage/complete/fail so failures during the user's physical testing are capturable post-hoc.
4. **Build gate**: `dart run build_runner build`, `flutter analyze`, `flutter test` green before any claim of done.

## Rollout

Phased per tasks.md: data model first (lowest risk, unblocks everything), then detail page (highest daily value), then tabs/planner, then hygiene/deep-link/reactivity audit. Each phase lands compiling and tested; the old combo list remains routable until the new index passes review (flagless — views swap at the route level in one commit per phase).

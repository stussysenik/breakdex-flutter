# Design — Discovery Graph & Spatial Canvas

## Context

Breakdex's library is relational but only ever surfaced as flat lists and detail pages. The owner
wants an exploratory, spatial perspective — a graph and a freeform canvas — that turns the catalog
into a discovery surface ("a digital garden"). The central design question is **where the graph
lives**, because the data already encodes the relationships we want to show.

## Goals

- Render the existing library as an interactive graph and a hand-arranged canvas.
- Surface combinations the owner has never tried, deterministically.
- Add zero risk to existing data; ship a useful read-only slice without depending on the full
  read-write platform.

## Key decision: graph as a *view*, not a new *store*

### Options considered

1. **Add SurrealDB** as a graph/document store backing the relationships.
2. **Project the existing relational data into a graph model at read time** (chosen).

### Why projection wins here

- **The edges already exist as rows.** `comboMoves` (sequence adjacency), `aura_links`
  (move→move transition affinity), `deckMoves` (grouping), and `notes`/`plans` (annotations) are
  exactly the edges we render. There is nothing to "graphify" — only to read.
- **The graph is small.** A single user's library is hundreds, not millions, of nodes. Force-directed
  layout and traversal run comfortably client-side, in-memory.
- **Discovery queries are simple traversals.** "Moves with a natural aura affinity but no connecting
  comboMove" is a set difference over two edge lists. "Orphan moves" is degree-0 detection.
  Recursive reach is a SQLite recursive CTE on device, or a BFS in JS on web. No graph engine needed.
- **Avoids a fourth source of truth.** Device = Drift; web = Drive manifest; backend = Postgres+S3
  (`add-beam-web-architecture-foundation`). A SurrealDB would add another store to reconcile, against
  the project's explicit "push back complexity" constraint, for capability we get for free as a view.

### Revisit trigger (when a graph store would earn its place)

- Server-side traversal over data too large to ship to the client, **or**
- Graph queries that are awkward/slow as recursive CTEs or in-memory BFS at real data sizes, **or**
- A multi-user relationship graph (shared discovery) that needs server-side graph semantics.

Until one of those is real, the projection stays.

## Architecture

```
existing data (manifest.json / Drift rows)
        │  (pure, read-only)
        ▼
discovery-graph-projection  →  { nodes: Node[], edges: Edge[] }
        │                         node kinds: move | combo | note | plan | deck
        │                         edge kinds: combo-sequence | aura-affinity
        │                                     | deck-membership | annotation
        ├────────────► discovery-graph-view   (force-directed, dynamic)
        ├────────────► spatial-canvas         (manual positions, saved layouts)
        └────────────► combination-discovery  (never-combined pairs, suggestions)
                              │
                              └─► promote → existing combo-creation CRUD path
```

- **Projection** is a pure function: same input → same graph. No side effects, no writes. This makes
  it trivially testable and reusable on both web and device.
- **Layouts** (canvas positions + named saved boards) are the *only* new persisted data. They are
  additive records keyed by id, stored in `localStorage` initially and migratable to the CRUD
  platform's backend layout store later. They reference entity ids but never mutate entities.
- **Promotion** (discovered pair → real combo) is the single write, and it reuses the existing,
  guarded combo-creation flow rather than introducing a new write path.

## Edge semantics

| Edge kind | Source data | Meaning |
|---|---|---|
| `combo-sequence` | `comboMoves` adjacency | These moves *are* sequenced together |
| `aura-affinity` | `aura_links` (natural/neutral) | These moves transition naturally (candidate, not actual) |
| `deck-membership` | `deckMoves` | Grouped in the same deck |
| `annotation` | `notes`, `plans` | A reflection/plan attaches to a combo |

The discovery insight is the **gap between `aura-affinity` and `combo-sequence`**: a natural
affinity with no actual sequence = a combination worth trying. If `aura_links` is empty, discovery
falls back to co-occurrence (moves sharing combos/decks) so it still returns useful suggestions.

## Risks & mitigations

- **Layout drift when entities are deleted/renamed.** Layouts reference ids; a missing id renders as
  a tombstoned/ghost node rather than crashing, and is prunable. No entity is ever modified to keep a
  layout valid.
- **Force-directed jitter on large graphs.** Cap simulation iterations and freeze on settle; offer the
  static canvas as the calm alternative. Filtering by kind keeps the working set small.
- **Scope creep into a recommendation engine.** Discovery stays deterministic (graph set operations);
  no learned ranking in this change.

## Migration / rollout

Read-only by construction, so rollout is a UI addition behind the existing navigation. The only new
persistence (layouts) is additive and independently removable. No schema migration, no data
backfill, no destructive step.

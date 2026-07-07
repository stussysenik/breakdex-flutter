# Add the Discovery Graph & Spatial Canvas Interface

## Summary

Add a **discovery interface** to the Breakdex platform: the library is not just lists and
detail pages, but an explorable **graph** of moves, combos, notes, and plans — and a freeform
**spatial canvas** where the owner arranges those nodes by hand to think about the same data a
new way. On top of both sits a **combination-discovery** layer that surfaces moves the owner has
*never combined* but probably should (e.g. a natural aura affinity with no combo linking them).

The data is **already a graph** — `comboMoves` (sequence adjacency), `aura_links` (transition
affinity), `deckMoves` (grouping), `notes`/`plans` (annotations), and `reviews`/`fsrsCards`
(recall state) are all node↔node or node↔attribute relationships. This change renders and queries
that existing structure; it **adds no new storage engine**. The graph is a *view + query* concern,
computed client-side (in-memory, or SQLite recursive CTEs on the device) over the same manifest
the web mirror already reads.

This turns the tool into a **digital garden for breaking**: a surface for discovery, not just a
catalog — finding combinations you've never figured out.

## Motivation

- **The data is relational but only ever shown as flat lists.** The owner explicitly wants "a new
  perspective on the same information" — to "line up all things near each other" and "see all the
  relationships … in a graph view." The relationships exist (`comboMoves`, `aura_links`); they are
  simply never visualized.
- **Discovery, not just retrieval.** The desired outcome is finding *new* combinations — pairs of
  moves with a natural transition affinity that have never been sequenced together. That is a
  graph query over data we already have, not a feature that requires new infrastructure.
- **It composes with work already in flight.** The read-write foundation
  (`evolve-web-mirror-to-crud-platform`) and the labs/aura model (`add-labs-system`) provide the
  data and the mutation path; this change is the *exploratory view* over them.

## Architectural decision: no new graph database

We considered SurrealDB to back the graph. **Rejected for now.** The repo already commits to a
canonical backend (`add-beam-web-architecture-foundation`: Phoenix + Postgres + S3) plus Drift on
device and the Drive manifest on web. A graph *view* does not need a graph *store*: the node/edge
set is small (single-user library), the edges are already materialized as relational rows, and the
discovery queries are expressible in-memory or via SQLite recursive CTEs. Adding a fourth storage
engine would add operational and reconciliation complexity for no capability we cannot deliver as a
projection. See `design.md` for the revisit trigger.

## What Changes

- **Graph projection** — a pure function that builds a `{nodes, edges}` model from the existing
  manifest/DB (moves, combos, comboMoves, decks/deckMoves, aura_links, notes, plans), with typed
  node and edge kinds. No schema change; read-only over current data.
- **Discovery graph view** — an interactive node-edge rendering with a live force-directed layout
  (dynamic), filtering by node/edge kind, focus/neighborhood expansion, and click-through to the
  existing detail/playback surfaces.
- **Spatial canvas** — a freeform board where the owner drags nodes to arbitrary positions, groups
  them spatially, and **saves named layouts** (static). Layouts persist as additive data and never
  alter the underlying entities.
- **Combination discovery** — queries that surface "moves you've never combined" (candidate pairs
  with a natural aura affinity and no connecting `comboMove`), suggested combos, and isolated/orphan
  nodes, presented as actionable cards that can seed a new combo via the existing CRUD path.

## Capabilities

### New Capabilities

- `discovery-graph-projection`: Pure, read-only projection from the existing library data to a typed
  `{nodes, edges}` graph model. Defines node kinds (move, combo, note, plan, deck) and edge kinds
  (combo-sequence, aura-affinity, deck-membership, annotation) and how each maps from existing rows.
- `discovery-graph-view`: Interactive graph rendering with live force-directed layout, kind filters,
  focus/neighborhood navigation, and click-through to detail/playback. Read-only over the data.
- `spatial-canvas`: Freeform drag canvas with manual node positioning, spatial grouping, and saved
  named layouts persisted as additive data separate from the entities.
- `combination-discovery`: Queries and presentation that surface never-combined candidate pairs,
  suggested combos, and orphan nodes, each actionable into the existing combo-creation flow.

### Modified Capabilities

_None._ This change is purely additive: it reads existing data and adds a layout/preferences store.
It does not modify any existing capability's behavior.

## Relationship to existing changes

- **Builds on** `evolve-web-mirror-to-crud-platform` (read-write foundation + web shell) for the
  mutation path when a discovered combination is promoted into a real combo, and for the navigation
  shell it plugs into. This change does not require the full CRUD platform to ship a read-only graph.
- **Consumes** `add-labs-system`'s `aura_links` (move→move transition affinity) as the primary
  "natural transition" edge for discovery. If aura data is absent, discovery degrades gracefully to
  co-occurrence-based suggestions.
- **Does not overlap** `add-declarative-storage-truth-and-content-addressable-materialization`
  (filesystem determinism / cleanup) — that is tracked separately and is out of scope here.

## Data safety (production app with deployed data)

- **Read-first.** The graph projection, graph view, and discovery queries are strictly read-only
  over existing entities; they create, update, or delete nothing.
- **Additive persistence only.** Saved canvas layouts and view preferences are stored in a new,
  separate store (layout records keyed by id); they never mutate moves, combos, notes, or plans.
- **Promotion goes through existing CRUD.** Turning a discovered combination into a real combo uses
  the existing, guarded combo-creation path — no new write path that could bypass validation or
  reconciliation.

## Non-goals

- No new storage engine (no SurrealDB); no schema migration of existing entities.
- No filesystem/determinism cleanup (separate change).
- No fix for the videos-not-showing bug (tracked separately); the graph links to the existing
  playback surface and inherits whatever that surface provides.
- No AI/ML recommendation engine — discovery is deterministic graph queries, not learned ranking.

## Impact

- **Web** (`web-mirror/src/`): new graph-projection lib, graph-view and spatial-canvas components,
  a discovery panel, and a layout/preferences store (localStorage or the backend layout store from
  the CRUD foundation when available). Plugs into the existing section navigation.
- **Device (optional, later)**: the same projection can be computed from Drift via recursive CTEs if
  an in-app graph view is wanted; not required for the initial web-first slice.
- **No new dependencies required** beyond a force-directed layout helper (small, client-side) for
  the dynamic view.

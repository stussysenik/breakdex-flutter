# Tasks — Add the Discovery Graph & Spatial Canvas Interface

## 1. Graph projection (foundation, no UI)
- [x] 1.1 Define the graph model types (`Node` with kind/id/label, `Edge` with kind/source/target) in the web mirror lib
- [x] 1.2 Implement `projectGraph(manifest)` — pure function mapping moves/combos/comboMoves/decks/deckMoves/aura_links/notes/plans to `{nodes, edges}`
- [x] 1.3 Map edge kinds: `combo-sequence`, `aura-affinity`, `deck-membership`, `annotation`; omit kinds whose source data is absent
- [x] 1.4 Unit tests: read-only (input unchanged), deterministic (same input → same model), graceful degradation (missing aura/notes), node/edge kind coverage

## 2. Discovery graph view (dynamic)
- [x] 2.1 Add a force-directed layout helper (small client-side dependency or minimal in-house simulation) with iteration cap + settle-and-freeze
- [x] 2.2 Render nodes/edges from the projection; empty-state when the library has no nodes
- [x] 2.3 Filter controls by node kind and edge kind; recompute visible set on toggle
- [x] 2.4 Focus a node → emphasize it and its immediate neighborhood
- [x] 2.5 Click-through: selecting a node opens the existing detail/playback surface (reuse, don't fork)
- [x] 2.6 Verify in browser (`?demo=1`) that the demo manifest renders a stable, interactive graph

## 3. Spatial canvas (static)
- [x] 3.1 Freeform drag positioning of nodes; positions held in view state
- [x] 3.2 Define the layout record shape (id, name, `{entityId → position}`) — additive, references ids only
- [x] 3.3 Persist layouts (localStorage first; structure compatible with the CRUD platform's backend layout store for later migration)
- [x] 3.4 Save / reopen named layouts; restore saved positions
- [x] 3.5 Ghost/tombstone rendering for layout entries whose entity no longer exists, with prune action
- [x] 3.6 Tests: save→reopen round-trip; deleting a layout leaves entities intact; missing-entity → ghost (no crash)

## 4. Combination discovery
- [x] 4.1 Query: never-combined candidates = `aura-affinity` pairs minus `combo-sequence` pairs
- [x] 4.2 Fallback: when no aura data, derive candidates from co-occurrence (shared combo/deck)
- [x] 4.3 Query: orphan nodes (degree 0)
- [x] 4.4 Discovery panel UI presenting candidates and orphans as cards
- [x] 4.5 Promote action: open the existing combo-creation flow seeded with the candidate's moves
- [x] 4.6 Tests: already-combined pair excluded; affinity-with-no-combo included; fallback path; promotion routes through existing CRUD; read-only until promotion

## 5. Integration & verification
- [x] 5.1 Plug graph / canvas / discovery into the web mirror's existing section navigation
- [x] 5.2 Confirm strictly read-only over entities except the explicit promotion path
- [x] 5.3 End-to-end check on the demo fixture (✓ verified) — real-manifest pass deferred to owner sign-in
- [x] 5.4 `openspec validate add-discovery-graph-interface --strict --no-interactive` passes

## Notes
- **Promotion (4.5):** the read-only mirror has no combo-creation flow yet (CRUD platform is owner-gated),
  so "Make combo" routes through a parent callback (`onPromote`) and surfaces a non-mutating explainer
  naming the two moves. The wiring is ready to seed the real creation flow once editing is enabled on web.
- **Aura data:** the manifest does not export `aura_links` today, so the graph carries no `aura-affinity`
  edges and discovery uses the co-occurrence fallback (verified on the demo fixture). When the labs model
  lands, pass `auraLinks` to `projectGraph` in `Discover.tsx` — no other change needed.
- **Test runner:** added `vitest` (dev-only) + a `test` script to the web mirror; 21 tests passing.

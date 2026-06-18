# Tasks — Web Authoring Studio & Lifecycle Record

Risk-ordered. Phase 0 ships first (display only); writes wait on `shared-source-of-truth`.

## Phase 0 — Complete read surface (no write risk)
- [x] 0.1 Audit the current read path (`drive.ts`, `Mirror.tsx`, `VideoModal`) for entities/videos it does NOT yet render (sets/decks, notes, plans, archived items)
- [x] 0.2 Render all entity kinds in `/web`: moves, combos (in `sequenceIndex` order), sets/decks, notes, plans
- [x] 0.3 Ensure every video with a resolvable content hash is playable; log/surface any unresolved media instead of silently omitting it
- [x] 0.4 Verify against demo fixtures (`demo.ts`) and, when owner signs in, against real Drive data
- [x] 0.5 `next build` green + browser smoke (chrome-devtools) showing all videos and entities

## Phase 1 — Lifecycle & archive view (read of truth + history)
- [x] 1.1 Define the web view-model for an entity lifecycle timeline (events: created, edited, combined, reviewed, archived) — `src/lib/lifecycle.ts` (`LifecycleEvent`/`LifecycleTimeline`/`projectLifecycle`)
- [x] 1.2 Render a per-move and per-combo lifecycle timeline; degrade gracefully when no event history exists (reconstruct from manifest) — `EntityHistoryModal`; `reconstructed` flag surfaced; combo creation inferred from earliest member
- [x] 1.3 Render archived/deleted entities in a visually distinct, recoverable state (tombstones stay visible and playable) — strikethrough + ARCHIVED tag in Library/Combos; gated Recover affordance (un-archive is a Phase 2 verified write per design open-question)
- [x] 1.4 Tests: timeline projection (with and without event history); archived entity remains listed — `src/lib/lifecycle.test.ts` (6 tests)
- [x] 1.5 Verify a move marked archived in fixtures still appears and plays in `/web` — `h-headspin` archived move + archived combo `c2` in `sample-manifest.json`; browser smoke: lists, opens lifecycle, plays (0:03)

## Phase 2 — Composition write contract (gated on `shared-source-of-truth`)
- [ ] 2.1 Confirm `shared-source-of-truth` write-through + sync-status primitives are available; block Phase 2 until they are
- [ ] 2.2 Implement ordered-combo write ops (create, reorder, insert, remove) with contiguous `sequenceIndex` re-indexing
- [ ] 2.3 Validation: reject empty combo / duplicate sequence positions before any write
- [ ] 2.4 Implement set (deck) write ops; removing a move from a set must not archive the move
- [ ] 2.5 Implement video attach/detach as content-hash reference only (no blob mutation)
- [ ] 2.6 Wire optimistic UI + pending/saved/failed sync status; failed writes retry without losing edits
- [ ] 2.7 Implement recovery (un-archive) as a verified write recorded in the entity lifecycle
- [ ] 2.8 Tests: re-indexing integrity, validation rejections, attach-is-reference-only, verified-before-saved, retry-preserves-edit

## Phase 3 — Authoring studio tools
- [ ] 3.1 Build `/combo-builder`: move list, drag-to-order sequence, video attach, save via Phase 2 contract
- [ ] 3.2 Seed builder with `neverCombinedCandidates()` suggestions; seed an editable draft from a selected suggestion
- [ ] 3.3 Wire `combination-discovery` promotion to open `/combo-builder` seeded with the candidate's moves
- [ ] 3.4 Build `/set-builder`: assemble a deck with a live composition summary (size, category mix)
- [ ] 3.5 Ensure suggestions/analysis perform no writes until explicit save
- [ ] 3.6 Tests: builder save path, suggestion seeding, promotion-opens-seeded-builder, no-write-until-save
- [ ] 3.7 `next build` green + browser smoke of both builders end to end

## Validation
- [ ] V.1 `openspec validate add-web-authoring-and-lifecycle-studio --strict --no-interactive`
- [ ] V.2 Full web test suite (`npm test`) green
- [ ] V.3 Data-safety review: confirm no phase hard-deletes any entity, media, or lifecycle record

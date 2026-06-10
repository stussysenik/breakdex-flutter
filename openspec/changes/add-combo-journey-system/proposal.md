# Add Combo Journey System — Library, Planner, Journal & Data Hygiene

## Summary

Rebuild the Combos surface as a **journey tool**: a combo is *a sequence with a tag and a journal*. Three tabs (Library · Planned · Calendar) answer *what you have · what's next · when*. One changeable status tag (`idea → attempting → landed → clean`, the existing Labs vocabulary). One capture action: jot it down. Alongside the feature, harden the data layer: stale-folder elimination, Files-app deep links to the owning move, and real-time incremental loading everywhere (no stale UIs, no frozen 0% progress).

The design was converged through 13 interactive prototypes (`.superpowers/brainstorm/`, final: `13-three-tabs.html`).

## Motivation

- Combos today are a flat list with a notes blob. Breakers develop combos over months — imagination first (moves they can't do yet), evidence later. There is no longitudinal record, no planning, no honest progress.
- The append-only `combo_note_entries` table already exists but is underused; status vocabulary already exists on `labs`. This change composes existing primitives rather than inventing new ones.
- Production data is sacred: every schema change is additive; the journal is write-once.
- Known UX debt this change retires: video imports stuck at 0% progress, stale folders accumulating in `Documents/`, Files-app videos not linking back to their Breakdex move, list screens that don't react to DB changes.

## The Memorable Model

> **A combo is a sequence — with a tag and a journal.**
> **Library · Planned · Calendar = what you have · what's next · when.**
> **One tag: idea → attempting → landed → clean. One action: jot it down.**

## Scope

### In scope
- **Combo status tag** — single mutable `status` column on `combos`; every change auto-appends an immutable journal row
- **Combo journal** — jots (text + optional video *reference*) on the existing `combo_note_entries` ledger; strict 56/16/fluid log grid; fluid type by length
- **Practice planner** — `combo_plans` table; Planned tab (ordered queue with one-line *why*); Calendar tab (past heat + future dashed plans); plan from existing combos, from new combos at creation, or from the Planned tab
- **Library tab** — auto-grouped by creation month; preview = name + transition chain + tag (no dots)
- **Combo duplicate** — clone structure as a new `idea` sketch with provenance journal row
- **Video-by-reference picker** — "+ video" lists DB videos first (this combo's moves, recent takes); Photos import is last resort
- **Detail page cleanup** — title · chain · tag · player+step line · journal · jot box on screen; Plan/Duplicate/Edit/Share/Album/Delete behind ⋯
- **CTA & orientation pass** — one primary action per screen, FAB for create, ≥48dp targets, explicit screen headers
- **Storage hygiene** — eliminate stale folders/orphans deterministically and idempotently; diagnostics counters
- **Files deep link** — opening a Breakdex-owned video from the Files app opens the owning move (or combo step) directly
- **Real-time reactivity** — all combo surfaces driven by Drift streams; determinate, monotone progress for every sizable operation; zombie-code audit of replaced views
- **Schema v22 migration** — additive only; migration test proves data survival
- **Diagnostics** — StageLogger/DiagnosticsLog coverage on every new flow for physical-device debugging

### Out of scope
- Merged/stitched combo videos (combos compose per-move videos; no rendering)
- FSRS scheduling changes (planner is intentions, not SRS)
- Sync of plans/journal (rides existing sync later)
- Social/sharing beyond existing share sheet
- Deleting or rewriting any existing journal/notes data

## Capabilities

1. `combo-journey-data-model` — schema v22: `combos.status`, `combos.createdAt`, `combo_note_entries.kind/videoPath/videoHash`, new `combo_plans`; DAOs, streams, migration + tests
2. `combo-journey-ui` — three tabs, tag, journal grid, jot composer, library video picker, duplicate, detail cleanup, CTA/orientation rules
3. `practice-planner` — plan creation from three entry points, ordered queue, calendar planning, evidence-based completion
4. `storage-hygiene` — stale folder elimination, orphan handling, idempotent sweeps, diagnostics
5. `files-deeplink` — Files/Open-in → resolve by hash/filename → navigate to owning entity
6. `realtime-reactivity` — stream-driven UI contract, determinate progress contract, zombie-code retirement

## Dependencies

- Existing tables: `combos`, `combo_moves`, `combo_note_entries`, `moves`, `asset_manifest`, `provenance_events`
- Existing services: `StorageOrchestrator`, `VideoPathHealer`, `VideoPathResolver`, `CanonicalFolderService`, `VideoStorageGate`, `StageLogger`, `DiagnosticsLog`, blackbox service
- Existing widgets: `ComboStepLine`/`TimelineNode`, `RobustVideoPlayer`, `AppSegmentedControl`, `PracticeCalendarView` (pattern), `ActionTile`, `StatePill`
- Existing status vocabulary: `labs.status` (`idea/attempting/landed/clean`)
- Tooling: Flutter & Dart MCP for build/run/test; `ast-grep` for call-site verification and zombie-code audit; FlowDeck for device/simulator validation

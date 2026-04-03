# Add Labs System — Breaking Diary, Set Builder & Achievements

## Summary

Add a 5th **Labs** tab to Breakdex — a creative workspace where breakers develop moves over months, plan battle sets, earn achievements, and define their personal "Bboy Aura" (move transition style fingerprint).

## Motivation

Breaking moves often take months to develop. Breakdex currently tracks atomic moves and combos with SRS review, but lacks a dedicated space for longitudinal move development, set choreography, gamified progression, and personal style mapping.

## Scope

### In scope
- **Lab Projects** — Long-term move development tracking (timeline, milestones, daily log)
- **Set Builder** — Drag-drop battle round sequencer using Arsenal moves
- **Achievement Garden** — Forest-app-inspired gemstone tiers (Seed → Sprouting → Growing → Mastered)
- **Bboy Aura** — Personal move transition affinity graph with saveable style presets
- **Kanban Board** — Trello-style status columns (Idea/Attempting/Landed/Clean)
- **Schema v12 migration** — 7 new tables, export schema v8
- **Full test coverage** — DAO unit tests + Maestro stress tests

### Out of scope
- AI-powered move suggestions
- Social/sharing features
- Audio/beat integration for sets
- Sync of labs via iCloud (future work)

## Capabilities

1. `lab-data-model` — Database tables, DAOs, migration, providers
2. `lab-tab-ui` — 5th tab shell, list/board views, lab detail, quick log
3. `set-builder` — Drag-drop move sequencer with transition indicators
4. `achievement-garden` — Tier calculation, garden grid, unlock celebrations
5. `bboy-aura` — Affinity links, aura visualization, presets, set builder integration

## Dependencies

- Existing `moves`, `combos`, `fsrs_cards`, `reviews` tables
- Existing `NotesSection`, `StatePill`, `AppSegmentedControl`, `CelebrationOverlay` widgets
- Existing `combo_moves` join table pattern for `lab_moves`

# Tasks — Add Labs System

## Phase 1: Data Foundation
- [x] 1.1 Create table definitions (labs, milestones, lab_moves, lab_entries, achievements, aura_links, aura_presets) (completed in cab8ce1)
- [x] 1.2 Create DAOs (LabsDao, MilestonesDao, LabEntriesDao, AchievementsDao, AuraDao) with CRUD + watch streams (completed in cab8ce1)
- [x] 1.3 Schema v12 migration in database.dart with achievement backfill for existing moves (completed in cab8ce1)
- [x] 1.4 Riverpod providers for all entities (completed in cab8ce1)
- [x] 1.5 Unit tests for all 5 DAOs (CRUD, cascade deletes, watch streams, edge cases) (completed in cab8ce1)

## Phase 2: Lab Tab Shell
- [ ] 2.1 Add 5th tab to BottomNavShell + GoRouter (/lab route + branch)
- [ ] 2.2 Lab list view with project/set cards (status pill, progress bar, metadata)
- [ ] 2.3 Lab board view with kanban columns (Idea/Attempting/Landed/Clean)
- [ ] 2.4 Quick log input (always visible, optional project link)
- [ ] 2.5 List/Board toggle (reuse AppSegmentedControl)
- [ ] 2.6 Create lab flow (name, type selection, initial notes)

## Phase 3: Lab Detail + Set Builder
- [ ] 3.1 Lab detail screen (header, timeline, milestones, notes)
- [ ] 3.2 Set builder — horizontal drag-drop move sequencer
- [ ] 3.3 Set move cards with aura-based transition indicators
- [ ] 3.4 Linked moves section (drag Arsenal moves into lab)
- [ ] 3.5 Milestone list with completion toggle + dates

## Phase 4: Achievement Garden
- [ ] 4.1 Achievement tier calculation service (seed → sprouting → growing → mastered)
- [ ] 4.2 Achievement garden grid widget
- [ ] 4.3 Achievement tile with tier icon + unlock animation
- [ ] 4.4 Achievement unlock celebration (CelebrationOverlay integration)
- [ ] 4.5 Backfill existing moves on first migration run

## Phase 5: Bboy Aura
- [ ] 5.1 Aura link rating UI (natural/possible/stretch)
- [ ] 5.2 Aura radial visualization (personal style fingerprint)
- [ ] 5.3 Aura presets — save/switch style profiles
- [ ] 5.4 Set Builder integration — highlight natural-affinity next moves
- [ ] 5.5 Per-move aura view on move detail screen

## Phase 6: Testing + Polish
- [ ] 6.1 Maestro stress-lab-crud.yaml (rapid create/delete/rename)
- [ ] 6.2 Maestro stress-set-builder.yaml (rapid drag-drop, reorder)
- [ ] 6.3 Maestro stress-achievement-garden.yaml (rapid tier unlock cycles)
- [ ] 6.4 Spring animations (drops, unlocks, transitions)
- [ ] 6.5 Empty states for all views
- [ ] 6.6 Export schema v8 (labs + achievements + aura)

## Dependencies
- Phase 2 depends on Phase 1 (tables + providers needed for UI)
- Phase 3 depends on Phase 2 (lab detail is inside lab tab)
- Phase 4 can run parallel with Phase 3 (achievement is independent of lab UI)
- Phase 5 depends on Phase 1 (aura tables) but UI can parallel Phase 3
- Phase 6 depends on all others

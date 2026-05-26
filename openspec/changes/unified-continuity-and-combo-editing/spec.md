# OpenSpec: Unidirectional Data Flow & Unified Continuity

## Status
- **Status:** Implemented
- **Author:** Gemini CLI
- **Date:** 2026-05-26

## Overview
Breakdex currently suffers from logic fragmentation where storage orchestration, database updates, and UI states are loosely coupled. This proposal aims to enforce a unidirectional data flow by centering all CRUD operations around XState-inspired state machines. These machines will act as the "single source of truth" for complex operations, ensuring that the filesystem (iOS folders) and database (SQLite) are always in sync.

Furthermore, the user experience in the Combo view will be enhanced to allow drilling down into individual moves, fixing the "continuity gap" where individual steps cannot be inspected or edited from within a sequence.

## Goals
1.  **Enforce Unidirectional Flow:** Center all data mutations (CRUD) in state machines.
2.  **Harmonize Storage & DB:** Ensure storage orchestration (hashed IDs, semantic folders) is a core part of the state transition logic.
3.  **Enhance Combo UX:** Allow navigating to and editing individual moves from the Combo Detail screen.
4.  **UI Polish:** Standardize primary/secondary text styles and typing for a "vibe-coded" professional look.

## Architecture Decisions

### 1. State Machine Ownership of CRUD
Complex operations (e.g., creating a move, renaming a category, editing a combo step) will be managed by specific machines in `lib/core/state_machines`.
- **Logic Chain:** UI Event -> Machine Event -> State Transition + Storage/DB Side Effects -> UI State Update.
- **Side Effects:** Machines will use the `StorageOrchestrator` and `BlackboxService` to ensure physical consistency.

### 2. Move Detail Drill-down from Combos
- The `ComboDetailScreen` will be updated to make individual steps clickable.
- Tapping a step will navigate to `/moves/{moveId}`, allowing the user to edit the move's metadata or video.
- **Continuity:** When the user returns from Move Detail, the Combo view should refresh to reflect the changes.

### 3. Vibe-Coded UI Standards
- **Primary Text:** `AppTypography.titleLarge` or `AppTypography.bodyMedium` with `onSurface` color.
- **Secondary Text:** `AppTypography.bodySmall` or `AppTypography.caption` with `secondary` (muted) color.
- **Interaction Feedback:** Haptic feedback for all machine-driven transitions.

## Implementation Plan

### Phase 1: Storage-Enforced State Machines
- [ ] Refactor `MoveDetailNotifier` to use a more robust `MoveDetailMachine`.
- [ ] Ensure `MoveDetailMachine` handles video edits and category changes using `StorageOrchestrator`.
- [ ] Refactor `ComboDetailScreen` logic into a `ComboDetailMachine` (if needed) or consolidate its mutation logic.

### Phase 2: Combo Detail Enhancements
- [ ] Update `lib/features/combo_detail/combo_detail_screen.dart` to make individual moves clickable.
- [ ] Implement navigation from Combo step to Move Detail.
- [ ] Ensure "Individual Beats" are clearly visible and editable.

### Phase 3: Final Polish
- [ ] Audit all screens for primary/secondary text contrast.
- [ ] Verify that `BlackboxService` captures all critical transitions.

## Verification
- **Automated:** Update Maestro flows to verify navigation from Combo -> Move Detail -> Edit -> Combo.
- **Manual:** Verify physical folder structure in the iOS simulator after these operations.

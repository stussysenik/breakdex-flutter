## Why

The move detail page (and all CRUD surfaces) currently uses imperative `showDialog`/`showModalBottomSheet` calls with no mutual exclusion, no saving feedback, inconsistent confirmation patterns, and a missing confirmation on log entry deletion. The system operates as independent imperative functions with no shared guard — dialogs can theoretically stack, stream rebuilds can interfere with editing state, and 23 distinct loopholes exist across the CRUD surfaces. Additionally, the canonical reconciliation service generates spurious "restored moves" notifications due to a logic gap in orphan recovery.

The app is single-user, single-device — a closed system where all events originate from user interaction. This means we can model it as a closed hierarchical state machine where every state is explicit, every transition is guarded, and impossible states are unrepresentable at compile time via Dart sealed classes.

## What Changes

- **State machine infrastructure**: Build a zero-dependency sealed-class state machine framework (`Machine<S, E>`) with pure transition functions, entry/exit actions for side effects, and hierarchical child state composition
- **Replace `DeleteStateMachine`**: Rewrite the existing enum+StreamController `DeleteStateMachine` (`lib/core/services/delete_state_machine.dart`) with the sealed class pattern for consistency
- **Move detail state machine**: Model all 17 CRUD states (idle, renaming, validatingName, nameConflict, savingName, albumSyncFailed, changingState, savingState, changingCategory, savingCategory, changingCount, savingCount, confirmingDelete, deleting, gone, confirmingRemoveVideo, removingVideo, pickingVideo, savingVideo, addingLog, savingLog, confirmingDeleteLog, deletingLog) with explicit transitions
- **Move list state machine**: Model list-level CRUD (confirmingDelete, deleting) and parameterized filtering
- **Add screen state machine**: Model move/combo creation with validation states
- **Trash/Restore state machine**: Replace existing DeleteStateMachine with sealed class pattern; add discoverable navigation transitions
- **Inline dialog overlays**: Replace `showDialog`/`showModalBottomSheet` with `Stack`-based overlays controlled by machine state — no Navigator route leaks, lifecycle tied to widget tree
- **Notes/Photos explicit dirty state**: Debounced auto-save modeled as a transient dirty sub-state in the idle machine
- **Log entry delete confirmation**: Add confirmation dialog for log entry deletion (currently immediate, no guard)
- **Delete confirmation accuracy**: Surface the full cascade (reviews, achievements, log entries, aura links) in the delete confirmation dialog
- **Fix restored moves bug**: Address spurious "restored" notifications in `canonical_reconcile_service.dart` / `video_reliability_runtime.dart`

## Capabilities

### New Capabilities

- `state-machine-core`: Zero-dependency sealed-class state machine framework. `Machine<S, E>` base class with pure `transition(S, E) -> S?` function, entry/exit action hooks, hierarchical child composition, and Riverpod provider integration
- `move-detail-crud`: Move detail screen governed by a state machine with 17 explicit states, mutex-guarded transitions, saving feedback, and inline overlay dialogs
- `move-list-crud`: Move list screen with guarded delete workflow and parameterized filtering hooks
- `add-screen-crud`: Add/create screen with explicit validation states for move and combo creation
- `trash-restore-crud`: Trash/restore screen replacing the existing DeleteStateMachine with sealed class pattern
- `log-entry-confirmation`: Confirmation dialog for log entry deletion (currently missing)
- `restored-moves-fix`: Fix spurious restored moves notifications in canonical reconciliation

### Modified Capabilities

None — no existing specs to modify.

## Impact

- `lib/core/state_machines/` — new directory (core machine, per-screen machines, providers)
- `lib/features/move_detail/move_detail_screen.dart` — rewrite dialog logic to consume machine state with inline overlays
- `lib/features/move_list/move_list_screen.dart` — integrate machine for delete workflow
- `lib/features/add/add_screen.dart` — integrate machine for creation workflow
- `lib/features/settings/canonical_trash_screen.dart` — consume new trash machine
- `lib/core/services/delete_state_machine.dart` — replaced (deleted)
- `lib/core/services/canonical_reconcile_service.dart` — fix restored moves logic
- `lib/core/providers.dart` — add machine providers
- `lib/shared/widgets/action_tile.dart` — may add state-aware variant
- No new dependencies (pure Dart sealed classes)
- **BREAKING**: `DeleteStateMachine` class removed; all consumers must migrate to new `TrashMachine`

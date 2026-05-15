## Context

The app currently handles CRUD operations through imperative `showDialog`/`showModalBottomSheet` calls scattered across screen widgets. Each dialog is an independent Navigator route with no shared guard, no mutual exclusion, and inconsistent patterns. The existing `DeleteStateMachine` (enum + StreamController, 212 lines) handles only asset-level delete/restore for canonical storage — not UI-level CRUD.

23 loopholes were identified by exhaustively enumerating the state space of the move detail page alone:
- No mutual exclusion between modal operations
- Log entry delete has zero confirmation
- Rename has no saving feedback
- Delete confirmation lies about cascade scope
- Dialogs survive widget disposal (Navigator route leak)
- Album sync failures are invisible
- Notes/photos auto-save unbounded
- No recovery path for partial failures

The system is single-user, single-device — a **closed machine** where all events originate from user interaction. No websocket interrupts, no external actors. This makes a pure state machine viable without distributed-system complexity.

**Constraints:**
- Must integrate with existing Riverpod providers and Drift repositories
- Must not add external dependencies (pure Dart sealed classes)
- Must not break existing navigation (GoRouter)
- Must co-exist with existing stream-based reactivity for non-modal state (read path)

## Goals / Non-Goals

**Goals:**
- Replace all imperative dialog logic with state-machine-governed inline overlays
- Make every destructive action require explicit confirmation
- Provide saving/loading feedback for every async operation
- Prevent impossible states at compile time via Dart sealed classes
- Consistent visual pattern: editing states vs destructive states vs idle
- Fix the spurious "restored moves" notification bug
- Replace existing `DeleteStateMachine` with same sealed-class pattern

**Non-Goals:**
- Replace Riverpod or GoRouter as the app's state management / navigation layer
- Add real-time collaboration or websocket-aware conflict resolution
- Implement undo/redo history (deferred to follow-up)
- Change the database schema or migration strategy
- Build a visual state machine editor or debugger tool

## Decisions

### Decision 1: Zero-Dependency Sealed Class Machine

**Chosen**: Build `Machine<S, E>` using Dart 3 sealed classes + pattern matching.

**Alternatives considered:**
- `statemachine` package (3.4.0, 12k downloads): Adds a dependency for a pattern the language already supports. The package's callback-based API (`onEntry`, `onExit`) mixes side effects into state definitions, violating data-oriented separation.
- `saga_state_machine` (1.1.2, MassTransit-style): Designed for distributed sagas with event correlation and persistence. Overkill for a single-user Flutter app.
- Keep current enum + StreamController pattern: Works for simple cases but doesn't scale to hierarchical states or compile-time exhaustiveness checking.

**Rationale**: Dart sealed classes provide compile-time exhaustiveness — the compiler verifies that every state is handled in every `switch`. Pattern matching makes the transition function a pure expression. No runtime overhead beyond what the language already provides.

**Core API:**
```dart
abstract class Machine<S, E> {
  S get state;
  void send(E event);
  S? transition(S state, E event); // Pure — no side effects
  void onEntry(S state);  // Side effects after transition
  void onExit(S state);   // Cleanup before transition
}
```

### Decision 2: Inline Overlays Instead of Navigator Dialogs

**Chosen**: Render dialogs as `Stack` overlays within the screen widget tree, visibility gated by machine state.

**Rationale**: `showDialog` pushes a new `Navigator` route that:
- Survives widget disposal (callbacks hold stale `ref`/`context`)
- Can stack indefinitely (multiple dialogs can be active)
- Has independent lifecycle from the parent widget
- Uses `barrierDismissible: true` by default (accidental cancel)

Inline overlays tie the dialog lifecycle to the widget tree. When the screen is disposed, the overlay is disposed. When the machine transitions away from a dialog state, the overlay is removed. No route leaks, no stale references.

**Pattern:**
```dart
Stack(
  children: [
    // Main content
    ListView(...),
    // State-gated overlay
    if (state is Renaming)
      _RenameOverlay(state.draftName, onSave: (name) => machine.send(SaveName(name))),
    if (state is ConfirmingDelete)
      _DeleteConfirmOverlay(onConfirm: () => machine.send(Confirm())),
  ],
)
```

### Decision 3: Global Machine with Hierarchical Child States

**Chosen**: A root `AppMachine` owns child machines for each CRUD surface. The root routes events to the active child based on navigation context.

**Rationale**: "All CRUD surfaces" implies cross-screen coordination. When a move is deleted from the detail screen, the list screen must reflect the deletion. When a move is renamed, the combo creator must see the new name. A hierarchical machine centralizes event routing while keeping per-screen state encapsulated.

**Structure:**
```
AppMachine
├── MoveListMachine (viewing, confirmingDelete, deleting)
├── MoveDetailMachine (idle, renaming, validatingName, ..., gone)
├── AddMachine (choosingType, creatingMove, validatingMove, savingMove, ...)
├── TrashMachine (viewing, confirmingRestore, restoring, confirmingPurge, purging)
└── ComboDetailMachine (viewing, renaming, addingMoves, confirmingDelete, ...)
```

**Event routing**: The root machine tracks which screen is active (from GoRouter location). Events are dispatched to the root, which delegates to the active child. Invalid events (e.g., `TapDelete` while `MoveDetailMachine` is in `renaming` state) are silently ignored by the child.

### Decision 4: Notes/Photos as Explicit Dirty Sub-State

**Chosen**: Notes and photos editing creates a transient `dirty` sub-state in the `idle` machine with a debounce timer. The machine tracks whether unsaved changes exist.

**Rationale**: Without explicit dirty state, there's no way to:
- Show "unsaved changes" indicator
- Prevent navigation away with unsaved data
- Batch multiple rapid edits into a single save
- Handle save failures with retry

The dirty state auto-transitions to `saving` after 500ms of inactivity, then back to `idle` (or `dirty` if more edits arrive during save).

### Decision 5: Side Effects as Entry Actions

**Chosen**: Database writes, album sync, media cleanup, and video import hooks execute as entry actions of the state they belong to. The action completes and sends a result event (`SaveSucceeded` / `SaveFailed`).

**Rationale**: XState's "invoke" pattern: the state machine dispatches an async operation on state entry, and the operation's result is fed back as an event. The machine remains in the state until the result event arrives. This is the "feedback loop" — the machine owns the async lifecycle.

**Example:**
```dart
// In transition function:
(Idle(), SaveName(name: var n)) => SavingName(move, newName: n),

// In onEntry for SavingName:
case SavingName(:final move, :final newName):
  _repository.update(MovesCompanion(id: Value(move.id), name: Value(newName)))
    .then((_) => send(SaveSucceeded()))
    .catchError((e) => send(SaveFailed(e.toString())));

// Transition:
(SavingName(), SaveSucceeded()) => Idle(updatedMove),
(SavingName(), SaveFailed(error: var e)) => Error(move, message: e),
```

### Decision 6: Restored Moves Fix

**Root cause**: The `video_reliability_runtime.dart` cold-start check reports restored videos as "restored moves" to the user. The reconciliation logic in `canonical_reconcile_service.dart` recovers DB entries for locally-present files, but the notification conflates "video file restored" with "move restored."

**Fix**: Add a distinction between "video-only restoration" (file exists, move doesn't) and "move restoration" (move was soft-deleted and is being restored). The notification should only fire for actual move restoration, not cold-start video recovery.

## Risks / Trade-offs

- **[Inline overlays vs native feel]**: Stack-based overlays don't use the platform's dialog transition animations. Mitigation: Apply `AnimatedOpacity` and `AnimatedScale` to match Material dialog feel.
- **[Machine complexity]**: 17 states per screen × 5 screens = ~85 states to model. Mitigation: Build incrementally — move detail first, validate pattern, then expand.
- **[Stream conflict during save]**: If a stream update arrives during a `saving*` state, the machine ignores it. When returning to `idle`, the stream naturally picks up the latest data. Risk: If two saves happen in rapid succession, the second save's snapshot might be stale. Mitigation: Re-read from DB before applying the second save (optimistic concurrency check).
- **[Hierarchical machine overhead]**: A global machine adds indirection. Mitigation: The root machine is lightweight — just routing. Per-screen machines handle their own state. Communication between screens uses existing Riverpod invalidation.

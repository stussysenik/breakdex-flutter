## ADDED Requirements

### Requirement: Machine base class with pure transition function
The system SHALL provide a generic `Machine<S, E>` base class where `S` is a sealed class of states and `E` is a sealed class of events. The machine SHALL expose a pure `transition(S, E) -> S?` function that returns the next state or `null` (identity transition — event ignored). The machine SHALL NOT execute side effects inside the transition function.

#### Scenario: Valid transition
- **WHEN** machine is in state `Idle` and receives event `TapRename`
- **THEN** transition returns `Renaming` state

#### Scenario: Invalid transition ignored
- **WHEN** machine is in state `Renaming` and receives event `TapDelete`
- **THEN** transition returns `null` and machine stays in `Renaming`

#### Scenario: Compile-time exhaustiveness
- **WHEN** a new state variant is added to the sealed class hierarchy
- **THEN** the compiler SHALL error on any `switch` that doesn't handle the new variant

### Requirement: Entry and exit action hooks
The machine SHALL invoke `onEntry(S)` after transitioning to a new state and `onExit(S)` before leaving the current state. Side effects (DB writes, album sync, navigation) SHALL execute exclusively in entry/exit actions.

#### Scenario: Entry action executes DB write
- **WHEN** machine enters `SavingName` state via `SaveName` event
- **THEN** `onEntry` dispatches the DB update and the machine remains in `SavingName` until result event arrives

#### Scenario: Exit action cleans up
- **WHEN** machine leaves `Renaming` state via `Cancel` event
- **THEN** `onExit` discards any draft text state

### Requirement: Result event feedback loop
Async operations started in entry actions SHALL feed their result back to the machine as events (`SaveSucceeded`, `SaveFailed`). The machine SHALL NOT accept user input events while an async operation is in progress.

#### Scenario: Save succeeds
- **WHEN** machine is in `SavingName` and DB write completes successfully
- **THEN** `SaveSucceeded` event is sent, machine transitions to `Idle` with updated move data

#### Scenario: Save fails
- **WHEN** machine is in `SavingName` and DB write throws an error
- **THEN** `SaveFailed` event is sent with error message, machine transitions to `Idle` with error surfaced to user

### Requirement: Hierarchical child state composition
A machine SHALL support registering child machines. Events sent to the parent SHALL be delegated to the active child machine. Parent SHALL track which child is currently active based on navigation context.

#### Scenario: Event delegation to active child
- **WHEN** parent machine has `MoveDetailMachine` as active child and receives `TapRename`
- **THEN** parent delegates event to `MoveDetailMachine` which transitions to `Renaming`

#### Scenario: Event ignored when no child active
- **WHEN** parent machine has no active child and receives `TapRename`
- **THEN** event is silently ignored

### Requirement: Riverpod provider integration
The system SHALL expose each machine through a Riverpod `StateNotifierProvider` or `NotifierProvider`. Widgets SHALL read machine state via `ref.watch(machineProvider)` and dispatch events via `ref.read(machineProvider).send(event)`.

#### Scenario: Widget reacts to state change
- **WHEN** machine transitions from `Idle` to `Renaming`
- **THEN** watching widget rebuilds and renders the rename overlay

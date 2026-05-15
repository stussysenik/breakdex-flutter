## ADDED Requirements

### Requirement: All CRUD operations gated by machine state
The move detail screen SHALL render modal surfaces (rename dialog, delete confirmation, state picker, category picker, count editor, video picker, log entry dialog) as inline `Stack` overlays whose visibility is controlled by the machine state. No operation SHALL use `showDialog` or `showModalBottomSheet`.

#### Scenario: Rename dialog appears when machine enters Renaming
- **WHEN** user taps "Rename" ActionTile
- **THEN** machine transitions to `Renaming` state and an inline rename overlay appears

#### Scenario: Rename dialog dismissed on cancel
- **WHEN** user taps "Cancel" in rename overlay
- **THEN** machine transitions to `Idle` and overlay is removed

### Requirement: Mutual exclusion of modal operations
The machine SHALL ignore all action-intent events (`TapRename`, `TapDelete`, `TapChangeState`, `TapChangeCategory`, `TapChangeCount`, etc.) when in any non-`Idle` state. Only one modal SHALL be visible at any time.

#### Scenario: Delete tap ignored while renaming
- **WHEN** machine is in `Renaming` state
- **THEN** tapping "Delete Move" SHALL have no effect

#### Scenario: Rename tap ignored while confirming delete
- **WHEN** machine is in `ConfirmingDelete` state
- **THEN** tapping "Rename" SHALL have no effect

### Requirement: Destructive actions require explicit confirmation
Every destructive action SHALL require a `Confirming*` intermediate state before execution. Destructive actions include: delete move, remove video, delete log entry.

#### Scenario: Delete move confirmation
- **WHEN** user taps "Delete Move"
- **THEN** machine transitions to `ConfirmingDelete` with a confirmation overlay showing the full cascade scope (reviews, achievements, log entries, aura links)

#### Scenario: Delete move cancellation
- **WHEN** user taps "Cancel" in delete confirmation
- **THEN** machine transitions back to `Idle`

### Requirement: Saving state with loading feedback
All async save operations SHALL have a dedicated `Saving*` state that renders a loading indicator. The machine SHALL remain in the `Saving*` state until the async operation completes or fails.

#### Scenario: Rename save shows loading
- **WHEN** user taps "Save" in rename overlay with a valid new name
- **THEN** machine transitions to `ValidatingName`, then `SavingName` which shows a loading indicator, then `Idle` on success

#### Scenario: Rename save fails with error
- **WHEN** rename DB write fails
- **THEN** machine transitions to `Idle` with error surfaced via SnackBar

### Requirement: Name conflict detection
When renaming, the machine SHALL validate the new name against existing moves and combos via `ReviewableNamingService.isNameTaken`. If the name is taken, the machine SHALL enter `NameConflict` state showing an inline error.

#### Scenario: Name already exists
- **WHEN** user enters a name that matches an existing move or combo name
- **THEN** machine transitions to `NameConflict` with error message shown inline in the rename overlay

#### Scenario: User retries after conflict
- **WHEN** user edits the name in `NameConflict` state
- **THEN** machine transitions back to `Renaming` to allow retry

### Requirement: Album sync as explicit state
When a rename or category change triggers album copy synchronization, the machine SHALL enter an `AlbumSyncFailed` state if the sync fails, with a retry option. The DB write SHALL have already succeeded; only the album is out of sync.

#### Scenario: Album sync fails after rename
- **WHEN** rename DB write succeeds but album copy operation fails
- **THEN** machine transitions to `SavingName` then detects album failure, enters `AlbumSyncFailed` with retry action

#### Scenario: Album sync retry
- **WHEN** user taps "Retry" in `AlbumSyncFailed` state
- **THEN** machine re-attempts album sync and transitions to `Idle` on success

### Requirement: Count editor with min/max bounds
The count editor SHALL enforce bounds of 1–16 with disabled buttons at limits and a clear visual lock indication.

#### Scenario: Count at minimum
- **WHEN** count is 1 and user opens count editor
- **THEN** decrement button is disabled with reduced opacity

#### Scenario: Count at maximum
- **WHEN** count is 16 and user opens count editor
- **THEN** increment button is disabled with reduced opacity

### Requirement: State picker integrated with machine
The state picker sheet SHALL be governed by `ChangingState` state in the machine with cancel/confirm transitions.

#### Scenario: State change confirmed
- **WHEN** user selects a new state and taps confirm
- **THEN** machine transitions to `SavingState`, writes to DB, then returns to `Idle`

### Requirement: Category picker integrated with machine
The category picker sheet SHALL be governed by `ChangingCategory` state. On save, it SHALL sync the album copy (similar to rename).

#### Scenario: Category changed
- **WHEN** user selects a new category and confirms
- **THEN** machine transitions to `SavingCategory`, writes to DB, syncs album, then returns to `Idle`

### Requirement: Video management states
Adding, editing, removing, and sharing video SHALL each have explicit machine states. `PickingVideo`, `SavingVideo`, `ConfirmingRemoveVideo`, and `RemovingVideo` SHALL be distinct states with appropriate guards.

#### Scenario: Remove video confirmation
- **WHEN** user taps "Remove Video"
- **THEN** machine transitions to `ConfirmingRemoveVideo` with confirmation overlay

#### Scenario: Video removed
- **WHEN** user confirms remove video
- **THEN** machine transitions to `RemovingVideo`, runs media cleanup, clears video columns, then returns to `Idle`

### Requirement: Log entry delete confirmation
Deleting a log entry SHALL require a `ConfirmingDeleteLog` intermediate state with a confirmation dialog.

#### Scenario: Log entry delete confirmed
- **WHEN** user taps X on a log entry, then confirms in the overlay
- **THEN** machine transitions to `DeletingLog`, deletes the entry, refreshes the log list

#### Scenario: Log entry delete cancelled
- **WHEN** user taps X on a log entry, then cancels in the overlay
- **THEN** machine returns to `Idle` with no deletion

### Requirement: Notes and photos dirty state
Editing notes or photos SHALL transition the machine to a `dirty` sub-state within `Idle`. After 500ms of inactivity, the machine SHALL auto-save and return to clean `Idle`. The dirty state SHALL prevent navigation away without saving.

#### Scenario: Notes edited triggers dirty state
- **WHEN** user types in the notes field
- **THEN** machine enters `NotesDirty` sub-state with unsaved indicator

#### Scenario: Notes auto-save after debounce
- **WHEN** user stops typing for 500ms
- **THEN** machine transitions to `SavingNotes`, writes to DB, then returns to clean `Idle`

### Requirement: Gone state triggers navigation
When a move is successfully deleted, the machine SHALL enter `Gone` state. On entry to `Gone`, the machine SHALL trigger `context.pop()` to navigate back.

#### Scenario: Move deleted, navigate back
- **WHEN** machine enters `Gone` state
- **THEN** the screen navigates back to the previous route

### Requirement: Stream updates only consumed in Idle
The database stream SHALL only update the machine's move context when the machine is in `Idle` state. During all other states, stream updates SHALL be ignored.

#### Scenario: Stream ignored during edit
- **WHEN** machine is in `Renaming` and the move stream emits an update
- **THEN** the update is ignored and the rename dialog shows the snapshotted name

#### Scenario: Stream applied after edit completes
- **WHEN** machine transitions from `SavingName` to `Idle`
- **THEN** the move context is refreshed from the database stream

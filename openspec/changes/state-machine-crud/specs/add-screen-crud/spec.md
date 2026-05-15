## ADDED Requirements

### Requirement: Type selection as explicit state
The add screen SHALL enter a `ChoosingType` state where the user selects between creating a move or a combo. The machine SHALL NOT proceed to creation until a type is chosen.

#### Scenario: Type selected
- **WHEN** user selects "Move" in the type picker
- **THEN** machine transitions to `CreatingMove` state with the move creation form

#### Scenario: Type cancelled
- **WHEN** user dismisses the type picker
- **THEN** machine returns to idle and navigates back

### Requirement: Name validation during creation
The creation form SHALL validate the name against existing moves and combos using `ReviewableNamingService.isNameTaken`. Name conflicts SHALL show inline errors with a `NameConflict` state.

#### Scenario: Duplicate name detected
- **WHEN** user enters a name that already exists
- **THEN** machine transitions to `NameConflict` with inline error, preventing save

#### Scenario: User corrects name
- **WHEN** user edits the name in `NameConflict` state
- **THEN** machine transitions back to `CreatingMove` to retry

### Requirement: Saving state with progress
The creation SHALL enter a `SavingMove` or `SavingCombo` state with loading feedback. The machine SHALL remain in saving state until the DB write and video import complete.

#### Scenario: Move created successfully
- **WHEN** machine is in `SavingMove` and DB write succeeds
- **THEN** machine transitions to `Idle` and navigates to the new move's detail screen

#### Scenario: Creation fails
- **WHEN** machine is in `SavingMove` and DB write fails
- **THEN** machine transitions to `Error` state with error message and retry option

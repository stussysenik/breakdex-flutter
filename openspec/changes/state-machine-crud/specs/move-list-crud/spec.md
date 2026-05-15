## ADDED Requirements

### Requirement: Delete confirmation for moves in list
Tapping delete on a move in the list SHALL trigger a `ConfirmingDelete` state with an inline confirmation overlay showing the move name and cascade scope.

#### Scenario: Delete confirmed from list
- **WHEN** user taps delete on a list item, then confirms
- **THEN** machine transitions to `Deleting`, removes the move and its media, then refreshes the list

#### Scenario: Delete cancelled from list
- **WHEN** user taps delete on a list item, then cancels
- **THEN** machine returns to viewing state with no changes

### Requirement: No concurrent deletes
The machine SHALL ignore additional `TapDelete` events while in `ConfirmingDelete` or `Deleting` states.

#### Scenario: Second delete ignored
- **WHEN** machine is in `Deleting` state and user taps delete on another item
- **THEN** event is ignored

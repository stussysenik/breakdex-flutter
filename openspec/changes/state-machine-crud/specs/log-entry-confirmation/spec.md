## ADDED Requirements

### Requirement: Confirmation before deleting log entry
Tapping the close/dismiss button on a log entry SHALL trigger a `ConfirmingDeleteLog` state with an inline confirmation overlay. The log entry SHALL NOT be deleted until the user explicitly confirms.

#### Scenario: Log entry deletion confirmed
- **WHEN** user taps X on a log entry, then taps "Delete" in the confirmation overlay
- **THEN** the entry is permanently deleted from the database

#### Scenario: Log entry deletion cancelled
- **WHEN** user taps X on a log entry, then taps "Cancel" in the confirmation overlay
- **THEN** the entry remains and the overlay is dismissed

#### Scenario: No confirmation for other actions during confirmation
- **WHEN** the `ConfirmingDeleteLog` overlay is visible
- **THEN** no other modal actions (rename, delete move, etc.) can be triggered

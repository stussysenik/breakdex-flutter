## ADDED Requirements

### Requirement: Duplicate Detection
The app SHALL detect and display duplicate media files (same content hash).

#### Scenario: User views duplicates tab
- **GIVEN** the user is on the Media Manager screen
- **WHEN** they view the Duplicates tab
- **THEN** duplicate groups are shown as cards
- **AND** each card shows the files with the same content hash

#### Scenario: User resolves duplicates
- **GIVEN** the user is viewing a duplicate group
- **WHEN** they tap "Keep one"
- **THEN** the most-recently-used file is kept
- **AND** the other duplicates are deleted (with cloud backup verification)
- **AND** a snackbar shows "Duplicates resolved"

#### Scenario: No duplicates exist
- **GIVEN** the user is on the Media Manager screen
- **WHEN** they view the Duplicates tab
- **AND** no duplicates exist
- **THEN** an empty state shows "No duplicates found"

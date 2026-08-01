## ADDED Requirements

### Requirement: Media Manager Screen
The app SHALL provide a dedicated Media Manager screen accessible from Settings.

#### Scenario: User opens Media Manager
- **GIVEN** the user is on the Settings screen
- **WHEN** they tap "Media Manager"
- **THEN** the Media Manager screen opens with three tabs: Videos, Photos, Duplicates
- **AND** the screen shows stats header: "X files, Y MB, Z% cloud-backed"

### Requirement: Media Grid Display
The app SHALL display all app-owned media in a grid layout with thumbnails and metadata.

#### Scenario: User views video assets
- **GIVEN** the user is on the Media Manager screen
- **WHEN** they view the Videos tab
- **THEN** each video shows as a grid item with thumbnail, file name, size, and status icon
- **AND** status icons indicate: cloud-backed (cloud icon), local-only (device icon), orphaned (warning icon)

#### Scenario: User views photo assets
- **GIVEN** the user is on the Media Manager screen
- **WHEN** they view the Photos tab
- **THEN** each photo shows as a grid item with thumbnail, file name, size, and associated move name
- **AND** photos are loaded from the .photos/ directory

### Requirement: Search and Filter
The app SHALL allow users to search and filter media by various criteria.

#### Scenario: User searches for a file
- **GIVEN** the user is on the Media Manager screen
- **WHEN** they type in the search bar
- **THEN** the grid filters in real-time by file name, entity name, or content hash

#### Scenario: User filters by backup status
- **GIVEN** the user is on the Media Manager screen
- **WHEN** they tap the "Local Only" filter chip
- **THEN** only files without cloud backup are shown

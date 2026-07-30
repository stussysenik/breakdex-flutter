## ADDED Requirements

### Requirement: File Location Navigation
The app SHALL allow users to navigate to the file location in the system file browser.

#### Scenario: User taps "Show in Files" on iOS
- **GIVEN** the user has selected a media file
- **WHEN** they tap "Show in Files"
- **THEN** the system file browser opens to the file's location
- **AND** the file is highlighted/selected

#### Scenario: User taps "Show in Files" on Android
- **GIVEN** the user has selected a media file
- **WHEN** they tap "Show in Files"
- **THEN** the system file manager opens to the file's directory

### Requirement: Share File
The app SHALL allow users to share media files via the native share sheet.

#### Scenario: User shares a file
- **GIVEN** the user has selected a media file
- **WHEN** they tap "Share"
- **THEN** the native share sheet opens with the file attached
- **AND** the user can share via AirDrop, Messages, Mail, etc.

### Requirement: Copy File Path
The app SHALL allow users to copy the file path to clipboard.

#### Scenario: User copies file path
- **GIVEN** the user has selected a media file
- **WHEN** they tap "Copy Path"
- **THEN** the file path is copied to clipboard
- **AND** a snackbar shows "Path copied"

### Requirement: Delete File
The app SHALL allow users to delete media files with safety checks.

#### Scenario: User deletes a cloud-backed file
- **GIVEN** the user has selected a media file with cloud backup
- **WHEN** they tap "Delete" and confirm
- **THEN** the local file is deleted
- **AND** the asset remains in the manifest (can be re-downloaded)

#### Scenario: User attempts to delete a local-only file
- **GIVEN** the user has selected a media file without cloud backup
- **WHEN** they tap "Delete"
- **THEN** a warning dialog shows "This file has no cloud backup. Delete anyway?"
- **AND** the user must confirm to proceed

#### Scenario: User attempts to delete an actively-used file
- **GIVEN** the user has selected a media file currently used by a move/combo
- **WHEN** they tap "Delete"
- **THEN** a warning dialog shows "This file is used by [entity name]. Delete anyway?"
- **AND** the user must confirm to proceed

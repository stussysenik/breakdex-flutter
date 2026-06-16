# web-library-crud

## ADDED Requirements

### Requirement: Web journal create and edit

The web app SHALL let the owner create and edit journal entries (quick training reflections),
writing them through to the canonical backend so they sync to the phone. Journal writes SHALL be
append-or-update only and SHALL NOT delete existing entries except via soft-archive.

#### Scenario: Owner writes a reflection from desktop
- **WHEN** the owner creates a journal entry on the web app
- **THEN** the entry is saved to the backend and appears on the phone after its next reconcile

#### Scenario: Editing an entry preserves prior text
- **WHEN** the owner edits an existing journal entry
- **THEN** the updated text is written through and the prior version is retained in history

### Requirement: Rename and metadata edits

The web app SHALL let the owner rename moves and combos and edit their metadata, with edits
written through to the canonical truth. A rename SHALL be a metadata update and SHALL NOT require
re-uploading or renaming the underlying media blob.

#### Scenario: Rename propagates without touching media
- **WHEN** the owner renames a move on the web app
- **THEN** the display name updates in the backend and on the phone, while the content-addressed media file is unchanged

#### Scenario: Metadata edit is reversible
- **WHEN** the owner edits a move's metadata
- **THEN** the change is written through and the previous metadata is recoverable from history

### Requirement: Optimistic UI with sync status

The web app SHALL reflect edits optimistically and SHALL surface per-edit sync status (pending,
synced, failed) so the owner can see when a desktop edit has reached the backend.

#### Scenario: Pending edit is visible
- **WHEN** an edit has been applied locally but not yet acknowledged by the backend
- **THEN** the UI shows a pending state for that edit

#### Scenario: Failed write is retryable
- **WHEN** a write-through fails
- **THEN** the UI shows a failed state and offers a retry without losing the edited content

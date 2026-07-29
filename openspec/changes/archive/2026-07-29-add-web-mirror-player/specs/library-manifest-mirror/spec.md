# library-manifest-mirror

## ADDED Requirements

### Requirement: Published manifest includes user-authored journal notes and plans

The published `manifest.json` SHALL include the user-authored combo journal **notes**
(`ComboNoteEntries`) and practice **plans** (`ComboPlans`) in addition to the existing moves,
combos, combo-moves, categories, FSRS cards, decks, deck-moves, reviews, and assets, so that
a read-only consumer can mirror the full library. Each note SHALL carry at least its id, combo
id, kind, body, optional linked-video content hash, and creation timestamp. Each plan SHALL
carry at least its id, combo id, plan date, and optional completion timestamp. The manifest
`version` SHALL be incremented when these collections are added.

#### Scenario: Notes and plans appear in the manifest
- **WHEN** the library contains combo journal notes and practice plans and the manifest is serialized
- **THEN** the serialized JSON contains a `notes` array and a `plans` array reflecting those records, alongside the previously emitted collections

#### Scenario: Empty journal still serializes
- **WHEN** the library has no notes and no plans
- **THEN** the manifest serializes successfully with empty `notes` and `plans` arrays and no error

### Requirement: Manifest publication remains additive and non-destructive

Adding notes and plans to the manifest SHALL NOT introduce any database schema change or
migration, and SHALL NOT modify, move, or delete any stored row. The serializer SHALL read the
existing `ComboNoteEntries` and `ComboPlans` tables only.

#### Scenario: No schema migration introduced
- **WHEN** the app starts with this change present
- **THEN** the database schema version is unchanged and no migration runs as a result of the manifest additions

#### Scenario: Existing manifest consumers tolerate the new fields
- **WHEN** a consumer that predates this change reads the new manifest
- **THEN** it continues to read the collections it already understands and ignores the unknown `notes` and `plans` fields without error

### Requirement: Video resolution contract by content hash

The manifest SHALL expose, for each move, the content hash needed to locate its video file in
the user's Drive `Breakdex/` folder, where the video is stored as `<contentHash>.mp4`. A
read-only consumer SHALL be able to resolve a move to its video by matching the move's content
hash to the Drive file name without requiring Drive file IDs to be embedded in the manifest.

#### Scenario: A move resolves to its Drive video
- **WHEN** a consumer reads a move with content hash `H` and lists the `Breakdex/` folder
- **THEN** the consumer can locate the file named `H.mp4` and stream it as that move's video

#### Scenario: Move without a stored video is handled
- **WHEN** a move has no content hash (no associated video)
- **THEN** the consumer renders the move's metadata without a video and does not error

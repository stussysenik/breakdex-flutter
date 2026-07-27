## ADDED Requirements

### Requirement: Private per-user cloud space
Each signed-in user SHALL sync only to their own Appwrite account space and Google Drive
file scope.

#### Scenario: Two users sign in on the same device
- **WHEN** user A signs out and user B signs in
- **THEN** user B does not read, overwrite, or upload into user A's Appwrite documents or
  Google Drive files

### Requirement: Cross-device retrieval
The app SHALL retrieve the signed-in user's synced records on a second device without
destroying local unsynced Drift state.

#### Scenario: Second device hydrates
- **WHEN** a user signs in on a clean second device after device one has synced moves,
  combos, reviews, notes, decks, tombstones, and metadata
- **THEN** the second device hydrates those records and preserves tombstone semantics

### Requirement: Existing sync semantics remain locked
The sync implementation MUST preserve record-level LWW, tombstones, and dirty-guard
behavior.

#### Scenario: Dirty local edit receives remote update
- **WHEN** a record is locally dirty and an inbound realtime update arrives for that
  record
- **THEN** the inbound update is held or reconciled according to the existing dirty-guard
  rules and does not clobber in-progress edits

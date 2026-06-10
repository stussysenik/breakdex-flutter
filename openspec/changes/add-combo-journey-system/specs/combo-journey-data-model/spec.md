# combo-journey-data-model

## ADDED Requirements

### Requirement: Combo status tag
Each combo SHALL carry exactly one mutable `status` ∈ {`idea`, `attempting`, `landed`, `clean`} (default `idea`). Changing status SHALL atomically append an immutable `combo_note_entries` row with `kind='status'` and body `"<from> → <to>"` in the same transaction.

#### Scenario: Status change is journaled atomically
- **WHEN** a combo's status changes from `attempting` to `landed`
- **THEN** `combos.status` = `landed` AND a new ledger row `kind='status'`, body `"attempting → landed"` exists, both or neither

### Requirement: Append-only journal with video references
`combo_note_entries` SHALL gain `kind` (default `'jot'`), `videoPath` (nullable relative path), `videoHash` (nullable content hash). Existing rows SHALL be untouched by migration. Journal rows SHALL never be updated or deleted by application code; video attachments SHALL be references to existing sandbox/master files — never new copies.

#### Scenario: Migration preserves every existing entry
- **WHEN** the v21→v22 migration runs on a seeded production-shaped database
- **THEN** all pre-existing `combo_note_entries` rows survive byte-identical with `kind='jot'`

#### Scenario: Jot references an existing move video
- **WHEN** a user attaches a move's video to a jot
- **THEN** the jot stores the move's existing relative path/hash and no file is copied

#### Scenario: Referenced video later deleted
- **WHEN** a jot's referenced video no longer resolves
- **THEN** the jot still renders with a "video no longer available" fallback naming the original file, and the miss is logged

### Requirement: Combo creation date
`combos` SHALL gain `createdAt` (non-null). Migration SHALL backfill from the combo's earliest journal entry when one exists, else migration time.

#### Scenario: Backfill from earliest entry
- **WHEN** a combo has journal entries from Mar 4 onward
- **THEN** after migration its `createdAt` is Mar 4

### Requirement: Practice plans table
A new `combo_plans` table SHALL store (id, comboId FK cascade, planDate, position, createdAt, completedAt nullable). Plans are intentions: deletable, reorderable, and NEVER written into the journal ledger.

#### Scenario: Cascade with combo deletion
- **WHEN** a combo is deleted
- **THEN** its plans are removed and no orphan plan rows remain

### Requirement: Export round-trip
Export schema SHALL bump to v7 including status, createdAt, entry kinds, video references, and plans. Import SHALL accept v6 exports, defaulting the new fields.

#### Scenario: v6 import
- **WHEN** a v6 export is imported
- **THEN** all combos arrive with `status='idea'`, entries `kind='jot'`, zero plans, no data lost

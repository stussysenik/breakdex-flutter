## ADDED Requirements

### Requirement: Sets table

The system SHALL persist Set entities in a `sets` table with columns:

- `id` (TEXT, primary key, UUID)
- `name` (TEXT, not null)
- `description` (TEXT, nullable)
- `learning_state` (INTEGER, default 0 — same enum as Move/Combo)
- `created_at` (INTEGER, epoch millis)
- `updated_at` (INTEGER, epoch millis)

#### Scenario: Create a set

- **WHEN** a set is created with name "Power Moves"
- **THEN** a row SHALL be inserted in `sets` with a generated UUID, `learning_state = 0`, and `created_at`/`updated_at` set to the current timestamp

#### Scenario: Update a set name

- **WHEN** a set "Power Moves" is renamed to "Power Moves Advanced"
- **THEN** the `name` column SHALL be updated and `updated_at` SHALL reflect the current timestamp

#### Scenario: Delete a set

- **WHEN** a set is deleted
- **THEN** the row SHALL be removed from `sets` and all associated rows in `set_items` SHALL be cascade-deleted

### Requirement: Set Items junction table

The system SHALL persist set members in a `set_items` junction table with columns:

- `id` (TEXT, primary key, UUID)
- `set_id` (TEXT, foreign key → `sets.id`, not null)
- `item_type` (TEXT, not null — one of: `move`, `combo`, `set`)
- `item_id` (TEXT, not null — the ID of the referenced entity)
- `position` (INTEGER, not null — ordering within the set)

A composite unique constraint SHALL enforce `UNIQUE(set_id, item_type, item_id)`.

#### Scenario: Add a move to a set

- **WHEN** move "Windmill" (id: m1) is added to set "Power Moves" (id: s1) at position 0
- **THEN** a row SHALL be inserted in `set_items` with `set_id = s1`, `item_type = 'move'`, `item_id = m1`, `position = 0`

#### Scenario: Add a combo to a set

- **WHEN** combo "Basic Flow" (id: c1) is added to set "Practice Routine" (id: s2) at position 0
- **THEN** a row SHALL be inserted with `item_type = 'combo'`, `item_id = c1`, `position = 0`

#### Scenario: Nest a subset within a set

- **WHEN** set "Windmill Variations" (id: s3) is added to set "Power Moves" (id: s1) at position 1
- **THEN** a row SHALL be inserted with `item_type = 'set'`, `item_id = s3`, `position = 1`

#### Scenario: Duplicate item rejected

- **WHEN** move "Windmill" (m1) is added to set "Power Moves" (s1) but it already exists in that set
- **THEN** the insertion SHALL fail with a unique constraint violation

#### Scenario: Cycle detection rejects self-reference

- **WHEN** set A contains set B, and an attempt is made to add set A as a child of set B
- **THEN** the operation SHALL be rejected with an error indicating a cycle was detected

### Requirement: Set items ordering

Items within a set SHALL be ordered by the `position` column. Reordering SHALL update `position` values for affected items.

#### Scenario: Reorder items

- **WHEN** a set has items at positions 0, 1, 2 and the user moves position 2 to position 0
- **THEN** the item SHALL be updated to position 0, the former position 0 SHALL become 1, and former 1 SHALL become 2

#### Scenario: Remove an item reindexes

- **WHEN** an item is removed from position 1 of a set with items at 0, 1, 2
- **THEN** the remaining items SHALL have positions 0 and 1 (no gaps)

### Requirement: Set DAO

The `SetsDao` SHALL provide the following operations:

- `createSet(name, [description])` → Set entity
- `updateSet(id, {name, description, learningState})`
- `deleteSet(id)`
- `getSet(id)` → Set with items
- `getAllSets()` → List of Sets
- `addItem(setId, itemType, itemId)` → adds at end
- `removeItem(setId, itemType, itemId)`
- `reorderItem(setId, itemType, itemId, newPosition)`
- `watchAllSets()` → Stream of all Sets (reactive)
- `watchSet(id)` → Stream of single Set with items (reactive)

#### Scenario: Watch reacts to changes

- **WHEN** a widget subscribes to `watchAllSets()` and a new set is created
- **THEN** the stream SHALL emit an updated list containing the new set

#### Scenario: Get set includes nested items

- **WHEN** `getSet("s1")` is called on a set containing 2 moves, 1 combo, and 1 subset
- **THEN** the result SHALL include all items with their types, IDs, and positions, ordered by position

### Requirement: Name uniqueness across entities

A Set's name SHALL be unique across all Set names. Set names SHALL NOT conflict with Move or Combo names (the existing name uniqueness constraint covers all three entity types).

#### Scenario: Duplicate set name rejected

- **WHEN** a set is created with name "Power" and another set already named "Power" exists
- **THEN** the creation SHALL fail with a uniqueness constraint violation

#### Scenario: Set name conflicts with move name

- **WHEN** a set is created with name "Windmill" and a move named "Windmill" already exists
- **THEN** the creation SHALL fail with a uniqueness constraint violation

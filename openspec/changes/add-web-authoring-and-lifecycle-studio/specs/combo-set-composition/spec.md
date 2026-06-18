# combo-set-composition

## ADDED Requirements

### Requirement: Create and edit ordered combos

The web app SHALL let the owner create a combo and arrange its member moves as an explicit ordered
sequence, and reorder, insert, or remove members. The write contract SHALL keep `sequenceIndex`
contiguous and gap-free after every operation, and SHALL reject a combo with no members or duplicate
sequence positions before writing.

#### Scenario: Build a combo from ordered moves
- **WHEN** the owner assembles moves A, B, C in that order and saves
- **THEN** a combo is created whose members have `sequenceIndex` 0, 1, 2 for A, B, C

#### Scenario: Reorder preserves sequence integrity
- **WHEN** the owner moves C before B in an existing combo
- **THEN** the stored sequence becomes A, C, B with contiguous indexes 0, 1, 2

#### Scenario: Removing a member re-indexes the rest
- **WHEN** the owner removes B from combo A, B, C
- **THEN** the stored sequence becomes A, C with contiguous indexes 0, 1

#### Scenario: Empty combo is rejected
- **WHEN** the owner tries to save a combo with no moves
- **THEN** the save is rejected and no write reaches the canonical truth

### Requirement: Create and edit sets

The web app SHALL let the owner create a set (deck) and manage its move membership. Removing a move
from a set SHALL NOT delete or archive the move itself.

#### Scenario: Build a set from moves
- **WHEN** the owner adds moves A and B to a new set and saves
- **THEN** a set is created with A and B as members

#### Scenario: Removing from a set is non-destructive to the move
- **WHEN** the owner removes move A from a set
- **THEN** A is no longer a member of that set but remains an active move in the library

### Requirement: Attach video to a combo by reference

The web app SHALL let the owner attach an existing content-addressed video to a combo as part of
authoring. Attachment SHALL write a content-hash reference only and SHALL NOT upload, re-encode, or
delete the underlying media blob.

#### Scenario: Attach an existing asset
- **WHEN** the owner attaches an existing video (by content hash) to a combo
- **THEN** the combo references that content hash and the video plays in the web view

#### Scenario: Attachment never mutates media
- **WHEN** the owner attaches or detaches a video reference
- **THEN** the underlying content-addressed blob is unchanged

### Requirement: Verified, single-writer write-through

Composition writes (combos, sets, attachments, recovery) SHALL go through the canonical source of
truth and SHALL be reported as saved only after the canonical truth acknowledges the write. Until
then the UI SHALL show a pending state; on failure it SHALL show a failed state and allow retry
without losing the edit. Writes assume a single writer at a time.

#### Scenario: Pending until acknowledged
- **WHEN** the owner saves a composition edit
- **THEN** the edit shows as pending and only flips to saved once the canonical truth acknowledges it

#### Scenario: Failed write is retryable without loss
- **WHEN** a composition write fails
- **THEN** the UI shows a failed state and offers retry, and the edited composition is not lost

### Requirement: Guarded promotion target for discovery candidates

Promoting a `combination-discovery` candidate SHALL route through this composition write path by
opening the combo authoring flow seeded with the candidate's moves. No separate or unguarded write
path SHALL be created for promotion.

#### Scenario: Promote a candidate into a combo
- **WHEN** the owner promotes a never-combined candidate (A, B)
- **THEN** the combo authoring flow opens seeded with A and B in order, and saving uses the same verified write-through as any other combo

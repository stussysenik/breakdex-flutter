# move-lifecycle-archive

## ADDED Requirements

### Requirement: Complete read surface for all videos and entities

The web app SHALL render the **entire** library — every video and every entity (moves, combos with
their ordered move sequences, sets/decks, notes, plans) — from the canonical read path, before any
write capability is enabled.

#### Scenario: All videos are visible
- **WHEN** the owner opens the web app with a loaded library
- **THEN** every move/combo that has an associated video can be played, with none silently omitted

#### Scenario: Combos render in their stored order
- **WHEN** the owner views a combo
- **THEN** its member moves are shown in `sequenceIndex` order, top to bottom

### Requirement: Per-entity lifecycle timeline

The web app SHALL show, for a move or combo, a lifecycle timeline of the meaningful events in its
history (created, edited, combined/used, reviewed, archived), sourced from the recorded event
history where available.

#### Scenario: Viewing a move's lifecycle
- **WHEN** the owner opens a move's detail in the web app
- **THEN** a timeline of its lifecycle events is shown in chronological order

#### Scenario: Graceful timeline without full history
- **WHEN** no recorded event history exists for an entity
- **THEN** the timeline degrades to what the manifest can reconstruct (creation, current memberships, reviews) instead of failing or showing nothing

### Requirement: Deletion-resilient archive

A deleted entity SHALL remain accessible in the web view. Deletion SHALL be modeled as a soft-archive
(tombstone) that never erases the entity, its media reference, or its lifecycle; the canonical truth
SHALL NOT hard-delete owner content.

#### Scenario: A move deleted on the phone is still in /web
- **WHEN** a move is deleted on the phone and the change reconciles to the canonical truth
- **THEN** the move still appears in the web view, clearly marked as archived/deleted, with its video still playable

#### Scenario: Archived entities are visually distinct
- **WHEN** the owner browses the library in the web app
- **THEN** archived/deleted entities are shown in a distinct state and are not mistaken for active ones

#### Scenario: Recovery is available
- **WHEN** the owner chooses to recover an archived entity
- **THEN** the entity is restored to active state through a verified write, and the action itself is recorded in its lifecycle

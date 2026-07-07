# spatial-canvas Specification

## Purpose
TBD - created by archiving change add-discovery-graph-interface. Update Purpose after archive.
## Requirements
### Requirement: Freeform drag positioning

The system SHALL provide a freeform canvas where the owner can drag nodes to arbitrary positions and
arrange related items near each other, independent of any automatic layout.

#### Scenario: Drag a node to a position
- **WHEN** the owner drags a node to a location on the canvas
- **THEN** the node remains at that location until moved again

#### Scenario: Positioning does not alter entities
- **WHEN** the owner repositions nodes on the canvas
- **THEN** no move, combo, note, or plan entity is modified

### Requirement: Saved named layouts

The system SHALL let the owner save the current canvas arrangement as a named layout and reopen it
later, persisting layouts as additive records that reference entity ids without mutating entities.

#### Scenario: Save and reopen a layout
- **WHEN** the owner arranges nodes and saves the layout as "Power exits"
- **AND** later opens the "Power exits" layout
- **THEN** the saved node positions are restored

#### Scenario: Layout persistence is additive
- **WHEN** a layout is saved
- **THEN** the layout is stored separately from the entities
- **AND** deleting the layout leaves all referenced entities intact

### Requirement: Resilience to missing entities

When a layout references an entity that no longer exists, the canvas SHALL render a tombstoned/ghost
placeholder rather than failing, and SHALL allow pruning it, without ever altering other entities to
keep the layout valid.

#### Scenario: Referenced entity was deleted
- **WHEN** a saved layout references a move that has since been deleted
- **AND** the owner opens that layout
- **THEN** a ghost placeholder is shown for the missing node and the rest of the layout renders normally


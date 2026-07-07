# discovery-graph-projection

## ADDED Requirements

### Requirement: Pure projection from existing data to a graph model

The system SHALL provide a pure, read-only projection that transforms the existing library data
(moves, combos, comboMoves, decks, deckMoves, aura_links, notes, plans) into a typed graph model of
`nodes` and `edges`, without writing to or mutating any existing entity.

#### Scenario: Projection is read-only
- **WHEN** the projection runs over the current library data
- **THEN** it returns a `{nodes, edges}` model
- **AND** no move, combo, note, plan, deck, or other entity is created, updated, or deleted

#### Scenario: Deterministic output
- **WHEN** the projection runs twice over the same unchanged input
- **THEN** it produces an equivalent node and edge set both times

### Requirement: Typed node kinds

The graph model SHALL represent each entity as a node carrying its kind (one of: move, combo, note,
plan, deck), its source entity id, and a display label, so views can style and filter by kind.

#### Scenario: A move becomes a move node
- **WHEN** the projection encounters a move
- **THEN** a node with kind `move`, the move's id, and the move's name is present in the model

#### Scenario: A combo becomes a combo node
- **WHEN** the projection encounters a combo
- **THEN** a node with kind `combo`, the combo's id, and the combo's name is present in the model

### Requirement: Typed edge kinds from existing relationships

The graph model SHALL derive edges from existing relationships with explicit kinds: `combo-sequence`
from comboMoves adjacency, `aura-affinity` from aura_links, `deck-membership` from deckMoves, and
`annotation` from notes/plans attached to a combo.

#### Scenario: Combo sequence produces sequence edges
- **WHEN** a combo links moves A then B then C
- **THEN** the model contains `combo-sequence` edges connecting the combo and its member moves in order

#### Scenario: Aura link produces an affinity edge
- **WHEN** aura_links records a natural affinity from move A to move B
- **THEN** the model contains an `aura-affinity` edge between node A and node B

#### Scenario: Missing optional relationship data degrades gracefully
- **WHEN** aura_links (or notes/plans) are absent from the input
- **THEN** the projection omits those edge kinds and still returns a valid model with the remaining nodes and edges

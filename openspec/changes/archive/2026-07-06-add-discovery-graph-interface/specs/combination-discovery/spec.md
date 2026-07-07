# combination-discovery

## ADDED Requirements

### Requirement: Surface never-combined candidate pairs

The system SHALL surface pairs of moves that have a natural transition affinity (an `aura-affinity`
edge) but no existing `combo-sequence` connecting them, as candidate combinations the owner has not
yet tried.

#### Scenario: Natural affinity with no existing combo
- **WHEN** moves A and B have a natural aura affinity
- **AND** no combo sequences A and B together
- **THEN** the pair (A, B) appears as a never-combined candidate

#### Scenario: Already-combined pair is excluded
- **WHEN** moves A and B have a natural affinity
- **AND** an existing combo already sequences A and B together
- **THEN** the pair (A, B) does NOT appear as a candidate

#### Scenario: Fallback when affinity data is absent
- **WHEN** no aura affinity data exists
- **THEN** candidates are derived from co-occurrence (moves sharing combos or decks) so suggestions are still produced

### Requirement: Surface orphan nodes

The system SHALL identify nodes with no connecting edges (orphan moves/combos) so the owner can see
what is disconnected from the rest of the library.

#### Scenario: A move in no combo or deck
- **WHEN** a move belongs to no combo, deck, or affinity edge
- **THEN** it is listed as an orphan in the discovery panel

### Requirement: Promote a discovery into a real combo

Each candidate combination SHALL be actionable: the owner can promote it into a real combo through
the existing, guarded combo-creation flow, without a separate or unguarded write path.

#### Scenario: Promote a candidate
- **WHEN** the owner promotes a never-combined candidate (A, B)
- **THEN** the existing combo-creation flow is opened seeded with moves A and B

#### Scenario: Discovery queries are read-only until promotion
- **WHEN** the owner views discovery candidates and orphans
- **THEN** no entity is created or modified until the owner explicitly promotes a candidate

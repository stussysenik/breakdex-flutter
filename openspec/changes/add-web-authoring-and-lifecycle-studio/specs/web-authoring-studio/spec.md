# web-authoring-studio

## ADDED Requirements

### Requirement: Combo builder

The web app SHALL provide a `/combo-builder` tool that lists the owner's current moves, lets them
assemble an ordered sequence, attach a video, and save through the verified composition write path.

#### Scenario: Assemble and save a combo
- **WHEN** the owner picks moves, orders them, and saves in the combo builder
- **THEN** the combo is created via the composition write contract and appears in the library

#### Scenario: Builder reflects sequence order
- **WHEN** the owner drags a move to a new position in the builder
- **THEN** the builder shows the updated order that will be written as `sequenceIndex`

### Requirement: Combinatorics-seeded suggestions

The combo builder SHALL surface never-combined candidate pairs (from `combination-discovery`'s
`neverCombinedCandidates()`) as suggested starting points, and let the owner seed a draft combo from
a suggestion.

#### Scenario: Builder shows suggestions
- **WHEN** the owner opens the combo builder
- **THEN** moves with a natural affinity that have never been sequenced together are offered as suggestions

#### Scenario: Seed a draft from a suggestion
- **WHEN** the owner selects a suggested pair (A, B)
- **THEN** the builder is seeded with A and B as an editable ordered draft before saving

### Requirement: Set builder

The web app SHALL provide a `/set-builder` tool to assemble a set (deck) from moves, with a
lightweight composition summary (e.g. count and category mix) shown before saving.

#### Scenario: Assemble a set
- **WHEN** the owner adds moves to the set builder and saves
- **THEN** the set is created via the composition write contract

#### Scenario: Composition summary is shown
- **WHEN** the owner is assembling a set
- **THEN** a summary of its current composition (size, category mix) is shown

### Requirement: Analysis is read-only until explicit save

Suggestions and composition analysis SHALL NOT create or modify any entity until the owner
explicitly saves, mirroring discovery's read-only-until-promotion guarantee.

#### Scenario: Browsing suggestions writes nothing
- **WHEN** the owner views suggestions and analysis without saving
- **THEN** no combo, set, or other entity is created or modified

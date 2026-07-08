# Entity Annotations

## ADDED Requirements

### Requirement: Every core entity accepts text annotations

Decks and sets SHALL support free-text notes and timestamped note entries with the same shape
moves and combos already have (`notes` column + entries table, rendered via the existing
notes/journal widgets). Annotations sync under the same LWW + dirty-guard rules as other
record fields.

#### Scenario: Annotate a deck

- **WHEN** the user writes a note on a deck
- **THEN** it persists, auto-saves with the existing debounce behavior, and syncs like other
  record fields

#### Scenario: Timestamped entries on sets

- **WHEN** the user adds a journal entry to a set
- **THEN** it appears in the entity's entry list with its timestamp, matching the
  move/combo journal behavior

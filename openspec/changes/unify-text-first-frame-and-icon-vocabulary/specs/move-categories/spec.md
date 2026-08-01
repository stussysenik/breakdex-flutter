# Move Categories

## ADDED Requirements

### Requirement: The default category set is the owner's eight, in the owner's order

A client that has not persisted a category list SHALL be seeded with the canonical eight
categories in the stated order. Order is meaning, not alphabetics — the list is presented in
the order it was authored, and SHALL NOT be re-sorted for display.

#### Scenario: A fresh install opens the category surface

- **WHEN** a client with no persisted categories renders the list
- **THEN** all eight defaults appear, in the authored order

#### Scenario: A client already persisted a category list

- **GIVEN** an existing client with its own categories
- **WHEN** the app starts
- **THEN** its list is untouched — the default set only seeds an absent list

### Requirement: Uncategorized is a holding pen, not a category

The Uncategorized block SHALL render only while it holds at least one item. Its route SHALL
stay reachable so a deep link or a back navigation into it still resolves.

#### Scenario: A clean library with every move categorised

- **WHEN** the category surface renders and nothing is uncategorised
- **THEN** no Uncategorized block is shown, because advertising an empty bucket teaches a user
  a category exists that does not

#### Scenario: A move loses its category

- **WHEN** an item becomes uncategorised
- **THEN** the block appears, holding it

# Spec Delta — library-legibility

## ADDED Requirements

### Requirement: Library rows subtitle with dates, not identifiers

List rows on library surfaces (category screens, search results, filtered lists) SHALL
subtitle with the item's effective date, labeled by its source ("Added …" / "Filmed …"),
and SHALL NOT render a content hash, UUID, or raw filename as primary or secondary
text. Original filenames remain available on the item's detail screen.

#### Scenario: A camera-roll import shows a date, not a UUID

- **GIVEN** a move whose `originalVideoName` is `7ff8c14c-55f3-49e2-a0f7-….MOV`
- **WHEN** its row renders in a category list
- **THEN** the subtitle shows its effective date and the UUID appears nowhere on the row

#### Scenario: Shown date agrees with sorted date

- **GIVEN** the library sorted by "recently filmed"
- **WHEN** rows render
- **THEN** each subtitle shows the same date the sort used, labeled "Filmed …"

#### Scenario: Provenance survives on the detail screen

- **GIVEN** a move imported from file `OPTW 02-08-26 VERTICAL PART 1.mp4`
- **WHEN** the user opens its detail screen
- **THEN** the original filename is visible there

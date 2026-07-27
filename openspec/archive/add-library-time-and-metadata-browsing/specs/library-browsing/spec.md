# library-browsing — Spec Delta

## ADDED Requirements

### Requirement: The library offers an explicit sort choice

The Moves and Combos library SHALL offer a user-selectable sort with at least: recently
added, recently filmed, recently practiced, and alphabetical. The selection SHALL persist
across app launches and apply to the active view mode without changing it.

#### Scenario: Choosing a sort reorders the library

- **GIVEN** the Moves library is displayed in scan mode, newest-added first
- **WHEN** the user selects "A–Z"
- **THEN** the same moves are shown in the same view mode, ordered alphabetically

#### Scenario: The sort choice survives a relaunch

- **GIVEN** the user selected "recently filmed"
- **WHEN** the app is relaunched and the library opens
- **THEN** the library is still ordered by recently filmed

### Requirement: Every entity has a defined effective date under each sort

Each sort dimension SHALL resolve to a defined date for every entity, falling back to the
entity's creation date when its preferred field is absent, so no item is dropped to an
arbitrary position for lack of metadata.

#### Scenario: A move with no capture date still sorts sensibly

- **GIVEN** a move whose `videoCreationDate` is null (a legacy import) and a move filmed
  last week
- **WHEN** the library is sorted by recently filmed
- **THEN** the legacy move is ordered by the date it was added to Breakdex, in a stable
  position relative to the other moves — not grouped into an undefined bucket

#### Scenario: Combos do not fake a capture date

- **GIVEN** the library is sorted by recently filmed and the user switches to the Combos
  tab
- **WHEN** the combo list renders
- **THEN** combos are ordered by recently added and the interface indicates that filmed
  date does not apply to combos

### Requirement: Date-sorted lists are grouped into time buckets

When a date-based sort is active, the list SHALL group items under calendar-month headers,
labeled relatively for the current and immediately preceding month and absolutely beyond
them. Alphabetical sort SHALL NOT group.

#### Scenario: Scrolling a date-sorted library reads as a timeline

- **GIVEN** a library with moves added this month, last month, and in June 2026
- **WHEN** the user sorts by recently added in scan mode
- **THEN** the list shows "This month", "Last month", and "June 2026" headers above their
  respective moves

#### Scenario: Alphabetical sort has no date headers

- **GIVEN** the library is sorted A–Z
- **WHEN** the list renders
- **THEN** no month headers are shown

### Requirement: Preview rows and tiles disclose the item's date

Move and combo rows and tiles SHALL display the item's effective date for the active sort,
formatted for scanning (relative for the recent past, absolute beyond it) and localized.

#### Scenario: A tile shows when its clip is from

- **GIVEN** a move filmed three days ago, shown in glance mode under a filmed-date sort
- **WHEN** the tile renders
- **THEN** it shows a relative date ("3 days ago" or equivalent localized form) alongside
  the name

#### Scenario: The displayed date follows the active sort

- **GIVEN** a move added today but filmed a year ago
- **WHEN** the user switches from recently added to recently filmed
- **THEN** the date shown on that move's row changes from its added date to its filmed
  date, so the displayed date always explains the item's position

### Requirement: Categories report their recency alongside their count

The category browse surface SHALL show, per category, when it was most recently added to,
and SHALL allow ordering categories by that recency in addition to alphabetically.

#### Scenario: A category tile shows its last activity

- **GIVEN** the "Power moves" category whose most recently added move is from last week
- **WHEN** the category grid renders
- **THEN** that tile shows its move count and its last-activity date

#### Scenario: Categories can be ordered by recency

- **GIVEN** several categories with different last-activity dates
- **WHEN** the user orders categories by recency
- **THEN** the most recently added-to category is listed first, and an empty category with
  no activity sorts last rather than being hidden

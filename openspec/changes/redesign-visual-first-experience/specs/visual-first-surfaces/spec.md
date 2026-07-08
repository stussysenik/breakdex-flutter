# Visual-First Surfaces

## ADDED Requirements

### Requirement: Add flow communicates with visual anchors, not secondary text

The Add tab SHALL present its create choices as visual anchors (iconography, thumbnail,
shape/color) with at most one short label each. Paragraph-style helper or instructional text
SHALL NOT be rendered on the Add surface; text remains the medium for user input fields and
settings only.

#### Scenario: First-time user reads the Add tab without instructions

- **WHEN** a user opens the Add tab
- **THEN** each available action is identifiable by its visual anchor and single label
- **AND** no paragraph-style helper text is rendered

#### Scenario: Input fields keep their text role

- **WHEN** the user enters the move-creation metadata step
- **THEN** text fields (name, notes) render normally — the de-texting applies to interface
  chrome, not to user-entered content

### Requirement: Media grid unifies device and Breakdex videos with unambiguous membership

The media picker SHALL render one grid covering the whole device video library, and every
tile SHALL carry exactly four information slots: thumbnail with duration badge, display name,
one secondary fact (file size or capture date), and membership state. A video whose
`contentHash` matches an existing move SHALL be visibly marked as already in Breakdex.

#### Scenario: Device video already added

- **GIVEN** a device video whose content hash matches an existing move
- **WHEN** the picker renders its tile
- **THEN** the tile shows an "in Breakdex" membership mark
- **AND** selecting it offers opening the existing move instead of silently creating a duplicate

#### Scenario: Tile information is capped at four slots

- **WHEN** any tile renders
- **THEN** it exposes at most the four defined slots, and a missing fact is omitted rather
  than replaced with additional text

#### Scenario: Device-only video is selectable as before

- **GIVEN** a device video with no matching move
- **WHEN** the user selects its tile
- **THEN** the existing import flow starts unchanged

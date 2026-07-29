# layout-system Specification

## Purpose
TBD - created by archiving change add-stacked-viewport-layout. Update Purpose after archive.
## Requirements
### Requirement: Every screen is the same frame

A top-level screen SHALL be composed of four bands, of which bands 1 (safe area), 2 (header,
`AppLayout.headerHeight`) and 4 (navigation, `AppLayout.navBandHeight`) are identical on every
screen and do not vary in height, position, or typography. Only the content band varies. The
content band's first pixel SHALL fall at safe-area top + `headerHeight + contentTopGap` on
every screen without exception.

#### Scenario: Switching between two top-level tabs

- **WHEN** the user moves from one tab to another
- **THEN** the header band's height and the title's baseline are unchanged, and the first
  content pixel falls at the same `y` on both screens

#### Scenario: A screen has a long title

- **WHEN** a title exceeds the available header width
- **THEN** it ellipsizes on one line rather than wrapping, because a growing header band
  would move the content band

### Requirement: Screens do not build their own frame

A screen SHALL be built with `AppScreen` or `AppScreen.slivers`. A screen SHALL NOT construct
its own `Scaffold`, `AppBar`, or `SliverAppBar`. Collapsing, floating, and `.large` header
variants SHALL NOT be used on a top-level screen, because a header that changes height
between screens is the discontinuity this capability removes.

#### Scenario: A new screen is added

- **WHEN** a screen is authored
- **THEN** it supplies a title, optional actions, and content to `AppScreen`, and inherits the
  gutter, reading clamp, and nav-band inset without restating them

#### Scenario: A screen overrides the header title style

- **WHEN** a screen renders its title in a bespoke font, weight, or size
- **THEN** that is a review violation, and the title reverts to the frame's `titleLarge`

### Requirement: Content is clamped to a readable measure

The content band SHALL be clamped to `AppLayout.maxContentWidth` and centred above that
width. A dense grid MAY opt into `AppLayout.maxWideWidth`. Reading content SHALL NOT use the
wide clamp.

#### Scenario: The app is viewed on a wide monitor

- **WHEN** the viewport is wider than the clamp
- **THEN** the content column holds its maximum width and centres, and the gutters absorb the
  remaining width

### Requirement: Vertical rhythm resolves to the grid

Every vertical measurement SHALL be a multiple of `AppLayout.baseline`, and every block height
SHALL be a multiple of `AppLayout.blockGrid`. Sections SHALL be separated by
`AppLayout.sectionGap` and their items by `AppLayout.itemGap`, composed with `AppSection`
rather than with ad-hoc spacer widgets. A raw pixel value in a layout position that a token
expresses SHALL be a review violation.

#### Scenario: A section is added to a screen

- **WHEN** a group of items is added
- **THEN** it is wrapped in `AppSection`, which supplies the section gap and item gaps, and
  the author does not choose spacing values

#### Scenario: A bespoke off-grid dimension is required

- **WHEN** a design deliberately calls for a dimension no token expresses
- **THEN** it is recorded as a deliberate exception rather than mechanically snapped, because
  snapping an intentional value is a design decision and not a conformance move

### Requirement: One scroll axis per screen

A screen's primary content SHALL be reachable in one continuous scroll. A screen SHALL NOT
contain nested independently-scrolling regions, content-hiding horizontal carousels, or
in-screen tab bars that hide a second page of primary content.

#### Scenario: A screen accumulates more content than fits

- **WHEN** a screen's primary content exceeds roughly two viewport heights
- **THEN** the information architecture is split across screens, rather than a second scroller
  or a tab bar being introduced inside the screen

### Requirement: Migration is incremental and recorded

Screens SHALL migrate to the frame as tasks touch them, never in a single invasive sweep. A
non-conforming screen SHALL carry a row in the migration ledger in `docs/design/TOKENS.md`
naming how it currently deviates.

#### Scenario: A task touches a non-conforming screen

- **WHEN** a task modifies a screen whose ledger row says pending
- **THEN** that screen is migrated to `AppScreen` as part of the task, and its ledger row is
  updated in the same commit


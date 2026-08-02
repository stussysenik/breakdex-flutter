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

### Requirement: Band 3 has one atom

A single-line choice, setting, or navigation target inside the content band SHALL be rendered
by `AppRow` (`lib/shared/widgets/app_row.dart`): a flat, tappable line carrying a label, an
optional value, an optional leading affordance, and an optional trailing control, with a floor
of `AppLayout.rowHeight`. `AppRow` SHALL NOT carry a fill, a card, or an elevation — a filled
container makes a row read as a *thing* rather than a *choice*, and once one screen presents
choices as cards and another as lines, the parity the frame exists to create is gone. Grouping
SHALL be expressed by `AppSection` above the rows, never by decorating the rows themselves.

#### Scenario: A screen presents a list of choices

- **WHEN** a screen renders two or more single-line choices
- **THEN** each is an `AppRow` of at least `AppLayout.rowHeight`, under one `AppSection` title,
  and no row carries its own background or border

#### Scenario: A single-select is rendered

- **GIVEN** a setting with a closed set of options (theme, font, palette, sort order)
- **WHEN** it is presented to the user
- **THEN** it renders as an `AppChoiceList<T>` — one `AppRow` per option, the chosen one marked
  with a check — rather than as a segmented control or a wrap of pills, because a filled pill
  makes the selected option a different *kind* of object from its siblings and a wrap places
  options in an order nobody chose

### Requirement: The address line lives inside the header band

A screen's route SHALL be readable as a trail of plain text directly above its title, rendered
by `AppBreadcrumb`. The trail SHALL occupy `AppLayout.crumbHeight` plus `AppLayout.crumbGap`
*inside* the existing header band; band 2 SHALL NOT grow to accommodate it, because a header
whose height changes between screens is the discontinuity the frame exists to remove. A crumb
SHALL be a link if and only if the router's own matcher resolves its path prefix; an
unresolvable prefix renders as plain text.

#### Scenario: A detail screen deep in a route is shown

- **WHEN** a screen at `/breakdex/moves/power-moves` renders
- **THEN** the trail reads as one line of type with the tail emphasised and the ancestors muted,
  and the first content pixel is unchanged from every other screen

#### Scenario: A path segment is not a routable page

- **GIVEN** a path prefix that the router cannot match to a page
- **WHEN** the trail renders that segment
- **THEN** it is plain text, not a link, so tapping it cannot navigate the user somewhere the
  route table never promised

#### Scenario: The widget is pumped without a router

- **WHEN** `AppBreadcrumb` is built in a widget test with no `GoRouter` above it
- **THEN** it renders nothing rather than throwing

### Requirement: An overlay computes its own coordinates

A modal sheet or dialog SHALL position itself against a bottom inset it computes as
`AppLayout.navBandHeight + MediaQuery.padding.bottom`, in one place (`AppSheet`), mirroring how
`AppScreen` owns that computation for screens. An overlay SHALL NOT treat the raw viewport
bottom as the safe bottom: the navigation band is drawn over content, so a viewport-relative
overlay is wrong by exactly that inset and is clipped.

#### Scenario: A sheet is presented over a tab screen

- **WHEN** any modal sheet or dialog is shown
- **THEN** its bottom edge clears the navigation band, at every viewport height, with no
  content hidden behind band 4

#### Scenario: A new overlay is added

- **GIVEN** a diff introducing a `showModalBottomSheet` or `showDialog` call
- **WHEN** the change is reviewed
- **THEN** it is required to route through `AppSheet` rather than hand-rolling the inset


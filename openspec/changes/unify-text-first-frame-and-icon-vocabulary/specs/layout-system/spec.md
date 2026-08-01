# Layout System

## ADDED Requirements

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

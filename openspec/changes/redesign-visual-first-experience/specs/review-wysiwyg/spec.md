# Review WYSIWYG

## ADDED Requirements

### Requirement: Review card fits one screen

The active review card SHALL fit within one viewport with no default scrolling on supported
form factors. Content that genuinely overflows (e.g. long notes) SHALL collapse behind an
explicit expand affordance; scrolling appears only as a deliberate answer to a real content
overflow, never as the default layout strategy.

#### Scenario: Standard card renders without scroll

- **GIVEN** a move with a video, name, and rating row
- **WHEN** the review card renders on a supported phone viewport
- **THEN** all card content is visible without scrolling

#### Scenario: Overflow is an explicit affordance

- **GIVEN** a move whose notes exceed the vertical budget
- **WHEN** the card renders
- **THEN** notes are collapsed with a visible expand control, and the rest of the card still
  fits the viewport

### Requirement: Square-leaning geometry with customizable fill

Review card surfaces SHALL use the `AppRadius.xxs` (4) token instead of larger radii, and the
card fill color SHALL be user-customizable through the arbitrary color mechanism defined in
`clarify-review-loop-and-media-cleanup` (settings color editing), applying live without
restart.

#### Scenario: Radius tokens on review surfaces

- **WHEN** the review card and its rating controls render
- **THEN** their corner radii resolve from `AppRadius.xxs`, with raw values reserved for thin
  progress bars only

#### Scenario: Custom fill applies live

- **GIVEN** the user changes the review fill color in Settings
- **WHEN** they return to a review session
- **THEN** the card renders with the chosen fill without an app restart

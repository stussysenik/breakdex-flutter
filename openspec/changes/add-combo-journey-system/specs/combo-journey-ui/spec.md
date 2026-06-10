# combo-journey-ui

## ADDED Requirements

### Requirement: Three-tab combos surface
The Combos screen SHALL present exactly three views via `AppSegmentedControl`: **Library** (all combos, auto-grouped by `createdAt` month, newest first), **Planned** (ordered practice queue), **Calendar** (past activity + future plans). The active tab SHALL be visually unambiguous and the screen SHALL carry a `titleLarge` "Combos" header.

#### Scenario: Auto-grouping by creation month
- **WHEN** the Library renders combos created in June and May
- **THEN** they appear under "CREATED IN JUNE" / "CREATED IN MAY" section headers with no manual filing

### Requirement: Combo row preview
A Library row SHALL show: name (single line, ellipsized), the transition chain ("Move₁ → Move₂ → …", max 2 lines, clamped), the status tag, and one mono fact stamp (move count · recency). Rows SHALL NOT show per-move state dots or video thumbnails. Rows SHALL render correctly for combos of 1–10+ moves.

#### Scenario: Ten-move combo preview
- **WHEN** a 10-move combo renders in Library
- **THEN** the chain clamps at 2 lines and the row height stays bounded

### Requirement: Status tag control
The combo detail SHALL show the status tag as a tappable chip (current word + ▾). Tapping reveals the four words inline; selecting one updates the tag and the journal per the data-model capability. Text carries the meaning; color (existing learning-state palette) only reinforces.

#### Scenario: Tag change from detail
- **WHEN** the user taps the tag and selects "Clean"
- **THEN** the chip reads "Clean", a muted status row appears atop the journal, and no other UI mutates

### Requirement: Detail page composition
The combo detail SHALL show, in order: breadcrumb (`‹ COMBOS`), name (`titleLarge`), transition chain, status tag, video player, step line directly beneath the player, journal, and a pinned jot composer. Secondary actions (Plan for a day…, Duplicate, Edit, Share, Save to Album, Delete) SHALL live behind a single ⋯ affordance. The legacy NOTES section SHALL be removed from this screen (data preserved, editable via Edit Combo).

#### Scenario: Step tap reviews text and video together
- **WHEN** the user taps step node 7 of 10
- **THEN** the player swaps to that move's video, the step line scroll-centers node 7, and the journal remains visible below

### Requirement: Jot composer
A composer SHALL be pinned at the detail bottom with: text field (placeholder "Jot it down…"), a "+ video" button, and a 44dp accent send button. Sending appends one immutable jot and clears the field. There SHALL be no entry-type selector.

#### Scenario: Fluid type by length
- **WHEN** jots of 40 and 200 characters render
- **THEN** they use `bodySmall` (14) and `bodyMedium` (16) respectively on the 56/16/fluid journal grid

### Requirement: Library-first video picker
"+ video" SHALL open a picker listing, in order: this combo's move videos (name, filename, size, duration, usage counts), recent journal-linked takes, then "Import new from Photos…" as the final row. Selecting a library item links instantly with no copy and no progress UI.

#### Scenario: Linking a move video
- **WHEN** the user picks "Flare — flare_07.MOV · 16.4 MB"
- **THEN** a jot with that reference appears immediately marked as linked

### Requirement: Combo duplication
Duplicating a combo SHALL create a new combo with the same move sequence, name suffixed "(copy)", `status='idea'`, fresh `createdAt`, an empty journal except one `kind='duplicate'` provenance row naming the source. The source combo SHALL be untouched.

#### Scenario: Duplicate is a sketch
- **WHEN** "Saturday Run" (landed, 24 entries) is duplicated
- **THEN** "Saturday Run (copy)" appears in Library tagged Idea with exactly 1 journal row

### Requirement: CTA clarity and orientation
Every screen SHALL have exactly one primary action (Library: FAB "+"; Planned: "Plan a combo" button; Calendar future-day: "+ Plan"; Detail: the composer). All interactive controls SHALL carry visible text verbs or universally-known glyphs with ≥48dp hit areas. Accent color usage SHALL be limited to: segmented selection, primary action, active step node, row leading bar, send button (60/30/10 rule).

#### Scenario: First-time discoverability
- **WHEN** a user lands on any combos screen
- **THEN** the screen name, the primary action, and the way back are each identifiable without trial taps

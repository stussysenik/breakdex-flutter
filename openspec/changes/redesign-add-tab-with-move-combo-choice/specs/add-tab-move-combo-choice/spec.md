# Add Tab Move/Combo Choice

## ADDED Requirements

### Requirement: User sees move-or-combo choice on Add tab
The Add tab SHALL present two equal entry points: "Create Move" and "Create Combo". Neither option SHALL be visually subordinate to the other.

#### Scenario: Add tab loads with both options visible
- **WHEN** the user navigates to the Add tab
- **THEN** both "Create Move" and "Create Combo" cards are displayed as stacked, full-width panels
- **AND** each card shows a distinct icon, title, and descriptive subtitle

### Requirement: Create Move launches the clip-import flow with count step
Selecting "Create Move" SHALL initiate the existing video-clip-based move creation flow (video picker → metadata sheet → MoveCreationService) with a new count step. The flow SHALL be identical to the one previously triggered by the "Select a Clip" button, with the addition of a count selector.

#### Scenario: User creates a move from the Add tab
- **WHEN** the user taps "Create Move"
- **THEN** the video picker bottom sheet opens (Photo Library / Files / Camera)
- **AND** after selecting a video, the metadata sheet opens for name, category, and count input
- **AND** the count defaults to 4 and has a valid range of 1–16
- **AND** duplicate name checking runs before save
- **AND** on success, a SnackBar confirms creation

#### Scenario: User cancels mid-flow
- **WHEN** the user dismisses the video picker or metadata sheet without completing
- **THEN** the Add tab returns to its two-option state with no side effects

### Requirement: Create Combo navigates to combo builder
Selecting "Create Combo" SHALL navigate the user to the existing `CreateComboScreen` via the `/create-combo` modal route.

#### Scenario: User creates a combo from the Add tab
- **WHEN** the user taps "Create Combo"
- **THEN** the `CreateComboScreen` opens as a full-screen modal
- **AND** the user can select moves, reorder them, name the combo, and save
- **AND** on save, the modal pops and the user returns to the stateful shell (Add tab still active)

#### Scenario: Combo creation shows empty state when no moves exist
- **WHEN** the user taps "Create Combo" from the Add tab
- **AND** no moves exist in the database
- **THEN** the move picker inside `CreateComboScreen` displays "No moves yet — add some first!"

### Requirement: AppBar title reflects dual-purpose tab
The Add tab's AppBar SHALL display the title "Add" (not "Add Move") to reflect that the tab supports both move and combo creation.

#### Scenario: AppBar shows generic title
- **WHEN** the Add tab is active
- **THEN** the AppBar title reads "Add"

### Requirement: Move stores count metadata
Each move SHALL store a count value representing how many beats the move occupies. The count SHALL default to 4 and have a valid range of 1–16.

#### Scenario: Newly created move has count
- **WHEN** a move is created via the Add tab flow
- **THEN** the move's count is persisted to the database
- **AND** the count appears in the move's metadata

### Requirement: Combo builder shows beat grid overlay
The `CreateComboScreen` SHALL display a beat grid visualization when toggled on, showing each move as a proportional colored block with a count axis, timeline, and time labels.

#### Scenario: Beat grid shows proportional blocks
- **WHEN** the user adds moves to a combo with varying counts (e.g., 4-count Six Step, 2-count Two Step)
- **THEN** the beat grid renders each move as a block sized proportionally to its count
- **AND** the active move is highlighted with a glow effect
- **AND** a count axis labels each beat position (1, 2, 3…)

#### Scenario: Beat grid toggle hides the overlay
- **WHEN** the user toggles the beat grid off
- **THEN** the beat grid section is hidden
- **AND** the combo builder returns to its standard layout

#### Scenario: Summary bar shows composition stats
- **WHEN** moves are present in the combo
- **THEN** the summary bar displays total moves, total counts, and estimated time (@ 100 BPM)

### Requirement: Sequence list shows count per move
Each item in the combo's sequence list SHALL display the move's count alongside its name and category.

#### Scenario: Sequence item shows counts
- **WHEN** viewing the sequence list in the combo builder
- **THEN** each item displays "N counts" in its subtitle
- **AND** if the move has a non-default category, it is also shown (e.g., "4 counts · POWER")

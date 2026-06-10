# realtime-reactivity

## ADDED Requirements

### Requirement: Stream-driven combo surfaces
Every combos view (Library, Planned, Calendar, detail, journal, picker) SHALL be driven by Drift `watch()` streams. Data that can change SHALL NOT be served from one-shot futures or cached snapshots. A change written anywhere (jot, tag, plan, duplicate, delete) SHALL be visible on every affected screen without manual refresh.

#### Scenario: Cross-screen reactivity
- **WHEN** a jot is added on the detail screen
- **THEN** the Library row's stamp, the Calendar heat, and the Planned tab's evidence update without navigation or refresh

### Requirement: Determinate, monotone progress
Every operation with knowable size (Photos import, thumbnail generation, export, migration) SHALL report determinate progress derived from byte/frame counts, advancing monotonically from 0 to 100. Indeterminate spinners are forbidden where size is knowable. Progress that has not advanced for 2 seconds SHALL emit a stall diagnostic.

#### Scenario: No frozen 0%
- **WHEN** a video import begins
- **THEN** the progress indicator advances within the first second and never sits at 0% while bytes are flowing

#### Scenario: Stall is observable
- **WHEN** an import makes no progress for 2 seconds
- **THEN** a StageLogger stall event with the operation and last byte count is recorded

### Requirement: Zombie code retirement
Views replaced by this change SHALL be deleted in the same phase that replaces them. An `ast-grep` sweep for unreferenced widget classes among the touched features SHALL run before final review, and its findings SHALL be resolved (deleted or justified) in the PR description.

#### Scenario: No orphaned views
- **WHEN** the new CombosScreen lands
- **THEN** the old combo list screen and its providers are removed and no route or import references them

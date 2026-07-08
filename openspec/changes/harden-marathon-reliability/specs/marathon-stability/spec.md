# Marathon Stability

## ADDED Requirements

### Requirement: The core loop survives an 8-hour-equivalent soak

The app SHALL survive a scripted soak repeating the core loop (browse → play video → review
→ add → sync) for an 8-hour-equivalent run with zero crashes, zero unhandled exceptions
surfaced to the user, and a memory profile that plateaus (no monotonic growth across cycles).

#### Scenario: Soak run passes

- **WHEN** the soak script runs the core loop for the defined duration/cycle count
- **THEN** the app process survives with no crash and memory returns to its plateau after
  each cycle

#### Scenario: Leak regression is caught

- **GIVEN** a change that stops disposing a video or animation controller
- **WHEN** the soak runs
- **THEN** the memory plateau check fails and identifies the growth trend

### Requirement: No loading state dead-ends

Every loading state SHALL resolve to content, an error with a retry affordance, or an escape
route — an endless spinner with no exit SHALL NOT exist on any surface. Failures surface
visibly and recover without app restart.

#### Scenario: Network loss during load

- **GIVEN** connectivity drops while a surface is loading remote data
- **WHEN** the load fails
- **THEN** the user sees an error state with retry, and retry succeeds once connectivity
  returns

#### Scenario: Flow-state protection

- **WHEN** a background failure occurs during an active review session
- **THEN** the session continues uninterrupted and the failure is reported passively (status,
  not modal), preserving the user's flow

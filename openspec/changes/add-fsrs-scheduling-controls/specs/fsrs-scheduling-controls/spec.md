# fsrs-scheduling-controls

## ADDED Requirements

### Requirement: User-editable global FSRS scheduling parameters

The app SHALL let the learner edit the global FSRS scheduling parameters — desired retention,
maximum interval, fuzzing, learning steps, and relearning steps — from the SRS parameters surface.
Edited values SHALL be persisted in SharedPreferences and SHALL apply to the next review of any
card. Scheduling SHALL remain global (the same for all decks and categories).

#### Scenario: Editing retention changes future scheduling
- **WHEN** the learner sets desired retention to 0.90 and then rates a due card "Good"
- **THEN** the card's next due date is computed with retention 0.90 (a shorter interval than the 0.85 default would have produced for the same card and rating)

#### Scenario: Toggling fuzzing
- **WHEN** the learner turns off fuzzing
- **THEN** subsequent reviews schedule without interval fuzz, and the change persists

### Requirement: Strictly non-destructive to deployed data

Editing FSRS parameters SHALL NOT modify, delete, or migrate any stored data. The change SHALL NOT
add or alter any database table, column, or migration. Stored `fsrs_cards` rows (stability,
difficulty, due date, reps, lapses) SHALL remain unchanged when a parameter is edited; the new
parameters affect only the computation performed at a card's next natural review.

#### Scenario: Existing card data untouched on edit
- **WHEN** the learner changes desired retention while cards already have stored schedules
- **THEN** no `fsrs_cards` row is written as a result of the edit, and each card keeps its current due date until it is next reviewed

#### Scenario: No schema migration introduced
- **WHEN** the app starts with this change present
- **THEN** the database schema version is unchanged and no migration runs for FSRS settings (parameters are read from SharedPreferences)

### Requirement: Defaults preserve current behavior

When no FSRS parameters have been set, or stored values are missing or out of range, the app SHALL
use the prior hardcoded defaults: desired retention 0.85, learning steps [10m], relearning steps
[10m], maximum interval 36500 days, fuzzing enabled. A learner who never opens the controls SHALL
experience scheduling identical to before this change.

#### Scenario: Fresh install / never opened controls
- **WHEN** a learner who has never edited FSRS settings reviews cards
- **THEN** scheduling uses retention 0.85, steps [10m]/[10m], max interval 36500, fuzzing on — identical to the previous build

#### Scenario: Corrupt or missing preference falls back
- **WHEN** a stored FSRS preference is absent or outside its valid range
- **THEN** the app uses the corresponding default for that parameter without error

### Requirement: Parameters validated to safe ranges

The controls SHALL constrain each parameter to a safe range before persisting or applying it:
desired retention within [0.70, 0.97], maximum interval ≥ 1 day, and steps as non-negative
durations. Out-of-range input SHALL be clamped, never applied raw.

#### Scenario: Retention clamped
- **WHEN** a retention value below 0.70 or above 0.97 would be applied
- **THEN** it is clamped into [0.70, 0.97] before the scheduler is constructed

### Requirement: Live reflection and reset

The SRS parameters surface SHALL reflect the current persisted values and update immediately when
edited. The surface SHALL provide a "reset to defaults" action that restores the prior hardcoded
defaults. Persisted values SHALL survive app restart.

#### Scenario: Reset to defaults
- **WHEN** the learner taps "reset to defaults"
- **THEN** all FSRS parameters return to retention 0.85, steps [10m]/[10m], max interval 36500, fuzzing on, and these persist

#### Scenario: Persistence across restart
- **WHEN** the learner sets retention to 0.88 and restarts the app
- **THEN** the SRS parameters surface shows 0.88 and reviews schedule with 0.88

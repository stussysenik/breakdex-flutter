# Personalization Controls

## ADDED Requirements

### Requirement: Parametric entity naming

The user SHALL be able to rename the two core data-banks ("Moves", "Combos") from Settings,
and the chosen nouns SHALL render everywhere the defaults appear — tab labels, screen titles,
empty states, and dialogs. Renaming SHALL never alter stored data, only presentation.

#### Scenario: Renamed noun renders app-wide

- **GIVEN** the user renames "Moves" to "Blocks"
- **WHEN** they visit the library tab, a move's detail screen, and a delete dialog
- **THEN** each surface uses "Blocks" where it previously used "Moves"

#### Scenario: Reset to defaults

- **WHEN** the user clears a custom noun
- **THEN** the default label returns everywhere without restart

### Requirement: Flow-order preference for the add flow

The user SHALL be able to choose where video editing happens in the add flow: after metadata
(default, today's order) or immediately on selection (edit-while-adding). Both orders SHALL
produce identical move records.

#### Scenario: Edit-while-adding order

- **GIVEN** the preference is set to edit-while-adding
- **WHEN** the user picks a clip
- **THEN** the editor opens first and the metadata step follows it

#### Scenario: Orders converge on the same record

- **WHEN** the same clip is added under each order with the same inputs
- **THEN** the resulting move records are equivalent

### Requirement: Party mode is the fresh-install default

Fresh installs SHALL default to `AppMode.party`. An existing user's persisted app-mode choice
SHALL never be overridden by this change.

#### Scenario: Fresh install lands in party mode

- **GIVEN** a first launch with no stored `app_mode`
- **WHEN** the app starts
- **THEN** the app mode resolves to party

#### Scenario: Existing preference untouched

- **GIVEN** a user with stored `app_mode = anki`
- **WHEN** the app updates to this version
- **THEN** the mode remains anki

### Requirement: Settings apply live and confirm themselves visually

Every customization in Settings SHALL apply immediately (no save ceremony) and SHALL be
visually self-confirming on its own row (e.g. a type specimen for typography, a swatch for
colors, the live noun for naming). Settings sections SHALL each own one concern: Practice,
Appearance, Library & Data, System & Sync — consolidating the quiet-mode/review-composer
panels per the rescoped `add-quiet-playback-and-senior-drill-ui`.

#### Scenario: Change is visible before leaving Settings

- **WHEN** the user changes typography
- **THEN** the setting's own row re-renders in the chosen font immediately

#### Scenario: Leave and see it

- **GIVEN** any customization changed in Settings
- **WHEN** the user navigates back to the affected surface
- **THEN** the change is already applied with no restart or save step

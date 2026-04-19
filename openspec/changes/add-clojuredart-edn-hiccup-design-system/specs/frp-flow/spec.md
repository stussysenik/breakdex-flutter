## ADDED Requirements

### Requirement: Reactive data flow via watchers
The system SHALL notify watchers when atom values change.

#### Scenario: Add watcher to atom
- **WHEN** developer calls `(add-watch state :logger (fn [_ _ _ new] (log new)))`
- **THEN** watcher is invoked on every state change

#### Scenario: Watcher receives old and new value
- **WHEN** atom value changes
- **THEN** watcher receives old-value and new-value

### Requirement: Widget rebuilds on state change
The Flutter UI SHALL re-render when atom changes.

#### Scenario: Text widget bound to atom
- **WHEN** widget is created with `@count-atom`
- **AND** count-atom changes
- **THEN** text displays new value

#### Scenario: Batch updates trigger single rebuild
- **WHEN** developer swaps multiple values in one transaction
- **THEN** widget rebuilds once

### Requirement: Unidirectional data flow
Data SHALL flow in one direction: state → UI.

#### Scenario: User action updates state
- **WHEN** user taps button
- **THEN** state updates, UI reflects change
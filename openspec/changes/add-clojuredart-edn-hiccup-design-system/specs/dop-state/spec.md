## ADDED Requirements

### Requirement: Atom-based state management
The system SHALL use Clojure atoms as the primary state container.

#### Scenario: Create atom with initial value
- **WHEN** developer creates `(def state (atom {:count 0}))`
- **THEN** atom contains initial map

#### Scenario: Swap modifies atom
- **WHEN** developer calls `(swap! state update-in [:count] inc)`
- **THEN** atom's value is incremented

#### Scenario: Read atom value
- **WHEN** developer accesses `@state`
- **THEN** current value is returned

### Requirement: State persists across sessions
The system SHALL persist atom state to local storage.

#### Scenario: Save atom to storage
- **WHEN** developer calls `(save-atom! state :moves)`
- **THEN** atom is serialized to local storage

#### Scenario: Restore atom from storage
- **WHEN** app launches with saved state
- **THEN** atom is hydrated from storage

### Requirement: Multiple independent atoms
The system SHALL support multiple atoms for different domains.

#### Scenario: Move atoms and combo atoms
- **WHEN** developer creates `(def moves (atom []))` and `(def combos (atom []))`
- **THEN** each atom operates independently
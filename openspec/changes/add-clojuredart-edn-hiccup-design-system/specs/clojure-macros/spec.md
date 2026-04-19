## ADDED Requirements

### Requirement: Compile-time code generation
The system SHALL generate code at compile time without external tools.

#### Scenario: defmodel macro
- **WHEN** developer writes `(defmodel Move [id name difficulty])`
- **THEN** record is generated at compile time

#### Scenario: defwidget macro
- **WHEN** developer writes `(defwidget button [text] ...)`
- **THEN** widget function is generated

### Requirement: JSON serialization
The system SHALL generate serialization code automatically.

#### Scenario: Derive JSON from model
- **WHEN** Move model is defined
- **THEN** to-json/from-json are generated

#### Scenario: JSON round-trip
- **WHEN** move is serialized to JSON
- **AND** deserialized
- **THEN** data is identical

### Requirement: DI (Dependency Injection) via macros
The system SHALL handle DI at compile time.

#### Scenario: Inject database
- **WHEN** developer uses `(inject db)`
- **THEN** database is available at runtime

#### Scenario: Inject client
- **WITH** developer uses `(inject supabase-client)`
- **THEN** client is available
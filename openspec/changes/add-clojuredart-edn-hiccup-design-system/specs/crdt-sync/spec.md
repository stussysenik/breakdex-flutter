## ADDED Requirements

### Requirement: Conflict-free merging
The system SHALL merge concurrent changes without conflicts.

#### Scenario: Two devices modify same move
- **WHEN** device A updates move name to "Windmill"
- **AND** device B updates move name to "Spin"
- **THEN** merge result is deterministic

#### Scenario: Timestamp-based resolution
- **WHEN** two updates have different timestamps
- **THEN** update with later timestamp wins

### Requirement: Offline-first operation
The system SHALL work offline and sync when connected.

#### Scenario: Create move offline
- **WHEN** device is offline
- **AND** user creates move
- **THEN** move is saved locally

#### Scenario: Sync when online
- **WHEN** device comes online
- **THEN** local changes sync to server

### Requirement: CRDT types for domain objects
The system SHALL support standard CRDT types.

#### Scenario: LWWRegister for single values
- **WHEN** register is created
- **THEN** it resolves to latest value

#### Scenario: LWWRegister for move fields
- **WHEN** move has LWWRegister for name, difficulty
- **AND** changes happen concurrently
- **THEN** each field resolves independently
# web-state-machines

## ADDED Requirements

### Requirement: Web studio machines are XState v5 mirrors of Flutter machines
Interactive CRUD/editing flows in the web studio SHALL be governed by XState v5 statecharts
whose design (states, events, guards, transitions) mirrors the corresponding Flutter
`Machine<S,E>` 1:1 — same diagram, different runtime. Flutter's zero-dependency framework
in `lib/core/state_machines/` SHALL NOT be replaced or wrapped. Each mirrored pair SHALL
share a transition-table test: the same scenarios asserting the same resulting states in
both runtimes.

#### Scenario: Mirrored move-detail machine
- **WHEN** the move-detail statechart is implemented in the web studio
- **THEN** its states and events correspond one-to-one to the Flutter move-detail machine,
  and the shared transition-table test passes in both `flutter test` and the web test runner

#### Scenario: Web dirty-guard parity
- **WHEN** a realtime update arrives for a record being edited in the studio
- **THEN** the XState machine holds the inbound update exactly per `notes-conflict-guard`,
  matching Flutter behavior

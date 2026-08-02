# iOS Compile Budget

## ADDED Requirements

### Requirement: The cold iOS release build cost is a recorded number

The repository SHALL carry `docs/ios-build-budget.md` recording the wall-clock duration of a
cold `flutter run --release` device build, the date it was measured, the machine, and the
exact procedure used to produce it. A claim about compile speed SHALL cite that file rather
than an impression.

#### Scenario: A session claims the build got slower

- **GIVEN** `docs/ios-build-budget.md` records a duration with its procedure
- **WHEN** a session believes the build has regressed
- **THEN** it re-runs the recorded procedure and compares two numbers, not two feelings

#### Scenario: No baseline exists

- **WHEN** a change proposes a build-speed optimization with no recorded baseline
- **THEN** the baseline measurement is the first task and the optimization is blocked on it

### Requirement: No Firebase dependency survives under lib/

No file under `lib/` SHALL import `package:firebase_core`, `package:firebase_auth`,
`package:firebase_storage`, or `package:cloud_firestore`, and `pubspec.yaml` SHALL declare
none of them. This SHALL be enforced by a test, in the shape of the existing icon and color
conformance gates.

#### Scenario: A Firebase import is reintroduced

- **WHEN** a diff adds a `package:firebase_*` or `package:cloud_firestore` import under `lib/`
- **THEN** the conformance test fails and the diff does not land

#### Scenario: A Firebase dependency is reintroduced to pubspec

- **WHEN** a diff adds a firebase package to `pubspec.yaml` dependencies
- **THEN** the conformance test fails, naming the pod tree the dependency drags in

### Requirement: A retired transport names its replacement

Removing a sync or auth capability SHALL name, per capability, the Appwrite path that
replaces it. A removed capability with no named replacement SHALL halt the change and be
surfaced to the owner rather than deleted silently.

#### Scenario: A Firestore write path has an Appwrite equivalent

- **GIVEN** a Firestore write in `sync_service.dart` for an entity
- **WHEN** the corresponding backend under `lib/core/sync/backends/` handles that entity
- **THEN** the removal records the replacement and proceeds

#### Scenario: A Firestore write path has no equivalent

- **WHEN** a capability exists only on the Firestore path
- **THEN** the change stops, records the gap as a finding, and the owner rules before deletion

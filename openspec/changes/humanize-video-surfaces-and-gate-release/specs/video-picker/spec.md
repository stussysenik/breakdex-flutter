# Spec Delta — video-picker

## ADDED Requirements

### Requirement: The picker organizes by intent, not by storage backend

The SELECT VIDEO picker SHALL present exactly two tabs — **In Breakdex** (the app's own
video library, the default tab) and **Import** (the device photo library, videos only)
— and SHALL NOT surface storage locations (filesystem directories, Photos albums,
recovery scans) as separate browsing destinations.

#### Scenario: The library greets the user

- **GIVEN** a user opens the picker with videos already in Breakdex
- **WHEN** the sheet renders
- **THEN** the In Breakdex tab is selected by default and lists the app's videos
  newest-first by their effective date

#### Scenario: The recovery scan is not a tab

- **GIVEN** the historical Breakdex-albums recovery capability
- **WHEN** the picker renders
- **THEN** no tab exposes it, and the capability remains reachable from the
  recovery/settings surface

### Requirement: Library tiles show truthful human metadata

Each In Breakdex tile SHALL show a human title (the owning move or combo's name when
one exists, else the filename stripped of hash suffixes) and SHALL never render a
content hash, UUID, or fabricated value; a duration badge SHALL appear only when a real
duration was probed.

#### Scenario: Owned video shows its move's name

- **GIVEN** a manifest row owned by a move named "backspin variations"
- **WHEN** its tile renders
- **THEN** the title reads "backspin variations", not the on-disk filename

#### Scenario: No fabricated durations

- **GIVEN** a video whose duration has not been (or cannot be) probed
- **WHEN** its tile renders
- **THEN** no duration badge is shown — never a placeholder such as 0:01

#### Scenario: Ownerless video is listed without leaking identifiers

- **GIVEN** a live manifest row with no owning entity, backed by file
  `Thursday July 16th 2026 - 69e13899.mp4`
- **WHEN** its tile renders
- **THEN** it appears in the list titled "Thursday July 16th 2026" with no hash
  fragment visible

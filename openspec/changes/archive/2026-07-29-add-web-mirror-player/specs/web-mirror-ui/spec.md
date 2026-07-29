# web-mirror-ui

## ADDED Requirements

### Requirement: Read-only mirror of the full library

The web app SHALL render a read-only mirror of the user's library from `manifest.json`,
including moves, combos and their move sequences, journal notes, practice plans, and FSRS/
review state. The mirror SHALL be a projection of the manifest only and SHALL expose no control
that creates, edits, or deletes data.

#### Scenario: Library renders from the manifest
- **WHEN** the owner is signed in and `manifest.json` is loaded
- **THEN** the app displays the moves, combos, notes, plans, and review/FSRS state contained in the manifest

#### Scenario: No editing affordances
- **WHEN** the owner views any section of the mirror
- **THEN** the interface offers only viewing and playback — there is no add, edit, rate, plan, or delete control

### Requirement: Inline video playback from Drive

The web app SHALL play a move's video by resolving its content hash to the corresponding
`<contentHash>.mp4` in the Drive `Breakdex/` folder and streaming it with the user's Drive
token. Playback SHALL stream rather than require downloading the entire file into memory before
play begins.

#### Scenario: Playing a move's video
- **WHEN** the owner selects a move that has a video
- **THEN** the corresponding Drive video streams and plays inline

#### Scenario: Missing video degrades gracefully
- **WHEN** a move references a content hash with no matching file in the `Breakdex/` folder
- **THEN** the app shows the move's metadata and a clear "video unavailable" state instead of erroring

### Requirement: Resilient to partial or older manifests

The web app SHALL render whatever the manifest contains and SHALL degrade gracefully when
optional collections (e.g. notes, plans) are absent — as when an older mobile build published a
manifest without them.

#### Scenario: Older manifest without notes/plans
- **WHEN** the loaded manifest omits the `notes` and `plans` collections
- **THEN** the app still renders moves, combos, and stats, and simply shows empty journal/plan sections

#### Scenario: Empty library
- **WHEN** the manifest contains no moves
- **THEN** the app shows an empty-state message rather than a broken or blank screen

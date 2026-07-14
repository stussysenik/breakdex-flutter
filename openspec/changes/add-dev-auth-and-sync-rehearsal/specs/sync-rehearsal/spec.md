# sync-rehearsal

## ADDED Requirements

### Requirement: The Phase-M scenario ladder is rehearsed cross-surface with user #0

The rehearsal SHALL drive a dedicated dev account (user #0) through the Phase-M scenario
ladder on two live surfaces (iOS simulator + web) using the ruled smoke driver (argent, with
chrome-devtools as the sanctioned web fallback): isolated origin, backfill parity, per-entity
dual-write → dual-read flips in the runbook's order, LWW conflict, tombstone no-resurrect,
and note-entry sync. Each rung SHALL record terminal- or driver-verified evidence in
`docs/sync-rehearsal-runbook.md` before its box ticks, and any data loss or duplication SHALL
flip that entity's pref back OFF and halt the ladder.

#### Scenario: An edit crosses surfaces in both directions
- **WHEN** an entity's dual-write and dual-read prefs are ON and user #0 edits a record on one surface
- **THEN** the edit appears on the other surface, and an edit made there flows back

#### Scenario: Concurrent edits resolve by LWW
- **WHEN** the same record is edited on both surfaces in quick succession
- **THEN** the write with the later `updatedAt` wins on both surfaces with no duplicate rows

#### Scenario: A tombstoned record never resurrects
- **WHEN** user #0 deletes a record on one surface and both surfaces later relaunch and re-sync
- **THEN** the record is absent on both surfaces permanently

#### Scenario: The rehearsal's blast radius is user #0 only
- **WHEN** the full ladder has run
- **THEN** a server-key spot-check shows no row outside `userId == dev0` was created, modified, or deleted by the rehearsal

### Requirement: Video pointer metadata rides the same sync machinery

The rehearsal SHALL prove that video **pointer** rows (the backend's video metadata — never
bytes) cross surfaces under the same dual-write → dual-read → LWW → tombstone machinery as
every other entity. Video **bytes** stay on Google Drive and require the owner's Drive token
(`google_sign_in`, a separate flow from Appwrite identity), so byte upload/playback SHALL
remain fenced to Phase M — user #0 has no Google account by design.

#### Scenario: A video pointer crosses surfaces
- **WHEN** user #0 creates a move with video metadata on one surface with the relevant prefs ON
- **THEN** the pointer row (name/reference fields, not bytes) appears on the other surface, and the missing-bytes state degrades visibly rather than erroring

#### Scenario: Byte transport is explicitly fenced
- **WHEN** the rehearsal ledger records the video rung
- **THEN** it names Drive byte upload/playback as NOT covered, pointing to Phase M

### Requirement: The rehearsal ledger fences what it cannot prove

The rehearsal ledger SHALL enumerate, alongside its results, the Phase-M proofs it does not
cover — live Google OAuth on iOS, Drive video playback on web, the legacy-identity claim,
the owner-cohort remote-config flip, and web OAuth with the httpOnly cookie — so a green
rehearsal cannot be misread as Phase M passing.

#### Scenario: Fenced items are explicit in the ledger
- **WHEN** the rehearsal completes and the ledger is written
- **THEN** it contains a fence table naming each owner-only proof as NOT covered, and the change's completion notes point to Phase M as the remaining live gate

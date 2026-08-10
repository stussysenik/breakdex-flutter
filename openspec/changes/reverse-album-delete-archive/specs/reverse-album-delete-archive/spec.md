# Spec: Reverse Album Delete Archive & Recovery

> **Language: Dart (Flutter) + native iOS (PhotoKit).** Depends on: `appwrite`
> (sync metadata), `enforce-face-law-conformance` (Recently Deleted UI on `AppScreen`).
> Implementation in a fresh student session — never this one.

This spec defines the move-level archive/recovery flow: when a user *externally*
deletes a Breakdex-managed Photos album copy, the app archives the move (never
hard-deletes it), surfaces it in a Recently Deleted inbox, and lets the user restore
or permanently delete it. Where it is silent on sync semantics, the
`migrate-canonical-backend-to-appwrite` and `make-sync-total-and-registry-driven` specs
are normative.

Module layout (additive):
- `lib/features/move_detail/data/` — archive columns + DAO helpers (Phase 1 landed).
- `lib/core/services/` — reconciliation service (startup/resume/PhotoKit triggers).
- native iOS bridge — read/lookup reconcile APIs (PhotoKit).
- `lib/features/settings/` — Recently Deleted `AppScreen` (restore + purge).

## ADDED Requirements

### Requirement: Managed-photos-reconciliation

The app SHALL reconcile tracked Photos `localIdentifier` values against the live PhotoKit
library and archive any move whose managed album copy is missing. Reconciliation SHALL
run on app startup (after first frame), app resume, and on PhotoKit library-change events.
The iOS bridge SHALL request `PHPhotoLibrary` read authorization only when there are tracked
managed assets to reconcile.

#### Scenario: External delete archives the move
- **WHEN** a tracked managed Photos album copy is deleted externally in Photos
- **AND** reconciliation runs (startup, resume, or library-change event)
- **THEN** the move is archived (`archivedAt` set, `archiveReason = external-delete`)
- **AND** it is excluded from active drill/list/review surfaces
- **AND** the detail view still resolves it by ID (in-flight screens don't crash)

#### Scenario: Present assets are left untouched
- **WHEN** reconciliation runs and every tracked `localIdentifier` resolves to a live `PHAsset`
- **THEN** no move is archived and no existing archive is touched

#### Scenario: Auth is gated on tracked assets
- **WHEN** there are no tracked managed assets to reconcile
- **THEN** the iOS bridge does NOT request `PHPhotoLibrary` authorization

### Requirement: Recently-deleted-moves

The app SHALL provide a Recently Deleted surface (an `AppScreen` linked from Settings →
Data) listing archived moves with restore and permanent-delete actions. Restoring SHALL
require a valid local video, recreate the managed Photos album copy, store the new exact
asset metadata, and clear the archive fields. Permanent delete SHALL route through the
existing cleanup service. Archived moves older than 30 days SHALL be purged automatically.

#### Scenario: Restore recreates the managed copy
- **WHEN** the user restores an archived move that has a valid local video
- **THEN** the managed Photos album copy is recreated
- **AND** the new exact asset metadata is stored
- **AND** `archivedAt`/`archiveReason` are cleared
- **AND** the move returns to active surfaces

#### Scenario: Restore with missing video fails explicitly
- **WHEN** the user restores an archived move whose local video is missing
- **THEN** restore fails with an explicit error
- **AND** the move stays archived (no partial state)

#### Scenario: Permanent delete routes through cleanup
- **WHEN** the user permanently deletes an archived move
- **THEN** the existing cleanup service removes local files, thumbnails,
  content-addressed state, and the managed Photos copy consistently

#### Scenario: 30-day purge
- **WHEN** an archived move's `archivedAt` is older than 30 days
- **THEN** the next reconciliation pass purges it through the cleanup service

### Requirement: Archive-sync-state

The app SHALL persist archive state locally (Drift) and through Appwrite move metadata
(`archived_at`, `archive_reason`). Archive SHALL sync as a move *update*, never as a
delete, preserving the recoverable-vs-hard-delete distinction across devices.

#### Scenario: Archive syncs as update
- **WHEN** a move is archived on device A
- **THEN** the Appwrite `moves` record carries `archived_at` + `archive_reason`
- **AND** device B hydrates the move in its archived state (excluded from active surfaces)

#### Scenario: Hard delete does not masquerade as archive
- **WHEN** a move is permanently deleted from inside Breakdex
- **THEN** it is synced as a tombstone/delete, distinct from the archive-update shape

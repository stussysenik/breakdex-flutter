## ADDED Requirements

### Requirement: Replace DeleteStateMachine with sealed class pattern
The existing `DeleteStateMachine` (enum + StreamController) SHALL be replaced with a `TrashMachine` using the same sealed-class pattern as all other CRUD machines. States SHALL be: `Viewing`, `ConfirmingTrash`, `Trashing`, `Trashed`, `ConfirmingRestore`, `Restoring`, `ConfirmingPurge`, `Purging`, `Failed`.

#### Scenario: Trash an asset
- **WHEN** user confirms trash action
- **THEN** machine transitions `Viewing` → `ConfirmingTrash` → `Trashing` → `Trashed`

#### Scenario: Restore a trashed asset within grace period
- **WHEN** asset is in grace period (30 days) and user confirms restore
- **THEN** machine transitions `Viewing` → `ConfirmingRestore` → `Restoring` → `Viewing`

#### Scenario: Purge expired assets
- **WHEN** grace period has expired and user confirms purge
- **THEN** machine transitions `Viewing` → `ConfirmingPurge` → `Purging` → `Viewing` (asset permanently deleted)

### Requirement: Grace period enforcement
The machine SHALL reject restore attempts for assets whose 30-day grace period has expired. The `Restoring` state SHALL check `deletedAt + 30 days < now` and transition to `Failed` if expired.

#### Scenario: Restore rejected after grace period
- **WHEN** asset was trashed more than 30 days ago and user attempts restore
- **THEN** machine transitions to `Failed` with "Grace period expired" error

### Requirement: Safety guard for hard delete
Hard delete SHALL verify minimum verified copy count (2) before proceeding, matching existing safety guard behavior.

#### Scenario: Hard delete blocked by safety guard
- **WHEN** asset has fewer than 2 verified copies and user attempts hard delete
- **THEN** machine transitions to `Failed` with safety guard error message

### Requirement: Existing API compatibility
The new `TrashMachine` SHALL expose `trash(hash, reason)`, `restore(hash)`, `hardDelete(hash)`, `purgeExpired()`, and `daysUntilPurge(hash)` methods matching the existing `DeleteStateMachine` public API.

#### Scenario: Public API unchanged
- **WHEN** existing code calls `machine.trash(hash, reason: 'user')`
- **THEN** the behavior is identical to the previous `DeleteStateMachine`

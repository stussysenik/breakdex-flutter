## ADDED Requirements

### Requirement: Distinguish video recovery from move restoration
The video reliability runtime SHALL NOT report a "restored moves" notification when only video files are recovered during cold start. A "move restored" notification SHALL only fire when an actual move database row is restored (e.g., from trash).

#### Scenario: Cold start video recovery
- **WHEN** the app starts and reconciles locally-present video files that have no corresponding move rows
- **THEN** no "restored moves" notification is shown to the user

#### Scenario: Move restored from trash
- **WHEN** a user explicitly restores a trashed move via the trash screen
- **THEN** the move list SHALL reflect the restored move without spurious duplicate notifications

### Requirement: Canonical reconciliation does not create duplicate move entries
The `canonical_reconcile_service.recoverOrphansLocally` method SHALL NOT create duplicate move database entries. It SHALL only update the asset manifest for files that already have manifest entries.

#### Scenario: Orphan recovery updates manifest only
- **WHEN** reconciliation finds a locally-present file matching a known manifest hash
- **THEN** the manifest's `localPath` and `localVerifiedAt` are updated; no new move row is created

#### Scenario: Orphan without manifest is imported as asset only
- **WHEN** reconciliation finds a file with no matching manifest
- **THEN** a new manifest entry is created via `importOrphans` but no move row is created

# Reverse Album Delete Archive & Recovery — Design

## Product Contract

Breakdex remains the canonical library. Photos albums are managed projections. If the user deletes a Breakdex-managed Photos asset externally, Breakdex responds by archiving the move into Recently Deleted. This removes it from active drill and arsenal UI without destroying the underlying record immediately.

## Archive Model

Moves gain nullable archive metadata:
- `archivedAt`
- `archiveReason`

Archived moves stay in the database so they can be restored, but active queries exclude them. Detail views may still resolve archived moves by ID so in-flight screens do not crash if reconciliation happens mid-session.

## Reconciliation Model

### Managed asset identity
Each move already stores the exact Photos `localIdentifier` for its managed album copy. Reconciliation uses those IDs instead of semantic filenames.

### Native lookup
The iOS bridge requests `PHPhotoLibrary` read/write authorization only when there are tracked managed assets to reconcile. It can then:
- compare tracked `localIdentifier` values with `PHAsset.fetchAssets(withLocalIdentifiers:)`
- emit a generic library-changed event when PhotoKit reports changes

The Dart side performs the DB-aware reconciliation because it owns move/archive policy.

### Trigger points
- app startup after first frame
- app resume
- PhotoKit library change event while the app is active

## Restore Model

Restoring an archived move requires a valid local video file. Restore recreates the managed Photos album copy, stores the new exact asset metadata, and clears the archive fields. If the local video is missing or the album copy cannot be recreated, restore fails explicitly and leaves the move archived.

## Permanent Delete & Retention

Archived moves are retained for 30 days. Expired archived moves are purged during reconciliation startup/resume passes. Purging uses the existing cleanup service so local files, thumbnails, content-addressed asset state, and app-managed Photos copies are removed consistently.

## Sync

Supabase `moves` metadata gains:
- `archived_at`
- `archive_reason`

Archive is synced as a move update, not a delete. This preserves the distinction between recoverable external deletion and intentional hard deletion from inside Breakdex.

## iCloud Retrieval

There are two separate iCloud paths:
- Breakdex cloud sync already uses iCloud Drive for app-managed files
- Photos-managed album copies can be recovered later via PhotoKit using the stored Photos asset identity

For Photos-backed recovery, the correct primitive is asset-identity-based retrieval rather than filename scanning. Officially, PhotoKit supports cloud-backed media access through APIs such as `requestAVAsset(forVideo:options:)` and `PHAssetResourceManager.writeData(...)` with network access enabled. This slice documents that path but does not yet surface a restore-from-iCloud-Photos UI.

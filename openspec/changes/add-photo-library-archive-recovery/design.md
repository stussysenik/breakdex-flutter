# Add Photo Library Archive Recovery — Design

## Product Contract

Breakdex remains the source of truth for moves. Photos album copies are managed projections owned by Breakdex. If a tracked Photos copy disappears externally, Breakdex does not hard-delete the move. Instead it archives the move, removes it from active UI, and makes recovery explicit via Recently Deleted.

## Data Model

Moves gain archive metadata:
- `archived_at`
- `archived_reason`

Archive metadata lives on the move row so restore/permanent-delete flows can use the existing move identity, media metadata, and sync plumbing. Active app surfaces query only non-archived moves. Archive-aware surfaces query archived rows explicitly.

## Native Photos Reconciliation

### Hybrid strategy
Use two reconciliation paths:
- startup/resume pull-based reconciliation for correctness after backgrounding or app relaunch
- live PhotoKit observer events while the app is running

Tracked asset records consist of:
- move ID
- Photos `localIdentifier`
- expected Breakdex album name

The native layer distinguishes:
- `assetDeletedFromLibrary`
- `assetRemovedFromManagedAlbum`

Either case archives the move at the Dart layer.

### Permissions
Saving album copies keeps the current lightweight add-only permission path. Reconciliation and asset restoration require Photos read access. If full album inspection is unavailable, the native layer degrades to asset-existence checks and reports authorization state back to Dart.

## Recovery Path

If a move's local file is missing but its tracked Photos asset still exists, Breakdex can restore the local file from the asset. The native bridge requests an AV asset or asset resource with network access allowed so iCloud-backed videos can materialize locally before export into Breakdex's app storage.

Restore precedence:
1. Use the existing local file if present
2. Rehydrate from tracked Photos asset
3. If neither exists, keep the move archived until the user relinks or permanently deletes it

## UI

Recently Deleted is a focused move-only surface reachable from Settings > Data. It shows archived moves, archive reason, and actions:
- Restore
- Delete Permanently

Restore clears archive metadata after local media is confirmed available or recovered. Permanent delete reuses the existing media cleanup path, then hard-deletes the move row.

## Sync

Move archive metadata syncs through the existing `moves` payload so another device can converge on the archived state once the Supabase schema is updated.

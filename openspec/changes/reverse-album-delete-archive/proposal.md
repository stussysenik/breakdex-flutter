# Reverse Album Delete Archive & Recovery

## Summary

Treat Breakdex as the source of truth while still honoring destructive Photos actions. When a user deletes a Breakdex-managed album copy from Photos, Breakdex should remove the move from active UI by archiving it into a recoverable Recently Deleted state instead of hard-deleting data. The same slice should define how managed Photos asset identity is reconciled and how iCloud-backed Photos assets can be recovered later.

## Motivation

The current media contract is one-way: Breakdex can clean up Photos copies it owns, but external Photos deletion does not flow back into the app. That leaves the app and Albums out of sync and makes the product feel unreliable. Hard-deleting the move immediately would be unsafe because Photos deletion is reversible and may propagate through iCloud. A recoverable archive state is the safer UX and matches how serious media apps separate library truth from exported copies.

## Scope

### In scope
- Detect when a tracked Breakdex-managed Photos asset disappears
- Archive affected moves instead of hard-deleting them
- Remove archived moves from active move/review surfaces
- Add a Recently Deleted screen with restore and permanent delete
- Recreate the managed album copy when restoring an archived move
- Add startup/resume reconciliation and a 30-day purge path for archived moves
- Sync move archive state through Supabase metadata
- Document the iCloud-backed Photos retrieval path for later recovery work

### Out of scope
- Full combo-level archive semantics
- Full UI redesign of Settings or Move Detail
- Automatic re-download of a missing local app file from iCloud Photos in this slice
- Retroactive cleanup of every historical unmanaged Photos copy

## Capabilities

1. `managed-photos-reconciliation` — reconcile tracked Photos asset IDs against the library and archive missing items safely
2. `recently-deleted-moves` — restore or permanently delete archived moves from a recoverable inbox
3. `archive-sync-state` — persist archived move state locally and through Supabase metadata

## Dependencies

- Existing `moves` table and sync metadata flow
- Exact managed Photos asset IDs already stored on moves
- Existing `NativeVideoAlbum`, `MediaCleanupService`, and `MoveRepository` paths
- iOS PhotoKit read/write authorization for reverse reconciliation

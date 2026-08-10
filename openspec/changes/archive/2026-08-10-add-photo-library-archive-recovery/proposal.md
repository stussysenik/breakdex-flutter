# Add Photo Library Archive Recovery

## Summary

Introduce a safe reverse-sync path for Breakdex-managed Photos album copies. When a tracked album copy disappears from Photos, Breakdex should archive the move instead of hard-deleting it, hide it from active drill/list UI, and surface it in a Recently Deleted flow. If the local app video is missing but the managed Photos asset still exists, Breakdex should be able to restore the video from the Photos asset, including iCloud-backed assets.

## Motivation

Today Breakdex only cleans media in the forward direction when the app deletes or replaces a move video. That keeps app-owned cleanup deterministic, but it does not handle the reverse direction: a user can delete a Breakdex-managed album copy in Photos and the UI remains stale. There is also no move-level archive/recovery flow, so the only safe behavior would be to leave broken rows behind. Finally, Breakdex can already import from Photos and iCloud Drive, but it does not yet use the tracked Photos asset identity as a recovery path when the local file disappears.

## Scope

### In scope
- Move-level archive metadata for recoverable reverse-delete handling
- Active move queries that exclude archived rows from drill/list surfaces
- Breakdex-managed Photos asset reconciliation on startup/resume and while the app is active
- Recently Deleted UI for archived moves with restore and permanent delete actions
- iCloud-backed restoration of local move videos from tracked Photos assets
- Validation coverage for archive filtering, reconcile behavior, and native bridge guardrails
- Supabase schema/payload support for syncing move archive state

### Out of scope
- Full combo-level archive/recovery parity
- Retroactive cleanup of every historical unmanaged Photos copy
- Generic Photos browser or user-wide album sync outside Breakdex-managed assets

## Capabilities

1. `photo-library-reverse-sync` — detect when tracked Breakdex Photos copies disappear and archive the corresponding move
2. `recently-deleted-recovery` — restore or permanently delete archived moves from a dedicated UI
3. `icloud-backed-media-restore` — recover a missing local move video from its tracked Photos asset when available

## Dependencies

- Existing managed Photos asset identity on `moves`
- Native `VideoAlbumPlugin` / Dart `NativeVideoAlbum` bridge
- Existing move repository, cleanup service, and sync logging infrastructure

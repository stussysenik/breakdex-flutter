# Clarify Review Loop, Media Cleanup & Color Customization

## Summary

Tighten Breakdex's review experience so it behaves like a clear due-now drill loop instead of a stale state browser. At the same time, fix sync/media cleanup gaps that leave deleted assets behind, and replace preset-only settings color controls with arbitrary color editing.

## Motivation

The current review flow mixes total state counts with active review launch behavior, which makes NEW / LEARNING / MASTERY hard to understand and can make cards feel "stuck" in learning. The app also has split delete paths that do not clean up media consistently, and sync can leave Arsenal rows stale after remote FSRS updates. Finally, settings color controls are restricted to curated presets even though users expect direct customization.

## Scope

### In scope
- Due-only review launcher counts for state-based sessions
- Single-card reveal-first review UI with no swipe preview affordance
- Less aggressive learning-step defaults for the FSRS loop
- Media playback focus rules so covered/non-primary video stops cleanly
- Sync reconciliation between `fsrs_cards` and `moves.learningState`
- Local/remote video cleanup on deletion paths
- Move detail media metadata showing source and album filenames
- Arbitrary accent/rating/category color editing in Settings
- Focused tests covering provider behavior, sync cleanup, and color persistence

### Out of scope
- Full redesign of the deck builder or schedule calendar
- Repo-wide refactors unrelated to review, sync/media, or settings colors
- Guaranteed cleanup of pre-existing Photos album assets without app-managed metadata

## Capabilities

1. `review-loop-ux` — due-only launch counts, reveal-first review flow, clearer state semantics, media focus behavior
2. `sync-media-cleanup` — reconcile stale move state, preserve pending video uploads, clean local/remote assets, surface file metadata
3. `settings-color-customization` — reusable arbitrary color editor for existing settings controls

## Dependencies

- Existing `fsrs_cards`, `moves`, `combos`, and `sync_log` data model
- Existing Flutter/Riverpod review providers and screens
- Existing `VideoService`, `SyncService`, and `VideoAlbumPlugin` integration points

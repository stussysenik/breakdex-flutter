## Why

The app has three clarity leaks that erode trust at critical moments. After exporting a trimmed video, iOS fires a system permission dialog asking for full photo library access — the user reads it as "delete my video." On every cold start, a stale "Recovered N videos" snackbar fires regardless of whether anything was actually recovered this boot. And the settings page presents 7 sections of mixed maturity, half of which are half-baked features that create noise without value.

These are not isolated bugs. They share a root cause: the app does not own its permission model, its notification lifecycle, or its information architecture.

## What Changes

### Fix the export → delete popup
- `VideoAlbumPlugin.swift` `deleteManagedCopies` checks `authorizationStatus` before attempting deletion — never calls `requestAuthorization` mid-operation
- Photo library access is requested as `.readWrite` at first relevant interaction, not lazily upgraded from `.addOnly` mid-export
- Permission status is visible in Settings → Diagnostics

### Eradicate the stale recovery snackbar
- `ManagedAlbumReconcileReport.hasStartupSignal` deduplicates: tracks a dismissed epoch so the snackbar fires only once per actual new discovery batch, never on subsequent cold starts
- Recovery that happens silently in the background stays silent — only actual new recoveries surface a notification

### Revamp settings information architecture
- Archive half-baked features: Cloud Sync (iCloud not finished), redundant diagnostics entries
- Settings reduced to 4 clear sections: **Appearance**, **Library** (categories, photo access), **Review**, **Data** (backup, restore, recently deleted, clear)
- Each section answers one question. No section is a work-in-progress graveyard.

### Harden semantic video storage
- Videos stored at `Moves/{category}/{move_name}/video.mp4` — the file system becomes browsable
- Renames and category changes move the file atomically
- Album exports remain copies; local storage is the source of truth

### Fix UI clarity anti-patterns found in audit
- Video editor: "Cancel" → "Discard" with unsaved-changes confirmation; "Export" → "Save"
- Swipe-to-delete on move/combo rows gains confirmation
- Review "Back" button that abandons session gets a confirmation
- Battle X button gets phase-aware behavior (exit only during idle/complete)
- Settings resets gain confirmation dialogs
- "Remove Video" and "Delete Move" action tiles gain visual separation

## Capabilities

### New Capabilities
- `semantic-video-storage`: Videos stored at `Moves/{category}/{name}/video.mp4`, renames/category changes move the file. File system is browseable.
- `photo-permission-hardening`: `.readWrite` requested at first use, never upgraded mid-operation. Status visible in Settings.
- `export-cleanup-no-dialog`: Post-export album cleanup never triggers system permission dialogs.
- `recovery-notification-dedup`: Recovery snackbars fire only on actual new discoveries, never as stale repeats.
- `settings-ia-revamp`: Settings reduced to 4 essential sections. Half-baked features archived behind a flag.

### Modified Capabilities
- `move-detail-actions`: "Remove Video" and "Delete Move" tiles gain visual separation and confirmation hardening
- `video-editor-ux`: Labels clarified ("Discard" / "Save"), unsaved-changes guard on back navigation
- `review-session`: Dead-end state offers "Skip this move" instead of only "End session"

## Impact

**Files modified:**
- `ios/Runner/VideoAlbumPlugin.swift` — permission guard in `deleteManagedCopies`
- `lib/core/services/managed_album_reconciliation_service.dart` — dedup `hasStartupSignal`
- `lib/core/services/video_path_resolver.dart` — semantic storage paths
- `lib/core/services/move_creation_service.dart` — semantic storage on create
- `lib/core/services/media_cleanup_service.dart` — semantic storage on cleanup
- `lib/features/move_detail/move_detail_screen.dart` — rename/category triggers file move, action tile separation
- `lib/features/video_editor/video_editor_screen.dart` — labels, unsaved-changes guard
- `lib/features/settings/settings_screen.dart` — IA revamp, archived features
- `lib/features/move_list/widgets/move_row.dart` — swipe delete confirmation
- `lib/features/move_list/widgets/combo_row.dart` — swipe delete confirmation
- `lib/features/flashcard_review/flashcard_review_screen.dart` — dead-end skip option, back confirmation
- `lib/features/battle/battle_screen.dart` — phase-aware close

**No breaking API changes.**

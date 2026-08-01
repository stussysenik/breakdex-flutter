# Add Media Manager

## Summary

Introduce a Media Manager screen that provides clear file ownership, location visibility, duplicate detection, and management capabilities. Addresses user confusion about app media vs system gallery and provides privacy/ownership value proposition.

## Motivation

Users are confused about:
- What media belongs to the app vs system gallery
- Where files are stored
- How to manage duplicates
- How to navigate to file locations

Current state:
- MovePhotosSection shows small 120px thumbnails with no metadata
- No file location visibility
- No duplicate detection UI
- FreeSpaceScreen exists for bulk cleanup but no granular control

This blocks App Store launch because the UX doesn't clearly communicate data ownership and privacy.

## Scope

### In scope
- Media Manager screen (Settings → Media Manager)
- File ownership clarity (app media vs system gallery)
- File location visibility (go to location, share, copy path)
- Duplicate detection (same content hash)
- Management actions (delete, share, export per file)
- Privacy messaging (local-first, user-owned)
- Search and filtering (by type, size, date, backup status)

### Out of scope
- Media editing (crop, filter) — use system tools
- Importing from system gallery — already exists
- Cloud storage management — handled by sync settings
- Bulk duplicate resolution — future enhancement

## Capabilities

1. `media-browser` — dedicated screen showing all app-owned media grouped by type
2. `file-ownership` — clear visual distinction between app media, cloud-backed, local-only, orphaned
3. `file-navigation` — go to file location, share, copy path
4. `duplicate-detection` — scan for duplicate hashes, show groups, resolve conflicts
5. `file-management` — per-file actions (view details, delete, share, export)
6. `privacy-messaging` — stats, export all, delete all with safety checks

## Dependencies

- `AssetManifestDao` — all tracked assets
- `SandboxHashIndex` — file location resolution
- `SpaceManager` — size calculations
- File system — actual file existence checks

## Technical Notes

### Data Model
- Assets already tracked in AssetManifest with content hashes
- File locations resolved via SandboxHashIndex (scans Moves/, Combos/ directories)
- Photos stored in .photos/ directory, tracked via move.imagePaths JSON

### UI Components
- `MediaManagerScreen` — main screen with tabs (Videos, Photos, Duplicates)
- `MediaGridItem` — thumbnail card with metadata overlay
- `MediaDetailSheet` — bottom sheet with full details + actions
- `DuplicateGroupCard` — card showing duplicate group with resolve actions

### Safety Guards
- Never delete without cloud backup verification
- Never delete if file is actively used by a move/combo
- Confirmation dialogs for destructive actions
- Soft delete + trash (undo capability)

### Platform Considerations
- iOS: UIDocumentPickerViewController for "show in files"
- Android: Intent.ACTION_VIEW with file URI
- Web: no file system access, show "unavailable" with explanation

## Acceptance Criteria

- [ ] User can see all app-owned media in one place
- [ ] Clear distinction between app media and system gallery
- [ ] File locations are visible and navigable (where supported)
- [ ] Duplicates are detected and showable
- [ ] Per-file actions work (delete, share, export)
- [ ] Privacy messaging is clear from the UI
- [ ] Safety guards prevent accidental data loss

## Tasks

See `tasks.md` for implementation breakdown.

## References

- `lib/core/sync/sandbox_hash_index.dart` — hash-based file lookup
- `lib/core/database/daos/asset_manifest_dao.dart` — asset metadata
- `lib/features/settings/free_space_screen.dart` — existing cleanup UI pattern
- `lib/core/sync/space_manager.dart` — storage analysis

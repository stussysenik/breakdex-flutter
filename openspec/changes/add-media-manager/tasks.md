# Media Manager Tasks

## Phase 1: Data Layer

- [ ] 1.1 Create `MediaManagerProvider` — aggregates assets from AssetManifestDao + SandboxHashIndex
- [ ] 1.2 Add `getOrphanedAssets()` method — assets not associated with any move/combo
- [ ] 1.3 Add `findDuplicates()` method — group assets by contentHash, return groups with >1 item
- [ ] 1.4 Add `resolveFilePath()` — combines SandboxHashIndex + .photos/ directory lookup

## Phase 2: UI Shell

- [ ] 2.1 Create `MediaManagerScreen` — Settings → Media Manager route
- [ ] 2.2 Add tab bar (Videos, Photos, Duplicates)
- [ ] 2.3 Create `MediaGridItem` widget — thumbnail + metadata overlay (size, hash, status icons)
- [ ] 2.4 Implement video tab — grid of video assets with thumbnails
- [ ] 2.5 Implement photos tab — grid of photo assets from .photos/ directory
- [ ] 2.6 Implement duplicates tab — list of DuplicateGroupCard

## Phase 3: File Actions

- [ ] 3.1 Add `MediaDetailSheet` — bottom sheet with full file details
- [ ] 3.2 Implement "Show in Files" — platform-specific file browser navigation
- [ ] 3.3 Implement "Share" — native share sheet with file
- [ ] 3.4 Implement "Copy Path" — copy file path to clipboard
- [ ] 3.5 Implement "Delete" — with safety checks (cloud backup verification, active usage check)

## Phase 4: Duplicate Resolution

- [ ] 4.1 Create `DuplicateGroupCard` — shows group of files with same hash
- [ ] 4.2 Add "Keep one" action — deletes others, keeps most-recently-used
- [ ] 4.3 Add safety check — never delete if no cloud backup

## Phase 5: Search & Filter

- [ ] 5.1 Add search bar — filter by file name, entity name, or hash
- [ ] 5.2 Add filter chips — type (video/photo), size range, backup status
- [ ] 5.3 Implement real-time filtering

## Phase 6: Privacy & Safety

- [ ] 6.1 Add stats header — "X files, Y MB, Z% cloud-backed"
- [ ] 6.2 Add "Export All" button — copy all media to user-visible location
- [ ] 6.3 Add "Delete All" button — with confirmation and safety checks
- [ ] 6.4 Add privacy messaging — "Your files stay on your device"

## Phase 7: Testing & Polish

- [ ] 7.1 Unit tests for data layer (provider, duplicate detection)
- [ ] 7.2 Widget tests for UI components (grid item, detail sheet)
- [ ] 7.3 Integration test for full flow (open → filter → delete)
- [ ] 7.4 Platform testing (iOS, Android, web fallback)

## Acceptance Criteria

- [ ] User can see all app-owned media in one place
- [ ] Clear distinction between app media and system gallery
- [ ] File locations are visible and navigable
- [ ] Duplicates are detected and showable
- [ ] Per-file actions work (delete, share, export)
- [ ] Privacy messaging is clear
- [ ] Safety guards prevent accidental data loss

## Dependencies

- `AssetManifestDao` (existing)
- `SandboxHashIndex` (existing)
- `SpaceManager` (existing)
- Platform file pickers (iOS UIDocumentPickerViewController, Android Intent.ACTION_VIEW)

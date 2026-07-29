## ADDED Requirements

### Requirement: Case-insensitive album pattern matching

The system SHALL detect Photos library albums whose names match any variant of Breakdex naming conventions, regardless of letter case, word separators (space, hyphen, underscore), or date suffix formats.

The match pattern SHALL cover:
- `breakdex` with any case (Breakdex, BREAKDEX, breakdex)
- `break` followed by optional separators then `dex` (Break Dex, break-dex, break_dex)
- `breaking` / `breakin` (legacy naming)
- `bboy` / `bgirl` (legacy dance naming)
- `breakdance` / `breakdancing`
- Dated variants like `Breakdex 05-05-2026` or `Breakdex 2026-05-05`

#### Scenario: Standard case album

- **WHEN** the Photos library contains an album named "Breakdex"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Lowercase album

- **WHEN** the Photos library contains an album named "breakdex"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Mixed case album

- **WHEN** the Photos library contains an album named "BreakDex"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Dated album with MM-DD-YYYY

- **WHEN** the Photos library contains an album named "Breakdex 05-05-2026"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Dated album with YYYY-MM-DD

- **WHEN** the Photos library contains an album named "Breakdex 2026-05-05"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Space-separated legacy name

- **WHEN** the Photos library contains an album named "Break Dex"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Hyphen-separated name

- **WHEN** the Photos library contains an album named "break-dex"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Underscore-separated name

- **WHEN** the Photos library contains an album named "break_dex_videos"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Legacy "breaking" album

- **WHEN** the Photos library contains an album named "Breaking"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Legacy "breakin" album

- **WHEN** the Photos library contains an album named "Breakin"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Legacy "bboy" album

- **WHEN** the Photos library contains an album named "Bboy Practice"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Legacy "bgirl" album

- **WHEN** the Photos library contains an album named "bgirl clips"
- **THEN** the discovery scan SHALL include that album's video assets

#### Scenario: Negation — unrelated album

- **WHEN** the Photos library contains an album named "Vacation 2025" not matching any Breakdex pattern
- **THEN** the discovery scan SHALL NOT include that album's assets

### Requirement: Native iOS case-insensitive album query

The native iOS `VideoAlbumPlugin` SHALL query `PHPhotoLibrary` using case-insensitive predicates when discovering managed assets.

On iOS, `PHFetchOptions.predicate` SHALL use `CONTAINS[c]` modifier to match album titles regardless of case. A secondary full-enumeration fallback SHALL iterate all user collections and test each title with `localizedCaseInsensitiveContains` to catch albums not matched by the predicate query.

#### Scenario: Predicate matches standard album

- **WHEN** the Photos library contains "Breakdex" and discovery runs
- **THEN** `PHFetchOptions` with `CONTAINS[c] "breakdex"` SHALL return that album

#### Scenario: Full enumeration catches edge case

- **WHEN** an album named "My Breakdex 🎯" exists but is not matched by the predicate query
- **THEN** the full enumeration fallback SHALL detect it via `localizedCaseInsensitiveContains`

#### Scenario: Duplicate results are deduplicated

- **WHEN** both the predicate query and full enumeration return the same asset
- **THEN** the result set SHALL contain the asset only once, deduplicated by `localIdentifier`

### Requirement: Album discovery triggers on app lifecycle events

The discovery scan SHALL run on:
1. App cold start (after database initialization)
2. App foreground (on `AppLifecycleState.resumed`)
3. Photos library change notification (`PHPhotoLibraryChangeObserver`)

#### Scenario: Discovery runs on cold start

- **WHEN** the app launches from a terminated state
- **THEN** the album discovery scan SHALL execute within 5 seconds of database readiness

#### Scenario: Discovery runs on foreground

- **WHEN** the app returns to foreground after being backgrounded
- **THEN** the album discovery scan SHALL re-execute

#### Scenario: Discovery triggered by library change

- **WHEN** the user adds a video to a Breakdex album via the Photos app while Breakdex is in background
- **THEN** on foreground, the `PHPhotoLibraryChangeObserver` notification SHALL trigger discovery which SHALL surface the new video

### Requirement: Discovered assets are persisted as moves

Each discovered video asset SHALL be:
1. Copied to the local `Documents/Moves/` directory (with iCloud download handling and timeout)
2. Registered in the `moves` table with `managedAlbumAssetId` set to the PHAsset `localIdentifier`
3. Assigned a thumbnail via the existing 3-tier thumbnail cache

#### Scenario: New asset becomes a move

- **WHEN** an album contains 3 videos and discovery runs for the first time
- **THEN** 3 new rows SHALL be created in the `moves` table, each with a valid `managedAlbumAssetId`

#### Scenario: Already-tracked asset is not duplicated

- **WHEN** an album contains a video already tracked in the `moves` table (matched by `managedAlbumAssetId`)
- **THEN** no duplicate move row SHALL be created

#### Scenario: Asset with iCloud download delay

- **WHEN** a video asset requires iCloud download and the download takes longer than 5 seconds
- **THEN** the system SHALL retry up to 3 times with exponential backoff, then mark the move as `pendingDownload` if still unavailable

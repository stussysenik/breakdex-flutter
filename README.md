<h1 align="center">Breakdex</h1>

<p align="center">
  <em>A pocket video database for dance moves — capture, connect, review, and track.</em>
</p>

<p align="center">
  <a href="https://github.com/stussysenik/breakdex-flutter/actions/workflows/release.yml">
    <img src="https://github.com/stussysenik/breakdex-flutter/actions/workflows/release.yml/badge.svg" alt="Release">
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/license-ISC-blue" alt="License">
</p>

---

## Quick Start

### Prerequisites

| Platform | Requirements |
|----------|-------------|
| All | [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.x |
| iOS | Xcode 16+, CocoaPods, [FlowDeck CLI](https://flowdeck.studio) |
| Android | Android SDK, device or emulator |

### Install

```bash
flutter pub get
```

### Run

```bash
# Debug mode (hot reload)
flutter run

# Release mode on connected device
flutter run --release -d <device-id>
```

### iOS Platform via FlowDeck

FlowDeck manages the native `ios/Runner.xcworkspace` for simulator/device builds and visual verification:

```bash
flowdeck config get --json                  # Check saved workspace config
flowdeck run                                # Build + run on iPhone 16 Pro simulator
flowdeck run --log                          # Build + run with live log streaming
flowdeck test                               # Run iOS native RunnerTests
flowdeck build -C Release                   # Build for release configuration
flowdeck simulator list --json              # List available simulators
flowdeck ui simulator session start \
  -S "iPhone 16 Pro" --json                 # Visual verification via screenshots + accessibility tree
```

---

## Features

### Arsenal
Store moves and combos with category semantics. Video-first creation: pick or record, trim, name, save. Browse by list or gallery, search, filter by category.

### Review
FSRS 2.0 spaced-repetition sessions with four response grades. Deck-based and state-based review modes. Ratings feed the scheduler so timing stays grounded in actual recall.

### Flow
Move-to-move transition graph. Whole-network mapping, single-move focus mode, clustered category inspection, multi-select set creation, and a persistent inspector for connection counts.

### Lab
Project-based training organization. Track sets, milestones, and daily practice with quicklog. An aura system surfaces momentum and consistency.

### Stats
Card counts by learning state, response quality distribution, timeline history, and retention curves. Calendar and heat-map planning surfaces.

### Sync
Supabase-powered cloud backup with connectivity-aware sync. Asset manifest tracking, integrity verification, and offline-first operation.

### Battle
Head-to-head practice mode for comparing moves and combos side by side.

### Settings
Theme, font, categories, sync, and export control. Native iOS share sheet via UIKit bridge.

---

## Screenshots

<table>
  <tr>
    <td align="center"><strong>Arsenal</strong></td>
    <td align="center"><strong>Review</strong></td>
    <td align="center"><strong>Stats</strong></td>
  </tr>
  <tr>
    <td><img src="e2e-screenshots/01-arsenal-tab.png" width="240"></td>
    <td><img src="e2e-screenshots/review-prescreen.png" width="240"></td>
    <td><img src="e2e-screenshots/03-stats-tab.png" width="240"></td>
  </tr>
  <tr>
    <td align="center"><strong>Deck Review</strong></td>
    <td align="center"><strong>Completion</strong></td>
    <td align="center"><strong>Settings</strong></td>
  </tr>
  <tr>
    <td><img src="e2e-screenshots/review-deck-current.png" width="240"></td>
    <td><img src="e2e-screenshots/review-completion.png" width="240"></td>
    <td><img src="e2e-screenshots/04-settings-tab.png" width="240"></td>
  </tr>
</table>

---

## Data Model & Naming

### The database is the source of truth — folders are just storage

Every move and combo lives in a SQLite database (Drift ORM). The folder structure on disk is purely for file storage and does **not** drive the app's behavior. This means:

- **Renaming a move** only updates the `name` column in the database. The video file, its path, and its folder stay exactly as they were. Rename freely — nothing on disk changes.
- **Deleting a move** removes the database row and the sandboxed video copy. Your original source file (Photos, Files, Camera roll) is never touched.
- **Video files are named by UUID** (e.g. `Documents/Moves/a1b2c3d4-e5f6-7890-abcd-ef1234567890.mp4`), not by the move name. The `videoPath` column stores a relative reference (`Moves/uuid.mp4`) that the app resolves at runtime.
- **Self-healing paths**: if iOS changes the app's container UUID (common on reinstall/update), `VideoPathResolver` recomputes the absolute path. If the file is still missing, it scans `Documents/Moves/` and `Documents/videos/` by filename as a last-resort fallback.
- **Content-addressable backup**: `CanonicalFolderService` maintains a content-addressed copy in `Documents/.breakdex-master/videos/` keyed by SHA-256 hash — immune to renames, moves, or UUID changes.

### Resolution chain (when the app needs to play a video)

```
Move row in DB
  └─ videoPath = "Moves/uuid.mp4" (relative)
       └─ VideoPathResolver.toAbsolute()
            └─ /current-container/Documents/Moves/uuid.mp4
                 ├─ File exists? → play it
                 └─ File missing? → resolve() scans disk by filename
```

---

## Video Storage & Cloud Backup

### Your videos are always copies — originals are never touched

Every video you import (from Photos, Files, or Camera) is **copied** into Breakdex's own sandboxed storage at `Documents/Moves/<uuid>.mp4`. The app stores only a **relative path** in its database — never a reference to the original file. After import, your original file in Photos or Files is completely independent and can be safely deleted, moved, or renamed.

### Where do the copies live?

```
/var/mobile/Containers/Data/Application/<UUID>/Documents/
  ├── Moves/                    # Imported videos (UUID-named copies)
  │   └── .thumbs/              # Generated thumbnail cache
  ├── videos/                   # Cloud-downloaded videos (on demand)
  ├── Exports/                  # Manual backup exports
  └── breakdex.db               # SQLite database
```

**This directory is NOT accessible via the iOS Files app or iTunes.** Videos only leave the sandbox through the export paths below.

### What happens when I delete a move?

- **Inside the app**: Only the sandbox copy is deleted. The video thumbnail is cleaned up. If the move had a managed Photos album copy, that is also removed.
- **Your original source file**: Completely untouched. The app never references it after import.

### Cloud backup (iCloud / Google Drive)

| Aspect | Detail |
|--------|--------|
| **Default state** | OFF — no cloud sync unless you manually enable it |
| **iCloud** | Opt-in via Settings > Video Backup > "Tap to enable". Uses your Apple iCloud storage. Uploads to `iCloud Drive/Breakdex/<contentHash>`. |
| **iCloud transparency** | Files are NOT visible in the iOS Files app — the iCloud container lacks `NSUbiquitousContainerDocumentsScope`. Backup is app-internal (restore-only). There is no way to browse or verify backed-up files manually. |
| **Google Drive** | Currently disabled by feature flag (`kGDriveEnabled = false`) |
| **What gets backed up** | Video files only (not the database). Each video is content-addressed by SHA-256 hash — duplicates are deduplicated automatically. |
| **Safety guard** | Videos are only deleted from local storage when at least **2 verified copies** exist (1 local + 1 cloud). A circuit breaker blocks bulk operations affecting >25% of the library. |
| **On-demand download** | If a video was freed by the Space Manager, tapping it in the app triggers automatic cloud re-download. |
| **Manifest sync** | A `manifest.json` of the full library is uploaded to each enabled cloud provider, debounced at 5-second intervals. |

**With iCloud connected**, videos you import are automatically uploaded to iCloud in the background. If you ever reinstall the app or switch devices, enable iCloud again and the sync engine will re-download your library.

**Known gap:** Cloud backup operates on a "trust me" model — users cannot independently verify which files have synced. Making the iCloud container browseable via iOS Files app (adding `NSUbiquitousContainerDocumentsScope`) is a desired improvement.

### How to get your videos OUT of the app

1. **Export to Photos** — per-move: tap the share/export button on any move detail screen. Creates an independent copy in a "Breakdex MM-DD-YYYY" album in your Photos library.
2. **Share sheet** — per-move: native iOS share sheet (AirDrop, Messages, etc.)
3. **Export Full Backup** — Settings > Data > "Export Full Backup". Exports JSON metadata (no video files included — videos must be individually exported or backed up via iCloud).

**Known gap:** No batch "export all to Photos" exists. Currently one-at-a-time only.

### Architecture

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart `^3.11.1`) |
| Storage | Drift (SQLite) with versioned migrations |
| State | Riverpod providers with stream-based reactivity |
| Scheduling | FSRS 2.0 spaced-repetition algorithm |
| Routing | GoRouter with deep linking |
| Auth | Google Sign-In via Supabase |
| Sync | Supabase cloud with offline-aware sync engine |
| Design | Inter font, tokenized color/spacing/type surfaces |
| Native | iOS UIKit bridges for media/share/video |

---

## Development

### Static Analysis

```bash
flutter analyze
```

### Testing

```bash
flutter test                              # Unit & widget tests
flutter test integration_test/            # Integration tests
maestro test .maestro/                    # E2E tests
maestro test --tags=stress .maestro/      # Stress tests
```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS + Xcode required)
flutter build ios --release

# Web
flutter build web --release
```

### FlowDeck iOS Workflow

For iOS platform development, FlowDeck wraps the native Runner workspace:

```bash
flowdeck build                             # Validate iOS build compiles
flowdeck test                              # Run iOS native tests
flowdeck build -C Release                  # Release configuration build
flowdeck run --log                         # Launch with live log streaming
flowdeck logs <app-id>                     # Attach to running app logs
flowdeck ui simulator session start \
  -S "iPhone 16 Pro" --json                # Continuous screenshot + accessibility tree capture
```

---

## Release

Conventional commits pushed to `main` drive [semantic-release](https://github.com/semantic-release/semantic-release) with git tags in `v${version}` format.

```bash
npm ci
npm run release:sync-docs
npm run release:dry-run
```

Commit prefixes: `feat:` (minor), `fix:` / `perf:` (patch), `BREAKING CHANGE:` (major).

---

## License

ISC

<h1 align="center">Breakdex</h1>

<p align="center">
  <em>Breakdex is a way how you can organize your dance knowledge. The exact scenario's, you have some practice fottage in the gallery and you'd like to review them in batch.
  
  We offer a fully customizable expandable modular system.</em>
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
Cloud backup via a provider-agnostic `SyncBackend` contract with offline-first operation, connectivity-aware sync, and record-level LWW reconciliation. Backend direction is **Appwrite** (open-source, self-hostable) — the sync layer is additive over local-first operation.

### Battle
Head-to-head practice mode for comparing moves and combos side by side.

### Settings
Theme, font, categories, sync, and export control. Native iOS share sheet via UIKit bridge.

### Design System & Conformance
Token-pure live showcase (`/dev/design-system`) for inspecting typography, color roles (with brightness × accessibility palette matrix), spacing, radius, depth/shadows, layout bands, and motion curves. Strictly conforms to Face Law design rules.

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

- **Declarative Storage Truth**: The database defines exactly where every file *should* be. If a file is in the wrong place or missing, the `StorageOrchestrator` and `VideoPathHealer` work to materialize it from the content-addressed master or move it to its canonical location.
- **Content-addressable materialization**: `CanonicalFolderService` maintains a content-addressed copy in `Documents/.breakdex-master/videos/ab/cd/hash.mp4` nested by hash. This acts as the immutable source of truth for the library, immune to renames or UUID changes.
- **Renaming a move** updates the database and **atomically moves the video file** to its new semantic path.
- **Deleting a move** removes the database row and the sandboxed video copy. Your original source file (Photos, Files, Camera roll) is never touched.
- **Semantic Storage**: Video files are stored at `Documents/Moves/{category}/{moveName}/video.mp4` (e.g. `Documents/Moves/Power/Windmill/video.mp4`).
- **Self-healing paths**: if iOS changes the app's container UUID, `VideoPathResolver` recomputes the absolute path. If the file is still missing, it scans `Documents/Moves/` and `Documents/videos/` by filename as a last-resort fallback.

### Resolution chain (when the app needs to play a video)

```
Move row in DB
  └─ videoPath = "Moves/Category/Name/video.mp4" (relative)
       └─ VideoPathResolver.toAbsolute()
            └─ /current-container/Documents/Moves/Category/Name/video.mp4
                 ├─ File exists? → play it
                 └─ File missing? → attempt materialization from .breakdex-master/ (Content-Addressable)
                      └─ Materialization failed? → resolve() scans disk by filename
```

---

## Video Storage & Cloud Backup

### Your videos are always copies — originals are never touched

Every video you import (from Photos, Files, or Camera) is **copied** into Breakdex's own sandboxed storage at `Documents/Moves/<uuid>.mp4`. The app stores only a **relative path** in its database — never a reference to the original file. After import, your original file in Photos or Files is completely independent and can be safely deleted, moved, or renamed.

### Storage constraints & automatic cleanup

Breakdex enforces strict boundaries on where videos live and automatically prunes empty directories to keep the filesystem clean:

| Layer | Mechanism | Purpose |
|-------|-----------|---------|
| **Write guard** | `VideoStorageGate` | Rejects any video write outside `Documents/Moves/` or `Documents/.breakdex-master/`. No video file can land in a temporary cache, external volume, or the documents root. |
| **Per-deletion prune** | `VideoService.deleteVideo()` | After deleting a video file and its thumbnail, walks up the directory tree removing empty parent folders up to (but not including) the `Moves/` root. |
| **Startup sweep** | `VideoPathHealer._autoCleanFileSystem()` | Once every 24 hours, recursively walks `Moves/` and deletes any empty subdirectories. Runs after orphan cleanup and case-duplicate folder merging. |
| **Canonical prune** | `CanonicalFolderService` | After removing a ledger entry or deduplicating a moved file, prunes empty hash-nested directories (`ab/cd/`) from `.breakdex-master/videos/`. |
| **Category cleanup** | `StorageOrchestrator._cleanupOldCategoryDir()` | Removes empty category directories (e.g., `Moves/Power/`) after the last move in that category is deleted or moved. |
| **Orphan quarantine** | `VideoPathHealer._cleanupMovesOrphans()` | Archives video files in `Moves/` that have no matching database record to `Moves/Archive/`. |

This layered cleanup ensures the filesystem never accumulates ghost directories. Empty folders are pruned immediately on deletion and swept again at startup — the Documents directory stays exactly as populated as your database contents.

### Where do the copies live?

```
/var/mobile/Containers/Data/Application/<UUID>/Documents/
  ├── Moves/                    # Imported videos (Semantic storage)
  │   └── Power/
  │       └── Windmill/
  │           ├── video.mp4
  │           └── .thumbs/      # Local thumbnail cache
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

Breakdex follows **CLEAN Architecture** principles with a local-first, state-machine-driven stack:

| Paradigm | Technology | Purpose |
|-------|-----------|---------|
| **Domain** | `freezed` (Algebraic Data Types) | Pure entities and strict `Failure` hierarchies — no side effects. |
| **Application** | `Machine<S,E>` (custom sealed-class framework) + `flutter_bloc` (legacy) | State machines orchestrate business logic; impossible states are made impossible at the type level. |
| **Infrastructure** | `fpdart` (`TaskEither`) | Wraps I/O (Drift, platform channels, network) into pure `TaskEither`s; errors declared in return types. |
| **Presentation** | `mix` + `flutter_riverpod` | "Dumb" UI — renders current state; applies CVA-style variant styling via `mix`. |
| **Design System** | `AppScreen`, `TOKENS.md`, Face Law | Live token-pure showcase (`/dev/design-system`), 6-rule chrome essentialism, swappable OKLCH color packs and icon packs. |
| **Storage** | Drift (SQLite) | Versioned local-first data layer — the source of truth. |
| **Sync** | Appwrite (direction; provider-agnostic `SyncBackend` contract) | Additive cloud sync over local-first; LWW + tombstones + dirty-guard. |
| **Scheduling** | FSRS 2.0 | Spaced-repetition algorithm. |

**Web mirror** (`web-mirror/`): Next.js 15 app with XState v5 machines mirroring their Flutter counterparts 1:1. Not yet wired to production data.

---

## Development

### Environment Configuration

The app uses Appwrite as the backend (cloud sync optional). Configuration lives in `.env.local` at the project root:

```bash
# Appwrite (required)
APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1
APPWRITE_API_KEY=<your-key>
APPWRITE_PROJECT_ID=6a50f25b000e15631ad0
APPWRITE_PROJECT_NAME=breakdex-flutter

# Google OAuth (required for authentication)
GOOGLE_WEB_OAUTH_KEYS=<your-key>.apps.googleusercontent.com
GOOGLE_WEB_CLIENT_SECRET=<your-secret>

# Dev test accounts (optional)
DEV0_EMAIL=dev0@breakdex.dev
DEV0_PASSWORD=<password>
OWNER_DEV_PASSWORD=<password>
```

**Note:** `.env.local` is git-ignored. If running for the first time, copy template values from project documentation or request them from the team.

### Prerequisites Setup

```bash
# Install dependencies
flutter pub get

# Generate build files (required after pubspec.yaml changes or Drift schema edits)
dart run build_runner build

# One-time: Install NPM dependencies for release tooling
npm ci
```

### Local Development — Web (Recommended)

**Flutter Web is the fastest dev loop (~41s compile).** Start here:

```bash
# Launch dev server with hot reload on http://localhost:9100
flutter run -d web

# Stop: press 'q' in the terminal
```

Hot reload lets you edit Dart code and see changes instantly without rebuilding. The web version shares the same codebase as mobile — all features work identically.

**Development cycle:**
1. Make a change to any `.dart` file
2. Save the file → hot reload (automatic in VS Code, or press `r` in the terminal)
3. Browser refreshes instantly; local database state persists

### Local Development — iOS Simulator

```bash
# Run on the iOS 26.2 simulator (iPhone 17 Pro)
flutter run

# With verbose logging
flutter run -v

# Hot reload: press 'r' in terminal
# Hot restart (full rebuild): press 'R' in terminal
```

### Static Analysis & Verification

```bash
# Quick verification gate (all checks except full test suite)
./verify.sh --quick

# Full verification including tests
./verify.sh

# Linting — Flutter analyzer
flutter analyze

# Type checking
dart analyze

# Code formatting (auto-fix)
dart format lib/ test/ integration_test/
```

### Testing

```bash
# Unit & widget tests (recommended for pre-commit)
flutter test

# Watch mode (re-run on file changes)
flutter test --watch

# Specific test file
flutter test test/core/state_machines/move_machine_test.dart

# Integration tests (device/emulator required)
flutter test integration_test/

# E2E tests with Maestro
maestro test .maestro/
maestro test --tags=stress .maestro/      # Stress tests
```

### Building for Release

```bash
# Web (recommended for distribution — 41s compile)
flutter build web --release

# Android APK (sideloadable)
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS + Xcode required)
flutter build ios --release

# All platforms at once (CI pattern)
scripts/distribute.sh all --quick
```

### FlowDeck iOS Workflow

For iOS platform development, FlowDeck wraps the native Runner workspace:

```bash
flowdeck config get --json                 # Check saved workspace config
flowdeck run                                # Build + run on iPhone 17 Pro simulator
flowdeck run --log                         # Build + run with live log streaming
flowdeck test                              # Run iOS native RunnerTests
flowdeck build -C Release                  # Release configuration build
flowdeck logs <app-id>                     # Attach to running app logs
flowdeck ui simulator session start \
  -S "iPhone 17 Pro" --json                # Continuous screenshot + a11y tree capture
```

### Common Development Tasks

#### Database Schema Changes

When modifying Drift tables in `lib/core/database/`:

```bash
# Regenerate the database layer
dart run build_runner build

# Clean and rebuild (if incremental fails)
dart run build_runner clean
dart run build_runner build

# Run tests to verify schema migrations
flutter test
```

#### Generating Code (Freezed, Riverpod, etc.)

```bash
# Watch mode — auto-regenerate on file changes
dart run build_runner watch

# One-time generation
dart run build_runner build --delete-conflicting-outputs
```

#### Device Debugging & Logging

```bash
# Web: Open browser DevTools
# In Chrome: Press F12 or Cmd+Option+I → Console tab

# iOS simulator: Print logs to terminal
flutter run -v

# Clear app state (local database reset)
flutter run --purge-persistent-cache

# Clear build artifacts
flutter clean
```

#### Git & Release Workflow

```bash
# Check uncommitted changes
git status

# Pre-commit checks (quick gates)
./verify.sh --quick

# View recent commits
git log --oneline -10

# Release (semantic versioning via conventional commits)
npm run release:dry-run              # Preview next version
npm run release:sync-docs            # Update docs + version
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| **Hot reload not working** | Press `R` (hard restart) instead. If that fails: `flutter clean && flutter run -d web` |
| **Build fails on pubspec.yaml change** | Run `flutter pub get && dart run build_runner build` |
| **DevTools DevTools connectivity** | Ensure no firewall blocks localhost. Try `flutter run -d web --web-port=9101` to use a different port |
| **Database locked / corrupt** | Close the app and delete `.dart_tool/build` and `build/` directories; run `flutter clean` |
| **iOS simulator stuck** | `flowdeck simulator list && flowdeck simulator erase --all && flowdeck run` |
| **Web CORS / auth errors** | Check `.env.local` has correct `APPWRITE_ENDPOINT` and `GOOGLE_WEB_CLIENT_SECRET`; refresh the browser hard-reload (Cmd+Shift+R) |

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

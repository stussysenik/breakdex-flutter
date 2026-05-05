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

## Architecture

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

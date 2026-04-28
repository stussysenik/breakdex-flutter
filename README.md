<h1 align="center">Breakdex</h1>

<p align="center">
  <em>A pocket video database for dance moves, combos, transition mapping, and spaced-repetition review.</em>
</p>

<p align="center">
  <a href="https://github.com/stussysenik/breakdex-flutter/actions/workflows/release.yml">
    <img src="https://github.com/stussysenik/breakdex-flutter/actions/workflows/release.yml/badge.svg" alt="Release">
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/license-ISC-blue" alt="License">
</p>

---

## About

![Demo](demo.gif)

Breakdex combines a move library, combo builder, flow graph, video tooling, deck-based practice, and review analytics into a single Flutter app. It uses FSRS spaced repetition to schedule reviews so you train the moves that are most at risk of decaying.

## Purpose

The product goal is simple: make long-term breaking practice more deliberate. Breakdex is meant to help you collect moves cleanly, understand how they connect, rehearse them on time, and read back the results without scattering your workflow across notes, chat, and camera roll.

## Why It Exists

Most practice systems are good at one slice of the problem and weak at the rest. A move list without scheduling does not protect memory. A flashcard system without video does not match the medium. A graph without analytics is just decoration. Breakdex exists to join those layers into one loop.

## Release Snapshot

<!-- release:meta:start -->
- Release tag: `v1.3.0`
- Release version: `1.3.0`
- Pubspec version: `1.3.0+5`
- Released: `2026-04-28`
- Metadata refreshed: `2026-04-28`
<!-- release:meta:end -->

## Automatic Provenance

<!-- release:provenance:start -->
- Source branch: `main`
- Source revision: `05c0ba3`
- Source commit: `05c0ba33cd86d6f30a845e85bb8fef0e6b266359`
- Source describe: `v1.2.0-11-g05c0ba3`
- Generator: `scripts/update_release_metadata.cjs`
- Inputs: `CHANGELOG.md`, `pubspec.yaml`, and local git metadata
<!-- release:provenance:end -->

### Latest Tagged Notes

<!-- release:notes:start -->
- add clojuredart and openspec changes
- land athlete ux, sync tooling, and research workbench
- make progress graph view immediate
- polish progress graph accessibility
- progress parent-first redesign
<!-- release:notes:end -->

Additional project records:

- [Vision](VISION.MD)
- [Roadmap](ROADMAP.MD)
- [Tech Stack](TECHSTACK.MD)
- [Progress](PROGRESS.MD)
- [Hyperdata Ledger](docs/hyperdata-ledger.md)
- [Architecture Notes](docs/architecture.md)

## How It Works

1. Capture moves and combos with a video-first flow.
2. Link moves through the Flow graph so compatibility becomes visible.
3. Review through FSRS-driven sessions to keep retention moving forward.
4. Use stats and graph context to decide what deserves the next sprint.

## Features

### Arsenal

Store atomic moves and combo sequences with category semantics, searchable in list and gallery views. Creation stays video-first: pick or record, trim, name, and save.

### Review

Run state-based and deck-based sessions with four response grades: Again, Hard, Good, and Easy. Ratings feed the FSRS scheduler so review timing stays grounded in actual recall.

### Flow

Map move-to-move transitions as a graph. The Flow tab supports whole-network mapping, single-move focus mode, clustered category inspection, multi-select set creation, and a persistent inspector for direct connection counts.

### Stats

Track card counts by learning state, response quality distribution, timeline history, and retention curves. The app is moving toward a broader analytics layer that can support calendar and heat-map style planning surfaces.

### Settings

Control theme, font, custom colors, categories, sync, and export behavior from a single place. iOS export/share now uses a native UIKit bridge.

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

## Getting Started

```bash
flutter pub get
flutter run
```

For release mode on a connected device:

```bash
flutter run --release -d <device-id>
```

## Architecture

| Layer | Technology |
| --- | --- |
| Storage | Drift (SQLite) with versioned migrations |
| State | Riverpod providers with stream-based reactivity |
| Scheduling | FSRS 2.0 spaced-repetition algorithm |
| Routing | GoRouter with deep linking |
| Design | Inter font, tokenized color/spacing/type surfaces |
| Native iOS | UIKit bridges for media/share workflows |

## Testing

End-to-end tests use [Maestro](https://maestro.mobile.dev) with tag-based groups:

```bash
maestro test .maestro/
maestro test --tags=stress .maestro/
maestro test .maestro/stress-flow-graph.yaml
```

Run targeted Flutter tests with:

```bash
flutter test
```

INP latency measurement:

```bash
bash scripts/inp-measure.sh
```

## Release

This project uses [semantic-release](https://github.com/semantic-release/semantic-release) with git tags in the `v${version}` format. Conventional commits pushed to `main` drive the pipeline.

Release automation now does all of the following in one path:

1. Analyze commits since the previous tag.
2. Generate release notes and update `CHANGELOG.md`.
3. Update `pubspec.yaml` via `semantic-release-pub`.
4. Refresh release metadata and provenance blocks in `README.md`, `VISION.MD`, `ROADMAP.MD`, `TECHSTACK.MD`, `PROGRESS.MD`, and `docs/hyperdata-ledger.md`.
5. Commit the generated release artifacts and publish the GitHub release.

Useful commands:

```bash
npm ci
npm run release:sync-docs
npm run release:dry-run
```

Commit prefixes: `feat:` for minor releases, `fix:` and `perf:` for patch releases, and `BREAKING CHANGE:` for major releases.

## License

ISC

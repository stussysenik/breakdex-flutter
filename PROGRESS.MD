# Progress

## Table Of Contents

- [Why This File Exists](#why-this-file-exists)
- [Release Snapshot](#release-snapshot)
- [Automatic Provenance](#automatic-provenance)
- [Latest Tagged Notes](#latest-tagged-notes)
- [Current Product Shape](#current-product-shape)
- [Recent Progress](#recent-progress)
- [Active WIP](#active-wip)
- [Next Lanes](#next-lanes)

## Why This File Exists

This file is the working status board for Breakdex. It keeps the product intent, active lanes, and current release line readable in one place so long-term learning work does not turn into scattered notes.

## Release Snapshot

<!-- release:meta:start -->
- Release tag: `v1.1.0`
- Release version: `1.1.0`
- Pubspec version: `1.1.0+3`
- Released: `2026-04-03`
- Metadata refreshed: `2026-04-03`
<!-- release:meta:end -->

## Automatic Provenance

<!-- release:provenance:start -->
- Source branch: `feature/flow-ui-ios-release`
- Source revision: `b88baff`
- Source commit: `b88baffdf8430a60d8ffe797f1f251d7d0d28e58`
- Source describe: `v1.1.0-6-gb88baff`
- Generator: `scripts/update_release_metadata.cjs`
- Inputs: `CHANGELOG.md`, `pubspec.yaml`, and local git metadata
<!-- release:provenance:end -->

### Latest Tagged Notes

<!-- release:notes:start -->
- No tagged release notes found yet.
<!-- release:notes:end -->

## Current Product Shape

| Area | State | Purpose |
| --- | --- | --- |
| Arsenal | Active | Capture and organize moves, combos, and source video. |
| Review | Active | Drive long-term retention with FSRS-based spaced repetition. |
| Flow | Active | Map move transitions, inspect direct compatibility, and build sets from graph selections. |
| Stats | Active | Turn review history into progress signals and planning feedback. |
| Settings | Active | Control theme, color system, sync, export, and device behavior. |

## Recent Progress

| Lane | Status | Why It Matters |
| --- | --- | --- |
| iOS export bridge | Complete | Share/export now routes through a native UIKit sheet instead of a brittle Flutter-only presentation path. |
| Flow clarity pass | Complete | The graph now explains its modes, surfaces honest entity state, and exposes a persistent selection inspector. |
| Accessibility hooks | Active | Progress graph actions, Flow controls, and tab/settings entry points now carry stable identifiers and larger hit targets for automation and assistive tech. |
| Release metadata automation | Active | Semantic release is now configured to update changelog and release metadata docs from the tagged version. |
| Scientific workbench | Active | Python, Julia, and Lisp lanes now exist for exported-data validation, AI tracing, and numerical checks outside the app runtime. |

## Active WIP

| Surface | Status | Current Direction |
| --- | --- | --- |
| Progress | WIP | Parent-first learning structure, immediate graph entry, and superfan analytics kept secondary. |
| Lab | WIP | Explicitly marked in navigation so unfinished planning surfaces do not read as production-final. |
| Flow | WIP | Honest move-first graph with direct inspection and mode-specific guidance instead of fake graph depth. |
| Review | Active | Instrument-panel controls, color-state customization, and quieter playback are being tightened. |

## Next Lanes

| Lane | Intent | Notes |
| --- | --- | --- |
| Combo and set graph nodes | Expand the Flow graph beyond move-only topology. | Current UI marks these as planned instead of pretending they are fully live. |
| Analytics engine | Add calendar, heat map, and richer learning diagnostics. | This is the right place to grow the app's data-driven layer. |
| Native QA | Keep tightening iOS-first behavior while validating cross-platform parity. | Release quality still depends on real-device verification loops. |

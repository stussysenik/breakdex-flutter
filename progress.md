# Progress

## Table Of Contents

- [Why This File Exists](#why-this-file-exists)
- [Release Snapshot](#release-snapshot)
- [Latest Tagged Notes](#latest-tagged-notes)
- [Current Product Shape](#current-product-shape)
- [Recent Progress](#recent-progress)
- [Next Lanes](#next-lanes)

## Why This File Exists

This file is the working status board for Breakdex. It keeps the product intent, active lanes, and current release line readable in one place so long-term learning work does not turn into scattered notes.

## Release Snapshot

<!-- release:meta:start -->
- Release tag: `v1.1.0`
- Release version: `1.1.0`
- Pubspec version: `1.1.0+3`
- Released: `2026-03-31`
- Metadata refreshed: `2026-03-31`
<!-- release:meta:end -->

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
| Accessibility hooks | Active | Flow actions, graph controls, and tab/settings entry points now carry stable identifiers for automation and assistive tech. |
| Release metadata automation | Active | Semantic release is now configured to update changelog and release metadata docs from the tagged version. |

## Next Lanes

| Lane | Intent | Notes |
| --- | --- | --- |
| Combo and set graph nodes | Expand the Flow graph beyond move-only topology. | Current UI marks these as planned instead of pretending they are fully live. |
| Analytics engine | Add calendar, heat map, and richer learning diagnostics. | This is the right place to grow the app's data-driven layer. |
| Native QA | Keep tightening iOS-first behavior while validating cross-platform parity. | Release quality still depends on real-device verification loops. |

# Vision

Breakdex should feel like a serious training instrument for breakers, not a loose pile of media screens and analytics cards.

## Core Mission

The product exists to help a dancer capture a move, understand where it fits, rehearse it on time, and return to the exact next action with as little resistance as possible.

## Primary User

The primary user is an active breaker building a personal library under real fatigue: after practice, between rounds, or while planning the next sprint. They do not want random dashboards. They want a clean path from “what is this?” to “what do I train next?”

## Product Standards

- Video-first workflows should beat text-heavy forms whenever possible.
- Flow and Progress should start from parent structure, then reveal detail.
- WIP surfaces should say they are WIP instead of pretending to be finished.
- Accessibility is product quality, not cleanup. Targets, semantics, contrast, and reading order are part of the feature.
- Analytics should support a training decision, not exist as decoration.

## Practice Loop

1. Capture a move or combo with source media.
2. Place it in category, graph, and review context.
3. Rehearse it through FSRS-backed sessions.
4. Read back the result through Progress, Flow, and planning surfaces.
5. Return to the next concrete sprint with no ambiguity.

## Release Snapshot

<!-- release:meta:start -->
- Release tag: `v1.5.0`
- Release version: `1.5.0`
- Pubspec version: `1.5.0+7`
- Released: `2026-07-29`
- Metadata refreshed: `2026-07-29`
<!-- release:meta:end -->

## Automatic Provenance

<!-- release:provenance:start -->
- Source branch: `main`
- Source revision: `ee10159`
- Source commit: `ee1015952bf854f7e8350d0591918d3d9853fe11`
- Source describe: `v1.4.0-119-gee10159`
- Generator: `scripts/update_release_metadata.cjs`
- Inputs: `docs/CHANGELOG.md`, `pubspec.yaml`, and local git metadata
<!-- release:provenance:end -->

## Latest Tagged Notes

<!-- release:notes:start -->
- **add:** stack choice cards vertically on compact (phone) widths
- **auth:** defer hydrate-on-login state write out of provider build
- **auth:** mobile Google OAuth via token flow — SDK 25.x swallowed callback params
- **boot:** survive an unconfigured Firebase instead of dying before runApp ([8e7f683](https://github.com/stussysenik/breakdex-flutter/commit/8e7f683e666d48c36968f16b17b8ca8d552e36cb)), closes [#0](https://github.com/stussysenik/breakdex-flutter/issues/0) [#1](https://github.com/stussysenik/breakdex-flutter/issues/1)
- **distribute:** never build past a failed gate
<!-- release:notes:end -->

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
- Release tag: `v1.8.0`
- Release version: `1.8.0`
- Pubspec version: `1.8.0+11`
- Released: `2026-08-01`
- Metadata refreshed: `2026-08-01`
<!-- release:meta:end -->

## Automatic Provenance

<!-- release:provenance:start -->
- Source branch: `main`
- Source revision: `2fdd09d`
- Source commit: `2fdd09d9af5f318fe8317692726610040e5e58dc`
- Source describe: `v1.7.0-22-g2fdd09d`
- Generator: `scripts/update_release_metadata.cjs`
- Inputs: `docs/CHANGELOG.md`, `pubspec.yaml`, and local git metadata
<!-- release:provenance:end -->

## Latest Tagged Notes

<!-- release:notes:start -->
- **ui:** the gallery is the wall, not a picture — merge caught it
- **ui:** a bar is either an address or a transaction, and that empties the table
- **ui:** appSheet owns the band-4 inset; 24 sheet sites migrated
- **ui:** detail screens onto AppScreen; back is read from the route, not passed
- **ui:** dialogs get a measure; the band was never their problem ([2cde4af](https://github.com/stussysenik/breakdex-flutter/commit/2cde4afd137c807e860f6af074b33585fd4b757f)), closes [ranked-#1](https://github.com/ranked-/issues/1)
<!-- release:notes:end -->

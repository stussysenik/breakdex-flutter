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
- Release tag: `v1.4.0`
- Release version: `1.4.0`
- Pubspec version: `1.4.0+6`
- Released: `2026-07-13`
- Metadata refreshed: `2026-07-13`
<!-- release:meta:end -->

## Automatic Provenance

<!-- release:provenance:start -->
- Source branch: `main`
- Source revision: `418c550`
- Source commit: `418c55057558bddccc17e5a5f75ad1ff13761727`
- Source describe: `v1.3.0-146-g418c550`
- Generator: `scripts/update_release_metadata.cjs`
- Inputs: `docs/CHANGELOG.md`, `pubspec.yaml`, and local git metadata
<!-- release:provenance:end -->

## Latest Tagged Notes

<!-- release:notes:start -->
- 8 UI clarity fixes from audit
- **a11y:** route Stats reaction-tile rating colors through AppSemanticTheme
- fixed move re-name text edit
- **i18n:** install l10n delegates in widget tests broken by 5.2a/5.2b
- **instax:** repair InstaxVideoCard call sites after ReviewableItem refactor
<!-- release:notes:end -->

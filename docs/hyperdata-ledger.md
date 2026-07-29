# Hyperdata Ledger

> **Manual:** Indexed by the [Breakdex Engineering Manual](manual/index.mdx) →
> [Sync](manual/04-sync.mdx). The manual links here for backfill/ledger detail.

## Purpose

This ledger records what Breakdex is trying to be at the system level: a move library, a practice engine, a transition map, and an analytics surface that all point toward better long-term learning.

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

## Why It Exists

Breaking practice usually fragments into disconnected artifacts: clips in the camera roll, notes in chat, isolated combos, and vague memory. Breakdex exists to make the practice loop explicit: capture a move, place it in a graph, schedule it for review, and read back the results.

## How It Works

1. Capture moves and combos with video-first workflows.
2. Store graph relationships as aura links so transitions can be inspected instead of guessed.
3. Review with FSRS so the system keeps feeding the learner what is about to decay.
4. Read analytics and graph state to decide what deserves the next sprint.

## Product Planes

| Plane | What It Holds | Primary Outcome |
| --- | --- | --- |
| Capture plane | Moves, combos, source media, categories | A clean library of training material |
| Graph plane | Aura links, move adjacency, set construction | Better transition literacy and combo design |
| Review plane | FSRS cards, decks, ratings, review history | Reliable long-term retention |
| Analytics plane | Card state counts, retention curves, timeline data | Better planning and feedback loops |

## Entity Ledger

| Entity | Lives In | Role |
| --- | --- | --- |
| Move | SQLite + media storage | Atomic training unit |
| Combo | SQLite | Ordered sequence of moves |
| Aura link | SQLite | Directed compatibility edge between moves |
| Set / Lab | SQLite | Curated cluster for dedicated sprint work |
| FSRS card | SQLite | Scheduling state for spaced repetition |
| Review event | SQLite | Ground-truth practice history |

## IA Principles

- Keep the app honest about what data is live now versus still planned.
- Prefer direct actions and compact summaries over decorative ambiguity.
- Treat Flow and Stats as planning tools, not just pretty visualizations.
- Keep release metadata and product docs tied to the same versioned automation path.

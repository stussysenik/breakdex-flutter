# Tech Stack

> **Manual:** Indexed by the [Breakdex Engineering Manual](manual/index.mdx) →
> [Product Doctrine](manual/01-product-doctrine.mdx). This file stays the stack inventory.

Breakdex is split into a product runtime, native bridges, release tooling, and a separate scientific workbench.

## Product Runtime

| Layer | Technology |
| --- | --- |
| UI runtime | Flutter 3.x with Material and Cupertino components |
| State | Riverpod providers and stream-driven updates |
| Navigation | GoRouter deep links and route-based surfaces |
| Local data | Drift on SQLite with generated schema and migrations |
| Scheduling | FSRS 2.0 spaced-repetition model |
| Media | Flutter video tooling plus native iOS media bridges |
| Cloud | Supabase-backed sync and auth lanes |

## Native And Device Layer

| Area | Technology |
| --- | --- |
| iOS media import/export | Swift plugins inside `ios/Runner/` |
| Sharing | Native UIKit presentation for export/share flows |
| Device preferences | SharedPreferences-backed local settings |
| Sensors and auth | `sensors_plus`, Google Sign-In, and platform services |

## Quality And Release Tooling

| Area | Technology |
| --- | --- |
| Test harness | `flutter test` and targeted widget/service tests |
| E2E and automation | Maestro flows under `.maestro/` |
| Commit discipline | Conventional commits with commitlint and husky |
| Release pipeline | `semantic-release`, `semantic-release-pub`, changelog automation |
| Doc provenance | `scripts/update_release_metadata.cjs` |

## Scientific Workbench

| Lane | Technology | Role |
| --- | --- | --- |
| Python | `uv`, DSPy, LangChain, LangSmith | AI tracing and exported-data analysis |
| Julia | Julia project environment | Numerical verification |
| Lisp | SBCL scripts | Symbolic and NLP experiments |

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

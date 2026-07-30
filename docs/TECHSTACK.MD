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
- Release tag: `v1.7.0`
- Release version: `1.7.0`
- Pubspec version: `1.7.0+10`
- Released: `2026-07-30`
- Metadata refreshed: `2026-07-30`
<!-- release:meta:end -->

## Automatic Provenance

<!-- release:provenance:start -->
- Source branch: `main`
- Source revision: `8c81252`
- Source commit: `8c81252584ad51b1b0cfc8afbff7394f836aa6cb`
- Source describe: `v1.6.1-11-g8c81252`
- Generator: `scripts/update_release_metadata.cjs`
- Inputs: `docs/CHANGELOG.md`, `pubspec.yaml`, and local git metadata
<!-- release:provenance:end -->

## Latest Tagged Notes

<!-- release:notes:start -->
- **diagnostics:** failures report honestly
- **dev:** preview gallery route
- **theme:** overlay owns error
<!-- release:notes:end -->

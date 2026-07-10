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

## Latest Tagged Notes

<!-- release:notes:start -->
- add clojuredart and openspec changes
- land athlete ux, sync tooling, and research workbench
- make progress graph view immediate
- polish progress graph accessibility
- progress parent-first redesign
<!-- release:notes:end -->

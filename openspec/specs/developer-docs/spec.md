# developer-docs Specification

## Purpose
TBD - created by archiving change add-engineering-manual-and-docs-ledger. Update Purpose after archive.
## Requirements
### Requirement: A canonical MDX engineering manual lives at `docs/manual/`

The repo SHALL maintain a canonical engineering manual as MDX chapters under
`docs/manual/`, written as the codebase's technical reference (language-book register:
normative, example-grounded). It SHALL cover, at minimum: product doctrine (move → combo
→ set atom model), `Machine<S,E>` state architecture, the data layer (Drift schema,
DAOs, three-layer repositories), sync (SyncBackend contract, LWW + tombstones,
dirty-guard, upload spool, Appwrite topology), the design system (tokens index, Fluid/
Morph motion doctrine), localization, platform seams (dart:io seam, web/WASM), testing &
verification standards, and release hygiene. Chapters SHALL be meaningful as plain text
(CommonMark + frontmatter; JSX as progressive enhancement only).

#### Scenario: Fresh-session student executes without re-deriving intent

- **GIVEN** a fresh agent session primed with only the manual and a change's `tasks.md`
- **WHEN** the next unticked task touches a documented seam (e.g. adds a `Machine` event)
- **THEN** the manual names the seam's files, invariants, and review standards, and the
  executor proceeds without re-deriving architecture from source archaeology

#### Scenario: Absorb-or-index, never duplicate

- **GIVEN** a topic with an existing canonical doc (e.g. `docs/design/TOKENS.md`)
- **WHEN** its manual chapter is authored
- **THEN** the chapter indexes/links the canonical source and states only what it adds
  (context, standards), duplicating no normative content

### Requirement: Staff-level standards chapters are normative and citable

The manual SHALL include standards chapters consolidating the repo's review checklists
(motion-token conformance, l10n grep gate, data safety, brownfield rules) and staff-level
mobile engineering standards (state, rebuilds, async, disposal, essentialist diff
discipline) into numbered, citable rules.

#### Scenario: A review cites a standard by number

- **WHEN** a reviewer flags a raw `Curve` literal on a product surface
- **THEN** the finding cites the manual standard (e.g. `standards.md#motion-1`) rather
  than restating the rule

### Requirement: Manual updates ride the same change as the seam they document

A change that alters a documented seam SHALL update the corresponding chapter and its
ledger frontmatter in the same commit that lands the seam change (same-commit ledger
rule extended to the manual).

#### Scenario: Seam change without chapter update is a review violation

- **GIVEN** a commit changing the `SyncBackend` contract
- **WHEN** the sync chapter's content and `verified` frontmatter are untouched
- **THEN** review flags it, and the docs-ledger drift check fails in CI


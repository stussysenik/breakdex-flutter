# Spec: Add Design-System Showcase Page

> **Language: Dart (Flutter Web, the #1 product surface).** Depends on:
> `enforce-face-law-conformance`, `add-color-packs`, `add-icon-system-and-packs`.
> Implementation in a fresh student session — never this one.

This spec defines the design-system showcase page: one surface that composites every
TOKENS.md category into a dense, grid-based layout optimized for least eye-travel
distance, and demonstrates the system across its brightness × accessibility-palette
variants so the whole design system is sign-off-able in one view. Where it is silent on
token semantics, `docs/design/TOKENS.md` is normative.

Module layout (additive):
- `lib/features/design_showcase/` — the showcase `AppScreen` + region widgets.
- `lib/features/design_showcase/data/` — token-sample model (which tokens render where).

## ADDED Requirements

### Requirement: Composite-showcase-layout

The app SHALL provide a single showcase surface that composites every TOKENS.md
category — color, typography, spacing, radius, depth, shadows, layout, motion — into
one dense, grid-based layout on a single scroll axis. Each token SHALL render as an
inline triple of `[name | value | live preview]` so label, value, and preview are
adjacent (least eye-travel). Related categories SHALL sit in neighboring regions.

#### Scenario: All categories render on one page
- **WHEN** the showcase page opens
- **THEN** color, typography, spacing, radius, depth, shadows, layout, and motion are
  all visible on one scrollable `AppScreen` (column form)

#### Scenario: Tokens render as inline triples
- **WHEN** a token row renders
- **THEN** the token name, its code value, and its live preview are adjacent on one row
  (no whitespace gap requiring the eye to drift)

#### Scenario: One scroll axis
- **WHEN** the reader navigates the page
- **THEN** there is exactly one scroll axis — no tabs, no nested scrollers, no
  carousels (Face Law one-scroll rule)

#### Scenario: Reading clamp is respected
- **WHEN** a reading region (typography, layout) renders
- **THEN** it is clamped to `maxContentWidth` (720); the dense color grid is clamped to
  `maxWideWidth` (1080)

### Requirement: Live-token-render

Every sample on the page SHALL render from the real token constants (`AppColors` via
the role system, `AppSpacing`, `AppLayout`, `AppRadius`, `AppMotion`, `AppTypography`,
`AppDepth`, `AppShadows`), never from a hardcoded duplicate. The page SHALL contain zero
raw color, spacing, radius, duration, or curve literals.

#### Scenario: Color swatches resolve from the role system
- **WHEN** a color tile renders
- **THEN** its swatch resolves from the active `AppColorRole` through the active pack +
  brightness + accessibility overlay (not a hardcoded hex)

#### Scenario: A token drift is visible
- **WHEN** a token constant's value is edited
- **THEN** the rendered preview on the showcase no longer matches the row's stated value,
  making the drift immediately visible

#### Scenario: No raw literals
- **WHEN** the feature is built
- **THEN** `lib/features/design_showcase/` contains no raw color/spacing/radius/duration/
  curve literal — every value resolves from a named token

### Requirement: Rollout-variant-matrix

The page SHALL provide a variant rail that toggles brightness (light/dark) and
accessibility palette (standard/deuteranopia/monochrome) and re-renders the color
region in place, so the full design system is sign-off-able across all three palettes
without leaving the page.

#### Scenario: Brightness toggle re-renders color
- **WHEN** the reader flips the brightness rail
- **THEN** the color region re-renders all roles under the selected brightness in place
  (no page navigation)

#### Scenario: Palette toggle re-renders color
- **WHEN** the reader selects a different accessibility palette
- **THEN** the color region re-renders all roles under the selected palette, confirming
  the overlay wins (deuteranopia shows the Okabe–Ito ramp; monochrome collapses signals
  to ink)

#### Scenario: All three palettes are sign-off-able in one view
- **WHEN** the owner reviews the page for rollout
- **THEN** they can verify standard, deuteranopia, and monochrome without leaving the
  page — the three versions are confirmed ready in one sitting

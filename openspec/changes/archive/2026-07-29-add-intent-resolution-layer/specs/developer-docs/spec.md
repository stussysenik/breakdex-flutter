# developer-docs Specification

## MODIFIED Requirements

### Requirement: A canonical MDX engineering manual lives at `docs/manual/`

The repo SHALL maintain a canonical manual as MDX chapters under `docs/manual/`, written as
the codebase's reference (language-book register: normative, example-grounded), in **two
halves under one authoring contract**.

The **engineering half** SHALL cover, at minimum: product doctrine (move → combo → set atom
model), `Machine<S,E>` state architecture, the data layer (Drift schema, DAOs, three-layer
repositories), sync (SyncBackend contract, LWW + tombstones, dirty-guard, upload spool,
Appwrite topology), the design system (tokens index, Fluid/Morph motion doctrine),
localization, platform seams (dart:io seam, web/WASM), testing & verification standards, and
release hygiene.

The **business half** SHALL cover, at minimum: positioning and the product wedge, growth and
activation, GTM/pricing/packaging, forward-deployed (what an invited user experiences end to
end), and the metrics contract. Both halves SHALL use the same frontmatter, the same
`watches:` ledger, and the same drift gate. Chapters SHALL be meaningful as plain text
(CommonMark + frontmatter; JSX as progressive enhancement only).

#### Scenario: Fresh-session student executes without re-deriving intent

- **GIVEN** a fresh agent session primed with only the manual and a change's `tasks.md`
- **WHEN** the next unticked task touches a documented seam (e.g. adds a `Machine` event)
- **THEN** the manual names the seam's files, invariants, and review standards, and the
  executor proceeds without re-deriving architecture from source archaeology

#### Scenario: A pricing task resolves to a ruling rather than an escalation

- **GIVEN** a task touching offering tiers or invite-code entitlement
- **WHEN** the session resolves the intent before starting
- **THEN** the GTM chapter names the offering band, the merchant-of-record ruling, and the
  cohort model, and the session proceeds without asking the owner

#### Scenario: Absorb-or-index, never duplicate

- **GIVEN** a topic with an existing canonical doc (e.g. `docs/design/TOKENS.md`)
- **WHEN** its manual chapter is authored
- **THEN** the chapter indexes/links the canonical source and states only what it adds
  (context, standards), duplicating no normative content

## ADDED Requirements

### Requirement: A business chapter names the decision surface it is truth about

Every business-half chapter SHALL declare a non-empty `watches:` list pointing at the code
that implements its rulings (for example: pricing/offering config and entitlement logic for
the GTM chapter; instrumentation emit sites for the metrics chapter). A chapter that can name
no such surface SHALL NOT be published in the manual; it belongs in `READINGS.md` as evidence
or in a change proposal as intent.

#### Scenario: An aspirational chapter is rejected

- **GIVEN** a proposed chapter describing a growth funnel that no shipped code emits events for
- **WHEN** it is authored with an empty `watches:` list
- **THEN** the gate fails and the content is filed as a reading or a proposal instead

#### Scenario: A thin chapter is preferred to a rich fiction

- **GIVEN** instrumentation covers only part of the activation funnel
- **WHEN** the growth chapter is authored
- **THEN** it documents only the instrumented part and names the uninstrumented remainder as
  a gap, rather than describing a funnel the product does not measure

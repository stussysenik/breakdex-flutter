# product-manual Specification

## ADDED Requirements

### Requirement: Product positioning chapter

A `docs/manual/13-product-positioning.mdx` chapter SHALL document breakdex's product
positioning. It SHALL cover:

- The atom model as a market position rather than a technical architecture
- Visual-first as a differentiator
- Beachhead vs expansion thesis and the expansion criteria
- Competitive landscape — what breakdex is NOT
- How product doctrine maps to market positioning

It SHALL carry frontmatter with `domain: product`, `watches:` covering `docs/VISION.MD`,
`docs/PRD.md`, and product copy source files. It SHALL index (not duplicate)
`docs/VISION.MD` and `docs/PRD.md`.

#### Scenario: New session understands the competitive position

- **GIVEN** a fresh session tasked with a feature that encroaches on a competitor's territory
- **WHEN** the session reads chapter 13
- **THEN** it determines whether the feature is in-bounds or out-of-bounds by the
  positioning chapter's competitive-landscape section, without asking the owner

### Requirement: Growth model chapter

A `docs/manual/14-growth-model.mdx` chapter SHALL document the product's growth
model. It SHALL cover:

- The full user journey: discover → onboard → practice → improve → share
- Retention levers and the practice-fidelity feedback loop
- Viral loops and the content flywheel
- Activation criteria and leading indicators

It SHALL carry frontmatter with `domain: product`, `watches:` covering analytics event
schemas, the onboarding flow, and any experiment-flag schema.

#### Scenario: Growth experiment is evaluated against the documented model

- **GIVEN** an owner asks "will this experiment improve retention?"
- **WHEN** the experiment's mechanism is checked against the growth model's documented levers
- **THEN** the experiment either maps to a named lever (measurable) or is outside the model

### Requirement: GTM and pricing chapter

A `docs/manual/15-gtm-and-pricing.mdx` chapter SHALL document go-to-market strategy
and pricing rationale. It SHALL cover:

- Distribution strategy and platform priority
- The invite-code cohort model
- Monetization tiers and the rationale for the $4.20–$9.99 USD range
- Platform merchant-of-record strategy
- Remote config and feature gating
- The release gate as a GTM instrument

It SHALL carry frontmatter with `domain: gtm`, `watches:` covering
`docs/design/TOKENS.md` (distribution section), remote config schemas,
`scripts/distribute.sh`, and any pricing configuration files.

#### Scenario: Pricing rationale is recoverable without archaeology

- **GIVEN** an owner considering a price change
- **WHEN** they or an agent reads chapter 15
- **THEN** the original rationale for each price point is documented

### Requirement: Forward-deployed and on-call chapter

A `docs/manual/16-forward-deployed.mdx` chapter SHALL document how the product
is operated and how decisions get made. It SHALL cover:

- Product decision-making authority (owner-driven model)
- The release gate and what each gate proves / does not prove
- The three session lanes and their boundaries
- Brownfield invariants
- What constitutes a page-worthy incident vs ordinary bug-fix work

It SHALL carry frontmatter with `domain: business`, `watches:` covering
`scripts/distribute.sh`, `scripts/verify_ledger.sh`, `scripts/docs_ledger_check`,
and `CLAUDE.md`.

#### Scenario: Fresh session knows its authority boundary

- **GIVEN** a student session assigned a task that requires a live Appwrite credential
- **WHEN** the session reads chapter 16
- **THEN** it identifies the task as owner-gated and stops

### Requirement: Metrics and observability chapter

A `docs/manual/17-metrics-and-observability.mdx` chapter SHALL document what the
project measures and how it observes itself. It SHALL cover:

- Key business metrics and the specific instrumentation that produces each
- Diagnostics infrastructure: the board, the cumulative gate, the diagnostics log
- The board as a health signal — what it measures and what it does not
- What is explicitly NOT measured, with rationale

It SHALL carry frontmatter with `domain: business`, `watches:` covering diagnostics
services, analytics DAOs, health-check scripts, and metrics documentation.

#### Scenario: A new metric is defined consistently

- **GIVEN** an owner or session wants to add a metric
- **WHEN** they read chapter 17
- **THEN** they know which existing metrics use the same instrumentation approach

### Requirement: Index integration

The manual index (`docs/manual/index.mdx`) SHALL gain a "Product & Business" section
listing chapters 13–17 alongside the existing engineering reading-order table.

#### Scenario: Product chapters appear in the manual index

- **GIVEN** `docs/manual/index.mdx` after Phase 3 lands
- **WHEN** read by any session
- **THEN** chapters 13–17 appear in the reading-order table

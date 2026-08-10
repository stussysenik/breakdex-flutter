# Spec: Distribution Prep — Web Release Readiness

> **Language: Dart (Flutter) + shell (YAML/CI).** Depends on:
> `add-web-first-release-and-monetization` (pricing/offering rulings), `appwrite`
> (entitlement + remote config). Implementation in a fresh student session — never
> this one.

This spec defines the owner-provisioned offering config, the admin invite-mint
capability, and the release-handoff artifact that together make the web release
repeatable and owner-operable. Where it is silent on pricing/cohort rulings, the
`add-web-first-release-and-monetization` spec is normative (Lemon Squeezy,
$4.20–$9.99 USD, web merchant-of-record). Where it is silent on selectors, the
Face-Law conformance spec (`enforce-face-law-conformance`) is normative.

Module layout (additive):
- `lib/core/config/offerings_config.dart` — typed offering config + resolve ladder.
- `lib/core/config/widgets/` — purchase flow reads config; disables when absent.
- Appwrite Function `invites-mint` — owner-scoped mint + bind + persist.
- `docs/web-release-handoff.md` — per-release handoff template + checklist.

## ADDED Requirements

### Requirement: Offering ids are owner-provisioned, never hardcoded

The repo SHALL read Lemon Squeezy offering ids and price variants from
owner-supplied config, never from literals in implementation code. The config
SHALL resolve remote-first (runtime override), then build-time env
(`--dart-define=OFFERINGS_JSON`), then **absent**. When absent, paid purchase flows
SHALL remain disabled or hidden, and the release checklist SHALL name the missing
owner action rather than failing ambiguously.

#### Scenario: Offering ids configured and present
- **GIVEN** offering ids are supplied via `--dart-define=OFFERINGS_JSON` (or remote
  override)
- **WHEN** the purchase flow builds
- **THEN** it resolves the configured offering id per tier and renders the paid path

#### Scenario: Offering ids absent (safe default)
- **GIVEN** no offering id is supplied via env or remote
- **WHEN** the purchase flow builds
- **THEN** paid flows are disabled or hidden and no checkout can be initiated with a
  placeholder id

#### Scenario: Remote override without rebuild
- **GIVEN** a build shipped with env-supplied ids, then the owner publishes a remote
  `offerings` override for a cohort
- **WHEN** a user in that cohort opens the purchase flow
- **THEN** the resolved id is the remote override, not the compiled env value

#### Scenario: Malformed config degrades safely
- **GIVEN** the env or remote value is malformed JSON or missing a required tier
- **WHEN** `OfferingsConfig.resolve()` runs
- **THEN** it returns absent for the affected tier (never throws, never substitutes a
  guess) and that tier's paid flow is disabled

### Requirement: Admin invite-code minting bound to tier and cohort

The repo SHALL provide an owner-scoped mint capability that creates a private invite
code, binds it to a specific entitlement tier and config cohort, persists it, and
returns a traceable release record (code, tier, cohort, timestamp). Minting SHALL
NOT be callable by a regular client — only the redeem path (`EntitlementService`
.redeem) is client-facing. The minted code SHALL be redeemable through the existing
redeem flow and SHALL appear in release records.

#### Scenario: Owner mints an invite for a tier + cohort
- **GIVEN** the owner is authenticated and authorized
- **WHEN** they invoke the mint capability for tier `pro`, cohort `beta`
- **THEN** a code is generated, persisted with `status: reserved`, and a release
  record `(code, pro, beta, <timestamp>)` is returned

#### Scenario: Mint is not client-callable
- **GIVEN** a regular (non-owner) signed-in user
- **WHEN** they attempt to invoke the mint capability
- **THEN** it is rejected by server-side auth before any row is written

#### Scenario: Minted code redeems through existing flow
- **GIVEN** a code minted for tier `pro`, cohort `beta`
- **WHEN** a user redeems it via `EntitlementService.redeem`
- **THEN** it grants an `Entitlement(tier: pro, cohort: beta, source: invite)` and the
  code status transitions to redeemed

#### Scenario: Duplicate mint is idempotent per (tier, cohort) batch
- **GIVEN** the owner mints 5 codes for the same tier + cohort
- **WHEN** the batch completes
- **THEN** 5 distinct codes are persisted, each independently traceable

### Requirement: Per-release handoff artifact with rollback path

The repo SHALL provide a `docs/web-release-handoff.md` template that records, for a
given release: the commit, build version, device matrix, sync proof, deploy URL,
known risks, and rollback path. A release checklist SHALL gate the release on:
offering ids configured, at least one invite minted per released tier, `verify.sh`
green, and deploy URL recorded. The rollback path SHALL name both the Vercel Instant
Rollback (incident) and tag-rebuild (tag-of-record) paths described in
`docs/web-deploy.md`.

#### Scenario: Handoff produced for a release
- **GIVEN** `verify.sh` is green and offering ids are configured
- **WHEN** the owner prepares the release
- **THEN** a filled handoff document is produced naming commit, build, deploy URL,
  and the rollback path

#### Scenario: Checklist gates on missing offering config
- **GIVEN** offering ids are absent
- **WHEN** the owner attempts to clear the release checklist
- **THEN** the checklist refuses and names "configure offering ids" as the blocking
  action — it does not self-grade

#### Scenario: Rollback path is written, not assumed
- **GIVEN** a release is live and an incident requires rollback
- **WHEN** the owner consults the handoff
- **THEN** the rollback path (Instant Rollback vs tag-rebuild) and the target
  previous-good tag are documented

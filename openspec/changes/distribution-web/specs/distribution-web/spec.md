## ADDED Requirements

### Requirement: Web deployment is secret-gated
The web deployment pipeline SHALL build the Flutter web app and deploy to Vercel only when
the required Vercel secrets are configured.

#### Scenario: Vercel secrets missing
- **WHEN** the deploy workflow runs without required Vercel secrets
- **THEN** it skips live deployment and emits an owner-actionable warning instead of
  failing ambiguously

### Requirement: Monetization variants are owner-provisioned
Lemon Squeezy offering ids and price variants SHALL be treated as owner-provisioned release
inputs, not invented by implementation code.

#### Scenario: Offering ids absent
- **WHEN** monetization code runs without configured offering ids
- **THEN** paid purchase flows remain disabled or hidden and the release checklist names
  the missing owner action

### Requirement: Invite-code release path
The release system SHALL support minting and sending private invite codes that bind
entitlement and config cohort.

#### Scenario: Invite code issued
- **WHEN** the owner mints an invite for a tester
- **THEN** the generated code is associated with the intended entitlement/cohort and can
  be traced through release records

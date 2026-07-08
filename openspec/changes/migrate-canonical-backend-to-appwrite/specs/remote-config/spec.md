# remote-config

> Added 2026-07-08 (owner ruling: config-first live updates; Shorebird code-push deferred to a
> flagged post-launch evaluation). Rides the Appwrite provisioning from Phases 0–1.

## ADDED Requirements

### Requirement: Server-driven runtime configuration

The system SHALL serve a versioned runtime configuration document from the canonical backend
containing minimum supported build, latest build, update messaging, feature flags, kill-switches,
and per-cohort flag profiles. Clients SHALL fetch it at launch and subscribe to live updates,
falling back to the last cached value and then to compiled defaults when offline. With all values
at defaults, client behavior SHALL be unchanged.

#### Scenario: Flag flip reaches a running client without redeploy
- **WHEN** the owner changes a feature flag in the backend console
- **THEN** a running client observes the new value via the realtime subscription without an app update

#### Scenario: Offline launch falls back safely
- **WHEN** a client launches with no network
- **THEN** it uses the last cached config, or compiled defaults if none is cached, and the app remains fully usable

### Requirement: Config-driven update gate

The system SHALL compare the running build number against the config's minimum supported build and
present update messaging (soft nag or hard block, per config) sourced from the config document,
linking the user-facing upgrade guide. The gate SHALL never trigger while the running build
satisfies the minimum.

#### Scenario: Outdated build is prompted to update
- **WHEN** a client whose build is below `minSupportedBuild` launches
- **THEN** it shows the configured update message and, if configured as a hard block, prevents further use until updated

#### Scenario: Current build is never gated
- **WHEN** a client whose build satisfies `minSupportedBuild` launches
- **THEN** no update prompt is shown

### Requirement: Cohort configuration profiles

The system SHALL support named cohort profiles inside the configuration document that override
default feature flags for users bound to that cohort (via invite-code redemption), so distinct
experiences ("own versions") ship from one binary without per-cohort builds.

#### Scenario: Cohort member gets its profile
- **WHEN** a user whose account is bound to cohort `crew` fetches config
- **THEN** the effective flags are the defaults overlaid with the `crew` profile

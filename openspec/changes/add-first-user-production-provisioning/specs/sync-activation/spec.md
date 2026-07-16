# sync-activation

Production first-login provisioning and per-entity dual-read/dual-write activation for
single-owner (and every subsequent) users. Local Drift is the source of truth; Appwrite is
the shadow replica. Identity is the Appwrite `userId`.

## ADDED Requirements

### Requirement: Remote-config-gated sync activation
The system SHALL gate all production sync activation behind an `appConfig.syncActivationEnabled`
flag that defaults to `false`, so that with the flag unset the app is byte-identical to a
pre-activation build (no backfill, no dual-read, no dual-write).

#### Scenario: Gate off — no activation
- **WHEN** a user establishes an Appwrite session and `syncActivationEnabled` is false (or unresolved/session-less)
- **THEN** no backfill runs, dual-read and dual-write prefs stay `false`, and behavior is unchanged from today

#### Scenario: Gate on — activation eligible
- **WHEN** a user establishes a session and `syncActivationEnabled` is true
- **THEN** the first-login provisioning path becomes eligible to run (subject to the one-shot guard)

### Requirement: First-login provisioning is one-shot per user
The system SHALL run provisioning at most once per Appwrite `userId`, tracked by a
per-user one-shot flag, so that re-launches and re-logins never re-trigger an automatic backfill.

#### Scenario: First eligible login provisions
- **WHEN** the gate is on and no `sync.provisioned.$userId` flag is set
- **THEN** the system runs the full backfill for all 8 entities, flips dual-write and dual-read on, and sets the one-shot flag

#### Scenario: Subsequent logins are no-ops
- **WHEN** the gate is on and `sync.provisioned.$userId` is already set
- **THEN** the system performs no backfill and leaves the (already-on) prefs unchanged

#### Scenario: Distinct users each provision once
- **WHEN** a second Appwrite `userId` signs in on the same device
- **THEN** that user provisions independently (its own one-shot flag), isolated from the first user's space

### Requirement: Activation is all-or-nothing
The system SHALL treat activation as transactional: if backfill fails, dual-read/dual-write
prefs remain off and the one-shot flag is NOT set, so the next launch retries cleanly with
no partial activation.

#### Scenario: Backfill failure leaves user un-activated
- **WHEN** the backfill throws during provisioning
- **THEN** dual-read and dual-write stay `false`, the one-shot flag stays unset, and provisioning is retried on the next launch

### Requirement: Provisioning writes to the signed-in user's isolated space
The system SHALL stamp all backfilled rows with the signed-in `userId`'s per-user permissions,
and all reads SHALL filter to that `userId`, so no user can read or write another's rows.

#### Scenario: Owner provisions under the Google identity
- **WHEN** the owner signs in with Google as the canonical account and provisioning runs
- **THEN** every backfilled row is owner-only permissioned to that `userId` and is invisible to any other user

#### Scenario: Idempotent replay
- **WHEN** provisioning (or a manual backfill) runs a second time for the same user
- **THEN** rows are reconciled by logical `(userId, id)` with last-writer-wins and no duplicate rows are created

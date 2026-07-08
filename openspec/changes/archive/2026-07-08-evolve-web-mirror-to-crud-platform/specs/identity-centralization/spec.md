# identity-centralization

## ADDED Requirements

### Requirement: Single account for identity and media

The system SHALL use a single Google account (`senik456@gmail.com`) as the home for both identity
and the globally-synced media Drive, used on the phone's Drive sync and the web sign-in alike, so
that exactly one Drive holds the canonical media. The owner allowlist SHALL be updated to reflect
the centralized account.

#### Scenario: Web and phone resolve the same Drive
- **WHEN** the owner signs in on web and the phone syncs media
- **THEN** both operate against the same account's Drive and see the same media set

#### Scenario: Allowlist reflects the centralized account
- **WHEN** an account not designated as the owner attempts to sign in
- **THEN** it is denied at the auth gate

### Requirement: Branded login defaulting to Google

The web app SHALL present a Breakdex-branded entry that initiates sign-in via Google by default,
because Drive access depends on the Google OAuth credential. A non-Google login that cannot yield
a Drive token SHALL NOT be offered as a path to library data.

#### Scenario: Branded entry initiates Google sign-in
- **WHEN** an unauthenticated visitor opens the app
- **THEN** they see the Breakdex-branded entry whose primary action begins Google sign-in

### Requirement: Migration to the centralized account is non-destructive

Moving media to the centralized account SHALL copy-then-verify each file and re-point the
canonical index, and SHALL NOT delete media from the prior account until the move is verified.

#### Scenario: Account migration preserves media
- **WHEN** media is migrated to the centralized account
- **THEN** every file is copied and verified before any source file is considered removable

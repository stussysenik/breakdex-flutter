# dev-auth

## ADDED Requirements

### Requirement: Flag-gated email/password sign-in, sign-in only

The system SHALL support establishing an Appwrite session via email/password through the
existing `AppwriteAccountGateway` seam, gated behind a compile-time flag
(`kDevEmailAuthEnabled`, default OFF). With the flag OFF, no dev sign-in surface SHALL be
constructed and release behaviour SHALL be byte-identical to a pre-change build. The client
SHALL NOT expose any registration path (no `account.create` from app code); dev accounts are
minted owner-side via the server-key CLI.

#### Scenario: Flag OFF hides the path entirely
- **WHEN** the app is built without `--dart-define=DEV_EMAIL_AUTH=true`
- **THEN** the auth screen shows only the Google sign-in and no email/password code path is reachable

#### Scenario: Valid credentials create a first-class session
- **WHEN** the flag is ON and user #0 submits correct credentials
- **THEN** a session is created without any page redirect and the resulting `AuthUser` flows through the same stream/refresh plumbing as a Google sign-in

#### Scenario: Wrong credentials fail typed, without a session
- **WHEN** the flag is ON and incorrect credentials are submitted
- **THEN** the attempt throws `AuthException` with the provider message, no session exists, and the form remains usable

### Requirement: Dev sessions inhabit an isolated per-user space

A dev-account session SHALL receive exactly the same per-user isolation as any other account:
it reads and writes only rows carrying its own `userId`, and its existence SHALL leave every
other user's rows untouched.

#### Scenario: User #0 sees only its own space
- **WHEN** user #0 signs in on any surface
- **THEN** it sees an empty (or only-its-own) data space and no row belonging to another user is read or written

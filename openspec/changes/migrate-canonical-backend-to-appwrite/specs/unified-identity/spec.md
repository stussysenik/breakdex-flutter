# unified-identity

## ADDED Requirements

### Requirement: Appwrite Account is the single identity across platforms

The system SHALL use Appwrite Account with the Google OAuth2 provider as the sole user identity
on mobile and web. One Appwrite `userId` SHALL key all synced records. `google_sign_in` on
mobile SHALL be retained only to mint Google Drive-scope tokens and SHALL NOT define identity.
Firebase Auth SHALL be retired together with the Firestore metadata path.

#### Scenario: One account, every surface
- **WHEN** a user signs in with the same Google account on iOS, Android, and web
- **THEN** all three sessions resolve to the same Appwrite `userId` and see the same dataset

#### Scenario: Web session grants Drive playback
- **WHEN** a user completes the web OAuth login with the Drive readonly scope
- **THEN** the web client can stream the user's videos from Drive using the session's provider
  token without a second consent flow

### Requirement: Legacy identities are claimed, never orphaned

On first Appwrite login, the system SHALL map the user's legacy Firebase uid to their Appwrite
`userId` via verified Google email in an additive `legacyIdentities` table. Backfills and pulls
SHALL resolve record ownership through this map so that no pre-migration record is orphaned.

#### Scenario: Existing user keeps their data
- **WHEN** a user whose records were created under Firebase auth signs in via Appwrite for the
  first time
- **THEN** all their existing moves, combos, reviews, and decks are visible unchanged

### Requirement: Login surface

The app SHALL present a login screen (matching the app design system) requiring an Appwrite
session before sync-backed features are available, with Google as the only provider, and SHALL
handle loading, error, and retry states without dead ends.

#### Scenario: Recoverable auth failure
- **WHEN** the OAuth flow fails or is cancelled
- **THEN** the user is returned to the login screen with a readable error and a retry action,
  and no partial session state persists

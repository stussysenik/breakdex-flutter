# web-mirror-access

## ADDED Requirements

### Requirement: Owner-allowlisted Firebase Auth gate

The web app SHALL require sign-in via Firebase Auth using the Google provider before showing
any library content, and SHALL grant access only to accounts on a configured owner allowlist.
A signed-in account that is not on the allowlist SHALL be denied and SHALL NOT trigger any
Drive request.

#### Scenario: Owner signs in
- **WHEN** an allowlisted owner completes Google sign-in
- **THEN** the app establishes a Firebase session and proceeds to load the library mirror

#### Scenario: Non-owner is rejected
- **WHEN** a signed-in account that is not on the allowlist reaches the app
- **THEN** the app shows an access-denied state and makes no Drive API call

#### Scenario: Unauthenticated visitor sees only the sign-in gate
- **WHEN** a visitor with no session opens the app URL
- **THEN** the app shows the sign-in gate and no library data or Drive request occurs

### Requirement: Single sign-in mints both session and Drive token

The same Google sign-in that establishes the Firebase session SHALL also request the
`drive.file` OAuth scope and yield a Google access token that the app uses to read the user's
Drive. The app SHALL NOT require a second, separate authentication step to access Drive.

#### Scenario: One login yields Drive access
- **WHEN** the owner completes the single Google sign-in
- **THEN** the app holds both a Firebase session and a Drive-scoped access token, and can read `Breakdex/manifest.json`

#### Scenario: Expired Drive token is recovered
- **WHEN** a Drive request fails because the access token has expired
- **THEN** the app re-acquires a token (silently or by prompting) and retries the read without losing the session

### Requirement: Read-only Drive access, minimal scope

The web app SHALL use only the `drive.file` scope (or, as a documented fallback,
`drive.readonly`) and SHALL perform only read operations against Drive — listing the
`Breakdex/` folder, downloading `manifest.json`, and streaming video bytes. The app SHALL NOT
create, modify, rename, move, trash, or delete any Drive file, and SHALL NOT write to the
manifest.

#### Scenario: Only reads are issued
- **WHEN** the app loads and renders the full mirror
- **THEN** every Drive call is a read (list, get, or media download) and no create/update/delete call is made

#### Scenario: No mutation surface is exposed
- **WHEN** the owner uses any control in the web app
- **THEN** no action results in a write to Drive, the manifest, or any backend

### Requirement: No secrets committed; configuration via environment

Firebase web configuration, the OAuth Web client ID, and the owner allowlist SHALL be supplied
via environment variables at build/deploy time and SHALL NOT be hardcoded or committed to the
repository. The repository SHALL provide a non-secret example template documenting the required
variables.

#### Scenario: Repo contains no live credentials
- **WHEN** the repository is inspected
- **THEN** it contains an example env template but no live Firebase config values, OAuth client secret, or deployment token

#### Scenario: Missing configuration fails safe
- **WHEN** the app is built or run without the required environment variables
- **THEN** it fails to start or shows a clear configuration error rather than falling back to embedded defaults

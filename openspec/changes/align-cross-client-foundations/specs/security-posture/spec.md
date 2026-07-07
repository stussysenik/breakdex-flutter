# security-posture

## ADDED Requirements

### Requirement: Token and session storage hygiene
OAuth and session credentials SHALL live only in platform secure storage: Keychain via
`flutter_secure_storage` on mobile, httpOnly cookies for the Appwrite web session. Tokens
SHALL never be stored in SharedPreferences, localStorage, or committed files. Google Drive
scopes SHALL stay minimized to the file-level access already in use.

#### Scenario: No token in insecure storage
- **WHEN** a signed-in session exists on mobile and web
- **THEN** an audit of SharedPreferences and localStorage finds no credential material, and
  the web session cookie is httpOnly

### Requirement: E2EE and workflow engines are explicit non-goals
The system SHALL document (root CLAUDE.md + this spec) that end-to-end encryption and
external durable-workflow engines (e.g. Temporal) are rejected: server-derived FSRS and
web-studio rendering require server-readable data, and durability is provided by idempotent
LWW operations, cursor rollback, the upload spool, and Appwrite Functions. Reopening either
decision requires a new OpenSpec change.

#### Scenario: Non-goal is discoverable
- **WHEN** a future contributor searches the repo for encryption or Temporal direction
- **THEN** root CLAUDE.md states the non-goal and links the rationale in this change

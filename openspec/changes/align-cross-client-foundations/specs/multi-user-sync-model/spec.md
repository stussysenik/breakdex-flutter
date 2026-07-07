# multi-user-sync-model

## ADDED Requirements

### Requirement: Private per-user synced spaces
Every user who signs in with Google SHALL receive a private synced space: their local Drift
data syncs to Appwrite documents owned by their account, and their videos upload to their
own Google Drive quota. Data SHALL NOT be readable or writable across user accounts;
per-user document permissions are the isolation boundary. The owner account is user #1 with
no special data-plane privileges.

#### Scenario: Second user gets an isolated space
- **WHEN** a second user signs in with Google on a fresh install and syncs
- **THEN** they see only their own records, and any attempt to read another user's
  documents is denied by Appwrite permissions (verified by an integration test)

### Requirement: Sign-in remains optional and non-destructive
The app SHALL remain fully functional for local-only users who never sign in. No sync
prompt, migration, or schema behavior SHALL degrade or alter local-only data (brownfield
constraint: additive-only).

#### Scenario: Local-only user is untouched
- **WHEN** a user with existing local data uses every CRUD surface without signing in
- **THEN** all features work offline and zero network sync traffic is emitted

#### Scenario: First sign-in claims legacy data
- **WHEN** a user with existing local records signs in for the first time
- **THEN** their local records are claimed under their new account via the uid-mapping
  mechanism from `migrate-canonical-backend-to-appwrite`, with no orphans and no duplicates

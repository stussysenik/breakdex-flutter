# backup-account — Spec Delta

## ADDED Requirements

### Requirement: Backup provider rows disclose their account

Any connected cloud backup provider row SHALL display the account identity holding the
backup (for Google Drive: the Google account email), so a user always knows where their
videos live.

#### Scenario: Drive row shows its email

- **GIVEN** Google Drive was connected with `user@gmail.com`
- **WHEN** the Video Backup section renders
- **THEN** the Drive row shows "Connected · user@gmail.com" (or equivalent localized
  form), distinct from the app-login account row

### Requirement: Unavailable providers are visibly degraded, never dead ends

The app SHALL render a backup provider as unavailable, with a short reason, on any
platform where it cannot work (Google Drive setup on web), and SHALL NOT offer a tap
into a failing flow.

#### Scenario: Web does not offer a Drive sign-in that fails

- **GIVEN** the app runs on Flutter Web
- **WHEN** the Video Backup section renders
- **THEN** the Drive row is shown unavailable ("backup runs from your phone") and
  tapping produces no sign-in attempt

### Requirement: One Google sign-in powers login and video backup

When the user signs into the app with Google, that single grant SHALL also authorize
video backup to that same account's Drive (`drive.file` scope via the Appwrite session's
provider token), with no second sign-in surface. Gated behind `DRIVE_VIA_APPWRITE`
(default OFF) until proven on device.

#### Scenario: Sign in once, backup follows

- **GIVEN** the flag is ON and a user signs into the app with Google
- **WHEN** the session is established
- **THEN** video backup to that account's Drive is enabled automatically, the Video
  Backup section shows that same email, and no separate Drive consent is requested

#### Scenario: Flag off preserves today's behavior byte-identically

- **GIVEN** `DRIVE_VIA_APPWRITE` is OFF
- **WHEN** the user signs in or manages backup
- **THEN** the existing `google_sign_in` Drive flow is unchanged

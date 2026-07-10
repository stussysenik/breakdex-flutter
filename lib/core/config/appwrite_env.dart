/// Public Appwrite connection constants for the live `breakdex` project.
///
/// Endpoint and project id are **public** values — they ship inside every
/// Appwrite client. The server API key is the only secret and never lives in
/// the app (owner writes config via console / server-key). Overridable at build
/// time with `--dart-define` for staging / self-host; the live Cloud values are
/// the defaults so a plain `flutter run` targets production read-only.
library;

/// Appwrite API endpoint (Frankfurt Cloud region for the live project).
const String kAppwriteEndpoint = String.fromEnvironment(
  'APPWRITE_ENDPOINT',
  defaultValue: 'https://fra.cloud.appwrite.io/v1',
);

/// Public project id of the live `breakdex` Appwrite project.
const String kAppwriteProjectId = String.fromEnvironment(
  'APPWRITE_PROJECT_ID',
  defaultValue: '6a50f25b000e15631ad0',
);

/// TablesDB database id (single database, id == name).
const String kAppwriteDatabaseId = 'breakdex';

/// `appConfig` table id (remote-config surface: flags, kill-switches, version).
const String kAppConfigTableId = 'appConfig';

/// Canonical **singleton** row id for the versioned app config. There is exactly
/// one config row; the owner creates/updates row `current` in the `appConfig`
/// table (per-cohort variance rides `cohortProfiles`, not extra rows).
const String kAppConfigRowId = 'current';

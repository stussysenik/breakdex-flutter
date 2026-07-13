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

/// `legacyIdentities` table id (D3 claim map: `firebaseUid → appwriteUserId`,
/// matched by verified Google email; written on first Appwrite login — task 3.4).
const String kLegacyIdentitiesTableId = 'legacyIdentities';

/// Canonical **singleton** row id for the versioned app config. There is exactly
/// one config row; the owner creates/updates row `current` in the `appConfig`
/// table (per-cohort variance rides `cohortProfiles`, not extra rows).
const String kAppConfigRowId = 'current';

/// Whether the **live** remote-config path (Appwrite row fetch + Realtime socket)
/// is active. The `appConfig` row is readable only by the `users` role, so a
/// session-less client — which is *every* client until Phase 3 identity lands —
/// can only ever degrade to compiled defaults. Firing the live path anyway just
/// CORS-fails the fetch and spins a futile Realtime reconnect loop (console
/// noise + wasted sockets). Kept off until Phase 3 wires a real session (and
/// Phase 0 registers the web origin as an Appwrite platform for CORS); flip to
/// `true` there. Until then [AppwriteRemoteConfigSource] is inert and config
/// resolves to cache-or-defaults. Overridable via `--dart-define` for testing.
const bool kRemoteConfigLiveEnabled = bool.fromEnvironment(
  'REMOTE_CONFIG_LIVE',
  defaultValue: false,
);

/// `invites` / `entitlements` table ids (authored in task 2.1) and the
/// `invites-redeem` Function id (task 2.2). Owner-minted invites map a code to a
/// cohort + entitlement tier; a redeem writes the caller's per-user entitlement.
const String kInvitesTableId = 'invites';
const String kEntitlementsTableId = 'entitlements';
const String kInvitesRedeemFunctionId = 'invites-redeem';

/// Whether released builds require an entitlement (invite code) to pass the app
/// gate. **Off by default** — the entire gate is inert, no Appwrite entitlement
/// read fires, and behaviour is byte-identical to a pre-gate build. Flipped on
/// only once the owner provisions the `invites`/`entitlements` tables live and
/// mints the first codes (Phase 2 live provisioning + wave 1). Even when on, the
/// gate never blocks the owner account, non-release/dev builds, existing device
/// users (grandfathered by a non-empty local library), or an already-entitled
/// user — see [EntitlementGate.evaluate]. Overridable via `--dart-define`.
const bool kEntitlementGateEnabled = bool.fromEnvironment(
  'ENTITLEMENT_GATE',
  defaultValue: false,
);

/// The owner account's email. When set (via `--dart-define=OWNER_EMAIL=...`) the
/// signed-in owner is never entitlement-gated (owner is user #1, never a
/// customer). Empty by default so no address is baked into the open-source repo.
const String kOwnerEmail = String.fromEnvironment(
  'OWNER_EMAIL',
  defaultValue: '',
);

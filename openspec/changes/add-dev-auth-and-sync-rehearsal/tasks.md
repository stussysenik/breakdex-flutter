# Tasks — add-dev-auth-and-sync-rehearsal

> **Executor entrypoint (Opus 4.8).** Phases 1 and 2 are independent — run in either order or
> in parallel sessions. Phase 3 depends on 1+2 **and** on the owner-gated live prerequisites
> (fenced inline — stop and surface, never improvise them). Phase 4 is strictly sequential
> after 3. Ledger rule applies: tick each box in the same commit that lands the work, with
> terminal-verified evidence (analyze/test/build output or a named sim/browser run). Rehearsal
> rungs (4.x) additionally tick the corresponding note in `docs/sync-rehearsal-runbook.md`.
> Cross-change: the panel (2.x) is `migrate-canonical-backend-to-appwrite` M.4's switch-hand —
> name that change in the commit body; do NOT tick its M boxes (those are the owner's live pass).

## Phase 1 — dev email/password auth seam (flag-OFF)

- [x] 1.1 Add `kDevEmailAuthEnabled` to `lib/core/config/appwrite_env.dart`
  (`bool.fromEnvironment('DEV_EMAIL_AUTH', defaultValue: false)`), doc comment matching the
  `kEntitlementGateEnabled` idiom: what it gates, why OFF, how to flip (`--dart-define`).
  Verify: `flutter analyze` clean.
- [x] 1.2 Extend the identity seam: add
  `Future<void> createEmailPasswordSession({required String email, required String password})`
  to `AppwriteAccountGateway` (in `lib/core/services/appwrite_auth_service.dart`) and implement
  it in `AppwriteAccountSdkGateway` (`appwrite_account_gateway.dart`) via
  `_account.createEmailPasswordSession`, mapping `AppwriteException` → `AuthException`
  (mirror the Google method). Add
  `Future<AuthUser> signInWithEmailPassword({required String email, required String password})`
  to `AppwriteAuthService`: gateway call → `currentUser()` → throw `AuthException` if null →
  `_emit` (no web-redirect branch — design D4). Verify: `flutter analyze` clean.
- [x] 1.3 Auth screen: when `kDevEmailAuthEnabled`, render a minimal email/password form under
  the Google button (grep `AppwriteLoginScreen` / `signInWithGoogle` call sites to find it);
  wire to `signInWithEmailPassword`; surface `AuthException.message` inline. Flag OFF ⇒ the
  subtree is not constructed. Match existing screen idiom + TOKENS (no new motion; this is a
  dev surface — plain Fluid defaults). **No registration affordance** (design D1).
- [x] 1.4 Tests: service happy/wrong-creds/null-session paths via the existing fake-gateway
  pattern (`test/core/services/appwrite_auth_service_test.dart`); login-screen pair — flag OFF
  ⇒ form absent, flag ON ⇒ submits and emits (extend
  `test/features/auth/appwrite_login_screen_test.dart`). Verify: targeted `flutter test` green
  + full `flutter analyze` clean.

## Phase 2 — dev sync-cutover panel (flag-OFF)

- [x] 2.1 Add `kDevSyncPanelEnabled` to `appwrite_env.dart`
  (`bool.fromEnvironment('DEV_SYNC_PANEL', defaultValue: false)`), same idiom as 1.1.
- [x] 2.2 New `lib/features/dev/sync_cutover_panel.dart`: enumerate every per-entity
  dual-write **and** dual-read pref key from `SyncService`'s constants (never re-type the
  strings — import them; entities: moves, combos, reviews, decks, noteEntries — confirm the
  full set by reading `lib/core/services/sync_service.dart` §pref keys), one toggle per key
  showing the persisted value, writing via `SharedPreferences.setBool`. Read-only footer:
  signed-in user id/email (from `AppwriteAuthService.currentUser`) so the operator always
  knows whose space they're mutating. Entry point: flag-gated tile on the settings surface
  (grep for the settings screen; match its list idiom). Flag OFF ⇒ absent.
- [x] 2.3 Widget tests: flag OFF ⇒ panel/tile absent; toggle flips the exact pref key;
  re-open shows persisted state. Verify: targeted `flutter test` green, `flutter analyze`
  clean, `flutter build web` green (both flags OFF — byte-identical guarantee holds).

## Phase 3 — harness + user #0 (owner-gated rungs fenced)

- [ ] 3.1 **[OWNER-GATED]** Live prerequisites, run per `docs/phase-m-runbook.md` §A–§D with
  the owner present: §A CLI auth (verified 2026-07-13) → §B note tables (targeted `create-*`
  ONLY — never `push tables --all`) → §C `push functions --activate` → §D register
  `http://localhost:<port>` web platform in console. If §B is deferred, note it: every rung
  except R7 (notes) still runs.
- [ ] 3.2 **[OWNER-GATED]** Mint user #0:
  `appwrite users create --user-id dev0 --email <dev address> --password "$DEV0_PASSWORD"`
  (server-key CLI; `DEV0_PASSWORD` added to `.env.local`, never committed — design D1).
  Verify: `appwrite users get --user-id dev0` shows the account.
- [ ] 3.3 `npx @swmansion/argent init` at repo root; commit the generated config as-is (this
  change sanctions it — design D6). Smoke: argent boots the app on an iOS simulator (flowdeck
  manages the sim) and on Chromium against a locally served `flutter build web` bundle, both
  with `--dart-define=DEV_EMAIL_AUTH=true --dart-define=DEV_SYNC_PANEL=true`. Evidence: both
  surfaces reach the auth screen with the dev form visible.
- [ ] 3.4 Author `docs/sync-rehearsal-runbook.md`: the R1–R7 ladder (below) as a results
  ledger — per rung: driver used (argent | chrome-devtools fallback), surfaces, evidence,
  pass/fail — plus the design-D7 fence table verbatim ("what this did NOT prove").

## Phase 4 — the rehearsal ladder (sequential; live, user #0 only)

> Flip order within each entity rung, per the Phase-M runbook: verify OFF (baseline, local-only)
> → flip dual-**write** → soak → flip dual-**read** → soak → cross-surface both directions.
> Any loss/duplication ⇒ flip that entity's pref back OFF, record, stop the ladder, surface.

- [ ] 4.1 **R1 — isolated origin.** Sign in as user #0 on sim + web (email/password). Both
  see an empty space; `list-rows` under the server key confirms no rows outside
  `userId == dev0` were touched at any point in the ladder (spot-check after R6).
- [ ] 4.2 **R2 — backfill parity.** Seed local data on the sim (a handful of moves/combos/
  reviews/decks via the real UI), run the backfill, verify per-entity row counts on the
  backend match local (the M.3 mechanism).
- [ ] 4.3 **R3 — moves cutover.** Full flip order on `moves` via the panel; edit on web →
  appears on sim; edit on sim → appears on web.
- [ ] 4.4 **R4 — combos, reviews, decks.** Repeat R3 per entity, one at a time.
- [ ] 4.5 **R5 — LWW conflict.** Edit the same move on both surfaces in quick succession;
  the later `updatedAt` wins on both; no duplicate rows; the loser's edit is cleanly gone.
- [ ] 4.6 **R6 — tombstone.** Delete a move on one surface; it disappears on the other and
  does **not** resurrect after relaunch + re-sync on either surface.
- [ ] 4.7 **R7 — notes** (requires 3.1 §B). Note-entry created on sim crosses to web and
  back; tombstoned note stays gone. Skip-with-note if §B deferred.
- [ ] 4.8 Fill the runbook ledger (3.4) with all evidence; record fenced items (design D7);
  tick this change complete; advance ROADMAP `## NOW` in the same commit; name
  `migrate-canonical-backend-to-appwrite` in the commit body (its M.4 confidence rises, its
  boxes stay untouched).

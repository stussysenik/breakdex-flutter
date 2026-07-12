# Appwrite Google OAuth Provisioning — Task 0.2 Runbook

**Change:** `migrate-canonical-backend-to-appwrite` · **Task:** `0.2` (owner-run) ·
**Status:** ✅ **provider VERIFIED enabled** (task 0.5, 2026-07-12) — see the status section below.

---

## Status — 0.5 headless verification (2026-07-12, overnight wave)

The owner believed 0.2 was handled. Task 0.5 **proved it headlessly** against the live Cloud
project (`6a50f25b000e15631ad0`, `https://fra.cloud.appwrite.io/v1`):

- **Google OAuth2 provider = ENABLED (Parts A + B done).** `GET /account/sessions/oauth2/google`
  (project header, no redirect follow) returns **`HTTP 301`** →
  `Location: https://accounts.google.com/o/oauth2/v2/auth?client_id=499240019967-jpou873pt715ubmacg9fjho3rm9nau3h.apps.googleusercontent.com&redirect_uri=…%2Foauth2%2Fcallback%2Fgoogle%2F6a50f25b000e15631ad0&scope=…email…profile+openid&response_type=code`.
  The `client_id` is the **Web** client (matches `.env.local` `GOOGLE_WEB_OAUTH_KEYS`, distinct
  from the iOS Drive client), and the `redirect_uri` matches this runbook's Part A/B URI
  character-for-character. A disabled provider would return a JSON `provider_disabled` error, not
  a Google 301. → **Provider proven.**
- **Web platform `localhost` = REGISTERED (Part C, web half).** With `Origin: http://localhost:3000`
  the API echoes `access-control-allow-origin: http://localhost:3000`; an unregistered origin
  (`evil.example.com`) is **CORS-blocked (403)**. → localhost web platform proven; this is also
  what lets `kRemoteConfigLiveEnabled` be flipped without the reconnect-loop.
- **Not headlessly provable (rides Phase M, does NOT block the wave):** iOS bundle / Android
  package native platform allow-listing (Part C, native half) and the production web domain
  (not chosen yet). Native OAuth uses the callback scheme, not a browser origin, so it can only
  be confirmed on the device: **M.2** (iOS live consent) resolves the iOS half, **M.6** the web
  origin. If either fails, the failure routes back into this doc.

**Ruling:** the actual gate — the provider issuing Google sessions — is proven, plus the
web-localhost origin. 0.2 is ticked on that basis; the native/prod-domain platform confirmations
are explicitly Phase-M residue (M.2 / M.6), consistent with the wave's proof split (D11).

Reproduce (auth from `.env.local`):
```bash
set -a; source .env.local; set +a
curl -sS -i -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
  "https://fra.cloud.appwrite.io/v1/account/sessions/oauth2/google?success=…&failure=…" | sed -n '1p;/^location:/Ip'
# expect: HTTP/2 301  +  location: https://accounts.google.com/...
```

---

**Original runbook (owner procedure, retained for reference):**

This is the single gate for the entire cross-device sync chain. Until the Google OAuth2
provider issues Appwrite sessions, no client can open a session, so Phase 3 (identity) and
Phase 4 (per-entity sync cutover) cannot start. Everything downstream is built and waiting;
this document is the ~20-minute console procedure that unblocks it.

Owner runs Parts A–C (console access + a Google Cloud OAuth client — I cannot do these).
The repo-half (Part D) is already committed.

---

## Constants (verified from the repo — copy-paste, don't retype)

| Thing | Value |
| --- | --- |
| Appwrite endpoint | `https://fra.cloud.appwrite.io/v1` (Frankfurt Cloud) |
| Appwrite project id | `6a50f25b000e15631ad0` |
| OAuth2 callback scheme (native) | `appwrite-callback-6a50f25b000e15631ad0` |
| **Google redirect URI** (register in the Google **Web** client) | `https://fra.cloud.appwrite.io/v1/account/sessions/oauth2/callback/google/6a50f25b000e15631ad0` |
| iOS bundle id / Android package | `com.breakdex.breakdex` |
| Google Cloud project number | `499240019967` (same project as the existing iOS Drive client) |
| Existing iOS OAuth client (Drive, `google_sign_in`) | `499240019967-sdv5ar5fs5pm12h947jfjvsjmqu2o20q.apps.googleusercontent.com` |

> Source of truth for endpoint/project: `lib/core/config/appwrite_env.dart`.

---

## The one non-obvious thing: **two different Google OAuth clients**

These are separate and must not be conflated:

- **iOS client** (already configured, `GIDClientID` in both plists) — used by `google_sign_in`
  for **Google Drive** token minting. Native flow, **no client secret**. Leave it exactly as is.
  Phase 3.3 keeps it purely for Drive scopes.
- **Web client** (this task creates/reuses it) — used by **Appwrite** to establish the
  **identity session**. Appwrite Cloud relays the OAuth flow server-side, so it needs a
  confidential client with **both a Client ID and a Client Secret**. iOS-type clients have no
  secret and will not work here.

So: the Drive login and the app-identity login ride different Google clients on purpose.
Existing users still see one familiar Google consent (Phase 3.3 handles that UX).

---

## Part A — Google Cloud Console (Web OAuth client)

1. Console → **APIs & Services → Credentials**, project **`499240019967`**.
2. If a **Web application** OAuth 2.0 client already exists (the `web-mirror` Firebase auth may
   have created one), reuse it. Otherwise **Create Credentials → OAuth client ID → Web application**;
   name it e.g. `Breakdex Appwrite (web relay)`.
3. Under **Authorized redirect URIs**, add exactly:
   ```
   https://fra.cloud.appwrite.io/v1/account/sessions/oauth2/callback/google/6a50f25b000e15631ad0
   ```
   (Cross-check this against the URI the Appwrite console shows in Part B — they must match
   character-for-character, including the trailing project id.)
4. *(Optional, only if a browser client hits Google directly — not our Appwrite relay path, so
   normally skip)* Authorized JavaScript origins: `http://localhost:PORT` (dev) + prod web origin.
5. **Save.** Copy the **Client ID** and **Client Secret** for Part B.

> If the OAuth **consent screen** is still "Testing", either add your Google account under
> **Test users**, or publish it. A Testing screen silently blocks non-test accounts at login.

## Part B — Appwrite Console (enable the Google provider)

1. Console → project **breakdex** → **Auth → Settings → OAuth2 Providers → Google → enable**.
2. Paste **App ID = Google Web Client ID**, **App Secret = Google Web Client Secret** (from Part A).
3. The panel shows a **URI** — confirm it equals the redirect URI you registered in Part A step 3.
4. **Update / Save.**

## Part C — Appwrite Console (register Platforms — CORS + SDK allow-list)

Required so the SDK is allowed to talk to the project, and so Flutter Web / `web-mirror` browser
clients aren't CORS-blocked. This is also what lets `kRemoteConfigLiveEnabled` be flipped on in
Phase 3 without the reconnect-loop noted in `appwrite_env.dart`.

Console → project **breakdex** → **Overview → Add platform**, add:

- **Flutter → iOS app** — Bundle ID `com.breakdex.breakdex`
- **Flutter → Android app** — Package name `com.breakdex.breakdex`
- **Web app** — Hostname `localhost` (dev)
- **Web app** — Hostname `<production web domain>` (fill in when the Flutter-Web release domain
  is chosen; add both apex and `www` if used)

## Part D — Native callback scheme (repo-half) — ✅ ALREADY LANDED

Committed with this runbook (safe/additive/inert until an OAuth2 session is first created):

- `ios/Runner/Info.plist` **and** `ios/Runner/Info-DebugProfile.plist` — added a second
  `CFBundleURLTypes` entry for scheme `appwrite-callback-6a50f25b000e15631ad0`.
  (Both plists on purpose: debug/profile builds read `Info-DebugProfile.plist`; a scheme in only
  one plist silently fails the flavor that omits it — see `project-ios-google-signin-config`.)
- `android/app/src/main/AndroidManifest.xml` — added
  `com.linusu.flutter_web_auth_2.CallbackActivity` (the callback handler for `appwrite ^25.2.0`
  → `flutter_web_auth_2 5.0.3`) with the same scheme and `android:taskAffinity=""`.

Verified: `plutil -lint` OK on both plists; manifest parses as valid XML.

---

## Definition of done for 0.2

- [x] Google **Web** OAuth client exists with the Appwrite redirect URI (Part A). *(0.5: proven — the 301's `client_id`+`redirect_uri`.)*
- [x] Appwrite Google provider enabled with that client's ID + secret (Part B). *(0.5: proven — 301 into Google.)*
- [x] web `localhost` platform registered (Part C, web half). *(0.5: proven — CORS echo.)* · [ ] iOS/Android native + prod web domain (Part C, native/prod half — rides M.2/M.6).
- [x] Native callback scheme registered in both plists + Android manifest (Part D).

**Live smoke (after Parts A–C):** once `3.1` (`appwrite_auth_service.dart`) exists, calling
`account.createOAuth2Session(provider: OAuthProvider.google, …)` should open the Google consent,
round-trip through the Appwrite callback, return to the app via the custom scheme, and yield a
non-null `account.get()`. That green session is the real proof — tick 0.2 then.

## What this unblocks (in order)

**Phase 3 — identity** (`3.1`–`3.5`): auth service, login screen, session-required wiring,
Firebase-uid → Appwrite-userId claim map, web login. Then **Phase 4** wires
`AppwriteSyncBackend` into `lib/core/providers.dart` (currently `syncBackend: null`) and turns on
per-entity sync + realtime `subscribe()` — the point at which iOS and Flutter-Web actually share
live data.

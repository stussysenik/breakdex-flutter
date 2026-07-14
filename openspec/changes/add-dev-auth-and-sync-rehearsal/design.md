# Design — add-dev-auth-and-sync-rehearsal

## D1 — Sign-in only; user #0 is minted owner-side

The client gains **no** registration surface. Appwrite's `account.create` is never called from
app code. User #0 is created once via the server-key CLI
(`appwrite users create --user-id dev0 --email <dev addr> --password <from .env.local>`), the
same authenticated session the phase-m-runbook already requires. Rationale: the product is
invite-gated (L5); an open registration path — even flag-gated — is a standing liability for
zero rehearsal value. Password lives in `.env.local` (`DEV0_PASSWORD`), never committed.

## D2 — Compile-time flags, byte-identical when OFF

Both new flags follow the exact `kEntitlementGateEnabled` idiom in `appwrite_env.dart`:
`bool.fromEnvironment`, default `false`, flipped per-build via `--dart-define`. With the flag
OFF the dev form / panel is not constructed (`if (kDevEmailAuthEnabled)`), so tree-shaking
keeps release builds byte-identical — the same guarantee L5 established and verified.
Rejected: a runtime/remote flag — dev surfaces must be impossible to enable in a shipped
binary, not merely disabled.

## D3 — Rehearse against the live project, as an isolated user

Alternative considered: a separate Appwrite test project. Rejected — it needs owner console
work to create, drifts from live schema, and (decisively) *bypasses the very thing under
test*: the per-user isolation model. User #0 in the live project exercises real row-security,
real Functions, real indexes; the isolation guarantee ("any sign-in gets an isolated space")
is itself one of the scenarios (R1). Blast radius: user #0's own rows only — the same radius
as any new user signing up.

## D4 — Email/password path is redirect-free on both surfaces

Unlike `createOAuth2Session`, `account.createEmailPasswordSession` resolves in-place — no
full-page web redirect, no callback scheme. So `signInWithEmailPassword` needs none of the
`_webRedirects()` machinery: call the gateway, read `currentUser()`, emit. This is exactly why
it de-lags the rehearsal loop. Wrong credentials map to the existing `AuthException` (mirror
of the Google path); a 401 on `currentUser()` after a *successful* session create is still a
fault, matching existing semantics.

## D5 — The sync-cutover panel is the missing M.4 switch-hand

The per-entity cutover prefs (`sync.<entity>.dualWrite.enabled` / dual-read counterparts in
`SyncService`) have **no runtime writer** — only tests flip them. M.4's instruction "flip
dual-write → soak → flip dual-read" is currently unexecutable on a device. The panel
enumerates the pref keys **from `SyncService`'s constants** (single source — no string
duplication), shows current values, and flips them live. It is deliberately dumb: read prefs,
write prefs, show last sync outcome. No new state machine — it is a settings surface over
existing state, per UI = f(state).

## D6 — argent is sanctioned here; chrome-devtools stays the fallback

The launch-wave preamble fenced `argent init` because it writes repo config mid-wave. That
fence was wave-scoped; this change is the named successor ("full click-through rides argent /
Phase-M"). `argent init` runs once, its config is committed, and the executor drives scenarios
via `npx @swmansion/argent` (MCP agentic toolkit — the executor *is* the test runner; no YAML
suite is authored). If argent cannot drive a rung (e.g. canvas-tree flakiness), the sanctioned
chrome-devtools fallback applies on web, and the rung's evidence says which driver ran —
binary truth includes naming the instrument.

## D7 — Honest fence: what the rehearsal proves vs. what stays Phase M

| Proven by rehearsal (user #0) | Stays Phase M (owner) |
| --- | --- |
| Session persistence across relaunch (mechanism) | Google OAuth callback scheme on iOS (M.2) |
| Backfill row-count parity (M.3 mechanism) | Real-data backfill of the owner library (M.3) |
| Per-entity dual-write→dual-read flips, both directions (M.4 core) | Drive video pointer → playback on web (M.4 video half) |
| LWW conflict, tombstone no-resurrect, notes cross | Legacy-identity claim via Google email (3.4) |
| Web email/password session from registered origin | Remote-config flip on owner cohort (M.5); web OAuth + httpOnly cookie (M.6) |

The rehearsal ledger in `docs/sync-rehearsal-runbook.md` records the right column as fenced,
so a green rehearsal can never be misread as "Phase M passed".

## D8 — Google OAuth live findings (2026-07-14): the chain is green server-side; failures were sequencing, not code

Live-verified with `curl` against the production project (`6a50f25b000e15631ad0`), so no
future session re-derives this:

- **Appwrite** `GET /account/sessions/oauth2/google?project=…&success=appwrite-callback-<pid>://…`
  returns `301 → accounts.google.com` with the correct `client_id` (`…jpou873…`) and
  `redirect_uri` (`…/oauth2/callback/google/<pid>`). Appwrite accepts the mobile callback
  scheme — it does **not** emit "Missing redirect URL" for this flow. That earlier error was
  transient pre-config state and does not reproduce.
- **Google** accepts that `redirect_uri` (`302` to sign-in, no `redirect_uri_mismatch`).
- **App side**: `appwriteAuthServiceProvider` wires the live SDK gateway; `/auth` route is
  reachable ungated; `appwrite-callback-<pid>` is registered in **both** `Info.plist` and
  `Info-DebugProfile.plist`; a plain `flutter run` targets production via the compiled
  defaults in `appwrite_env.dart`.

The only link never proven is the **on-device browser→app callback handoff** — interactive
by nature, owner-gated (M.2). Everything the rehearsal needs (email/password, redirect-free
per D4) bypasses that link entirely. Consequence for this change: a failed Google tap on a
device is **not** a blocker for any rung R1–R8 and must not restart an OAuth debugging loop;
the ladder proceeds on the dev path, and M.2 stays the owner's single remaining live proof.
See memory `gotcha_appwrite_oauth_device_debug` for the one-pass verification recipe.

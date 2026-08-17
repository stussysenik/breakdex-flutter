# Add first-user production provisioning & sync activation

## Why

Breakdex is a multi-device, one-source-of-truth system: **local Drift/SQLite is the
origin; Appwrite is a shadow replica.** An audit (2026-07-14) confirmed every sync
*service* is already built and correct:

- Google OAuth auto-provisions the Appwrite account on first sign-in; identity is bound
  by Appwrite `userId` (not email) — `appwrite_auth_service.dart:152`,
  `appwrite_account_gateway.dart:19`.
- Backfill writes are per-user permissioned (`_ownerOnly(userId)`), idempotent via
  logical `(userId,id)` dedup + `>=` LWW — `functions/sync-push/lib/reconcile.dart:271`.
- Reads are userId-isolated server-side on the trusted `x-appwrite-user-id` header —
  `functions/sync-pull/lib/main.dart:31,100,138`.
- LWW + tombstones + dirty-guard converge two devices losslessly —
  `sync_service.dart:616,642`; `reconcile.dart:293,324`.

**The gap:** the *only* trigger for backfill (`fullBackfillServiceProvider`) and the
*only* writer of the per-entity dual-read/dual-write prefs is `SyncCutoverPanel`,
reachable solely when `kDevSyncPanelEnabled` is compiled true (default false —
`appwrite_env.dart:97`, `settings_screen.dart:524`). **On a release binary a real
single-owner Google user never backfills and never turns sync on, so a second device
sees nothing.** Provisioning and isolation are correct; there is no *production path*
to activate them.

A separate gap: Lemon Squeezy offering ids that the web paid flow needs are
hardcoded/absent, blocking a web release. Offering ids MUST be owner-provisioned
(build-time config), never hardcoded.

## What Changes

Add a **first-login provisioning path** that generalizes what the dev panel does, so any
user (owner first) is provisioned on first successful Appwrite login — "start their space,
provisioned, once they successfully login once, all synced up":

1. **First-login provisioning trigger** — on a newly established Appwrite session, if a
   per-user one-shot `sync.provisioned.$userId` flag is unset: run the full backfill (all
   entities, idempotent), then flip dual-read + dual-write ON, then set the one-shot flag.
   Failure leaves prefs OFF (no partial activation). Mirrors the proven
   `hydrateOnLoginTriggerProvider` pattern exactly — no remote-config dependency (Phase M.5
   not proven live; a remote-config gate is a named follow-up, not this change).
2. **`SyncService.activateSync()` + batch setters** — additive API so a production path can
   compose the 8 backfill calls and flip every entity's prefs at once.
3. **Identity ruling (operational, no code literal)** — canonical owner = the Appwrite
   `userId` created by **Google sign-in as `senik456@gmail.com` on the device**; data
   ownership is fixed by whichever account is signed in at backfill time.
4. **Owner-provisioned offering config** — Lemon Squeezy offering ids read from
   `--dart-define=OFFERINGS_JSON`, never hardcoded. Absent/malformed → paid flow disabled.

## Capabilities

- `sync-activation` — production first-login provisioning + dual-read/write activation +
  owner-provisioned offering config.

## Footprint estimate

| Surface | Current → Target |
| --- | --- |
| First-login trigger | 0 → 1 provider (~80–120 LOC), mirrors `hydrate_on_login_providers.dart` |
| `SyncService` | +`activateSync()` + `setDualWriteAll`/`setDualReadAll` (~+60 LOC on `sync_service.dart`) |
| Offering config | +`lib/core/config/offerings_config.dart` (~+60 LOC) |
| Tests | +1 test file (trigger one-shot / idempotency / isolation / offering config), ~+200 LOC |
| **Total** | **~4–5 files, ~350 LOC + tests** — additive; no service rewrite |

## Non-goals

- **No remote-config gate in this change.** Phase M.5 (remote-config live-flip) is not proven
  live; a production trigger that depends on it cannot ship tonight. The trigger fires on
  first login guarded only by the per-user one-shot flag. Remote-config gating is a named
  follow-up.
- **No sub-second LWW rework.** Whole-second clock comparison (`sync_service.dart:648`)
  can leave two edits to the *same record in the same second* divergent until a later
  edit (data-safe, tie-keeps-local). Documented known-limitation; ms-precision migration
  is a named follow-up.
- **No `legacyIdentities` remap path.** Audit-only claim map stays as-is (harmless under
  Drift-origin).
- **No device-driven verification in this change.** Logic is proven by unit/integration
  tests; the owner drives the real cross-device soak in a dedicated session. No agent-driven
  UI runs.
- **No E2EE, no CRDTs, no removal of the dev panel** (dev panel stays for rehearsal).

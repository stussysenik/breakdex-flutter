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

## What Changes

Add a production, remote-config-gated **first-login provisioning path** that generalizes
what the dev panel does, so any user (owner first) is provisioned on first successful
Appwrite login — "start their space, provisioned, once they successfully login once,
all synced up":

1. **First-login provisioning trigger** — on a newly established Appwrite session, if a
   per-user one-shot "provisioned" flag is unset *and* a remote-config flag
   (`appConfig.syncActivationEnabled`, default false) is true: run the full backfill
   (all 8 entities, idempotent), then flip dual-read + dual-write ON, then set the
   one-shot flag. Failure leaves prefs OFF (no partial activation).
2. **Remote-config gate** — owner controls rollout via the existing `appConfig` surface,
   no new binary. Safe default OFF preserves today's byte-identical behavior.
3. **Identity ruling (operational, no code literal)** — canonical owner = the Appwrite
   `userId` created by **Google sign-in as `senik456@gmail.com` on the device**; data
   ownership is fixed by whichever account is signed in at backfill time. The prior
   `itsmxzou@gmail.com` email/password account is a disposable rehearsal artifact
   (different email → will NOT merge with the Google identity; holds no data).
4. **Defense-in-depth (optional task)** — add an explicit `userId` query filter to the
   client direct-reads of `reviewEvents`/`fsrsCards` (`appwrite_functions_transport.dart:70`),
   which today rely on row permissions alone.

## Capabilities

- `sync-activation` — production first-login provisioning + dual-read/write activation.

## Footprint estimate

| Surface | Current → Target |
| --- | --- |
| First-login trigger | 0 → ~1 provider/controller (~80–120 LOC), alongside existing `legacy_identity_providers.dart` |
| `SyncService` | expose a production `activateSync()` (backfill + pref flip + one-shot); ~+40 LOC on `sync_service.dart` |
| Remote config | +1 field `syncActivationEnabled` in `appConfig` model/source (~+15 LOC) |
| Tests | +1 test file (trigger one-shot / gate-off / idempotency / isolation), ~+150 LOC |
| **Total** | **~3–5 files, ~250 LOC + tests** — additive; no service rewrite |

## Non-goals

- **No sub-second LWW rework.** Whole-second clock comparison (`sync_service.dart:648`)
  can leave two edits to the *same record in the same second* divergent until a later
  edit (data-safe, tie-keeps-local). Documented known-limitation; ms-precision migration
  is a named follow-up, not this change.
- **No `legacyIdentities` remap path.** Audit-only claim map stays as-is (harmless under
  Drift-origin); optional unique-constraint hardening deferred.
- **No device-driven verification in this change.** Logic is proven by unit/integration
  tests; the owner drives the real cross-device soak in a dedicated session (runbook in
  design.md). No agent-driven UI runs.
- **No E2EE, no CRDTs, no removal of the dev panel** (dev panel stays for rehearsal).

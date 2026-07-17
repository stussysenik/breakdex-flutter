# Design — fix-video-backup-truth-and-unify-account

## D1 — Honest health: derive from the store, not the stream

`syncHealthProvider` currently maps engine *mood*: `progress == null → allSynced`
(`sync_providers.dart:355`). The engine only emits on state transitions, so a fresh app
launch with 66 unprotected videos reports "All synced".

**Ruling:** health derives from Drift. Add a watched query
(`AssetManifestDao.watchUnderprotectedCount()`) and compute:

```
providers empty            → noProviders
engine busy                → syncing
underprotectedCount > 0    → pendingUpload   (regardless of engine mood)
error state                → error
else                       → allSynced
```

The engine's progress stream remains for live transfer UI (percentages, active file);
it is never the source of the health verdict. This is UI = f(state) applied honestly:
state lives in the database, the stream is a projection.

## D2 — Sweep skip vs abort

`_uploadUnderprotected` early-returns on the first `waitForWifi` decision. The original
intent (don't spin through a big list on cellular) is preserved by **skipping** deferred
files and recording `deferredCount`; if everything was deferred, set state
`waitingForWifi` as before. One oversized file must never shadow the files behind it.

`dataCapExceeded` similarly skips (files smaller than the remaining cap may still fit —
`canTransfer` is per-file).

## D3 — Queue drain loop

`_processQueue` becomes: fetch up to `maxConcurrent` queued ops → execute → repeat until
the queue returns empty, checking `paused`/cancellation between batches. No recursion, no
timer — a plain `while` inside the already-guarded `runSyncCycle` (`_running` flag
prevents re-entry). Failed ops are already routed to `_retryFailed` with backoff;
the drain loop does not retry within a cycle (no hot-looping a failing op).

## D4 — One account, one sign-in (Phase 3, owner-gated)

Two Google surfaces exist today:

| | App login (data sync) | Video backup (Drive) |
| --- | --- | --- |
| Mechanism | Appwrite Google OAuth (token flow via `flutter_web_auth_2`) | `google_sign_in` SDK, `drive.file` scope |
| Identity | `itsmxzou@gmail.com` (owner acct) | whichever account the user picks in a second consent |
| Web | works (M.6 proven) | fails (not wired) |

**Target:** one OAuth grant. Appwrite sessions expose `providerAccessToken` and can be
created with additional scopes; adding `drive.file` to the Appwrite Google provider's
scope list gives every Google-login session a Drive-capable token that
`account.updateSession()` refreshes. A thin `AppwriteTokenDriveProvider` (implements the
existing `CloudProvider` contract) calls the Drive REST API with that token — no
`google_sign_in` dependency, works on mobile **and** web, and the backup account is by
construction the login account.

Consequences to accept (why this is owner-gated):
- Existing signed-in sessions lack the new scope → re-consent on next login (one-time,
  per user; acceptable pre-launch with one real user).
- Local-only users (no sign-in) have no video backup — true today too; the product
  answer is "sign in unlocks safety", stated visibly.
- The legacy `google_sign_in` provider row stays until the token path is proven on
  device (additive, `DRIVE_VIA_APPWRITE` flag, default OFF), then is retired by a
  follow-up migration that re-parents the Breakdex folder only if the accounts match —
  never silently re-uploading to a different account.

## D5 — What was NOT wrong (recorded so nobody "fixes" it)

- Upload bytes are exact: content-hash filenames, post-upload hash verify. The Drive
  *preview* transcodes; the stored object does not. No transcode work.
- `_executeUpload` resolves paths correctly; only the verifier had the relative-path bug.
- The one video that did upload proves OAuth, folder creation, and the upload path
  end-to-end.

## Open questions (owner)

- **O1:** Approve the Appwrite-scope approach for Phase 3 (re-consent tradeoff above)?
- **O2:** When the token path is proven, should the legacy `google_sign_in`-backed row be
  removed outright (one less consent surface) or kept as a power-user override?

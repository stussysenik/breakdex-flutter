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

## D6 — Progress is a projection, and projections must be pushed

The 2026-07-18 device run drained the whole queue while the Sync Status screen sat frozen
at "17/72". Traced: the `17/72` text renders `SyncProgress.syncedAssets/totalAssets`
(`sync_status_screen.dart:402`), fed only by `_emitProgress()`, which is called only from
`_setState()` (`asset_sync_engine.dart:693-696`). `_setState` fires at cycle start
(`uploading`), cycle end (`idle`), pause, and the wifi-wait branch — never when an
individual operation settles. So the stream emits one snapshot at sweep start and goes
silent for the entire drain.

This does not contradict D1 — it completes it. D1 ruled the *health verdict* derives from
Drift (and it does: the settings badge and pending count are live, because they watch
`watchUnderprotectedCount()`). The engine stream survives as the *transfer* projection.
The defect is that the projection was only pushed on mood changes.

**Ruling:** call `_emitProgress()` at the end of `_executeOperation`, after the operation
settles either way. One call site, no new state, no UI change — the existing stream
becomes per-operation fresh and everything downstream (`syncedAssets`, the fraction, the
bar) goes live. Mixing a live Drift stream and a stale engine snapshot on one screen is
what produced the contradiction the owner saw; this removes the staleness rather than
adding a second source of truth.

For in-flight bytes, the data already exists — `provider.upload`'s `onProgress` callback
writes `sync_operations.transferredBytes` on every chunk (`asset_sync_engine.dart:459`).
The active-transfer readout watches those rows; it does not need a new channel.

## D7 — Copy identity is `(contentHash, provider)`, enforced structurally

`AssetCopies.primaryKey` is `{id}` alone (`tables/asset_copies.dart:46`), and the engine
records every successful upload with `id: _uuid.v4()`
(`asset_sync_engine.dart:469-481`). `upsertCopy` is `insertOnConflictUpdate` — with a
fresh UUID there is never a conflict, so **every upload appends a new row**. The import
paths get this right by accident of convention (`'${hash}_local'` in
`import_state_machine.dart:141`), which is why the bug is invisible until the cloud path
runs twice.

Two consequences, both live in the current database:
- **Inflation.** Re-uploading an asset (the dedupe-retry storm does exactly this) adds
  another `verified` `gdrive` row. `updateCopyCount` counts rows, so `copyCount` climbs
  past the number of distinct providers actually holding the file.
- **False protection.** `copyCount >= 2` is the definition of "protected"
  (`getUnderprotected`, `watchUnderprotectedCount`) and the documented two-copy minimum
  gating local deletion (`tables/asset_copies.dart:6-9`). Two duplicate `gdrive` rows
  satisfy it with **one** real cloud copy. Nothing gates deletion on it *today* — grep
  confirms `copyCount` has no deletion consumer — but the invariant is load-bearing for
  the free-space work that will, and a counter that can lie about protection is exactly
  the class of defect this change exists to remove.

A third, latent variant: `legacy_asset_migration.dart:134` keys the local copy
`'${move.id}_local'` while `import_state_machine.dart:141` keys it `'${hash}_local'`. Two
different IDs for the same logical `(hash, local)` copy — if both paths ever touched one
asset, that asset shows `copyCount == 2` with **zero** cloud copies and is silently
excluded from every sweep.

**Ruling:** make the identity structural rather than conventional.
1. Derive the id as `'${contentHash}_$provider'` at every write site (engine, import,
   legacy migration, on-demand downloader, reconcile service — five call sites).
2. Add a unique index on `(contentHash, provider)` so a future call site cannot
   reintroduce the bug silently.
3. One-way migration: collapse duplicate pairs keeping the most protective status
   (`verified` > `uploading`/`pending` > `failed`), then recompute every `copyCount`.
   Additive and non-destructive — no asset loses a record it genuinely has.

## D8 — Diagnose before backfilling the local-copy gap

The device run showed ~33 successful uploads moving the counter by ~5. D7's inflation
alone cannot explain an *under*-count, so at least one other cause is present. The
candidate: legacy assets that never got a `local` copy row, so a successful Drive upload
leaves them at `copyCount == 1` — still underprotected, re-swept forever, counter never
converging.

That is a hypothesis, not a finding. The 1.5 diagnostics dump already reports copies
grouped by provider×status; it answers this directly. **Ruling:** the executor runs the
dump first and records the actual distribution in the task tick, then applies the
reconcile. The reconcile is written to be correct regardless of which cause dominates —
rebuild `local` rows from disk truth, never invent one for a file that is not there — but
we do not guess which defect bit this library when the instrument to check already ships.

## D9 — Terminal vs retryable failure

**Corrected during 4.5 by reading the dedupe, not the summary of it.** The revision above
("self-limiting, not literally infinite") was wrong, and the original "permafail storm"
reading was right. The retry lane *is* bounded per operation — `getRetryable` filters
`retryCount < maxRetries` — but `operationExists` dedupes only against `queued` and
`in_progress` (`sync_operations_dao.dart:63-76`). A `failed` row blocks nothing. Every
sweep calls `queueUpload` for each still-underprotected asset (`asset_sync_engine.dart:279`),
which finds no live operation and **inserts a fresh one with `retryCount` back at zero**.
The budget is bounded per operation and unbounded per asset: three attempts, every cycle,
forever. So 4.4 cannot mark the *operation* terminal and stop there — the terminal verdict
has to be readable at the point of re-queue, or the next sweep simply undoes it.

Consequence already shipped: 4.5's UI never says "will not retry", because today that
would be a lie. The exhausted bucket reads "keeps failing", which is exactly what the
engine does. 4.4 earns the stronger wording.

Original text, for the record — the retry lane is bounded (`maxRetries` default 3,
`sync_operations.dart:32`; `getRetryable` filters `retryCount < maxRetries`), and
`queueUpload` dedupes against existing operations (`asset_sync_engine.dart:181-186`).
The real defect is subtler and worse:

An asset whose bytes are gone burns three retries to learn what the first attempt already
proved, then sits in `failed` forever while the manifest row stays underprotected. The
pending count can therefore never reach zero, and the user is given no way to distinguish
"22 videos still uploading" from "22 videos whose files no longer exist". A permanently
inflated pending count is the same dishonesty as "All synced" — inverted.

**Ruling:** classify at the failure site. `_executeUpload` already knows the difference —
it fails with `'Local file missing: …'` only after `_healStaleLocalPath` returns null
(`asset_sync_engine.dart:443-449`). That path marks the operation terminal (a distinct
status, retry budget untouched); every other failure keeps today's retryable behavior.
Terminal-failed assets are counted and shown separately in Sync Status, so pending can
converge to zero honestly while the unbackupable set stays visible and actionable.

**Known blind spot to check during 4.4:** `entityPathCandidatesForHash` consults only
*active* moves (`moves_dao.dart:42 getActiveByContentHash`). An archived move whose file
is still on disk is invisible to the heal, so its asset would be classified terminal while
its bytes exist. Before shipping the terminal classification, confirm whether the ~22
`Moves/Power moves/` failures are archived-with-file (heal blind spot → widen the
candidate query to include archived entities) or genuinely deleted (classification is
correct). Terminal is a stronger claim than retryable; it must not be reached by a query
gap.

## D10 — Hash is identity, path is hint: the sandbox-scan rescue lane

**Ground truth (2026-07-19 device forensics, answers 4.0):** the per-asset forensics run
(`asset_resolution.dart` + extended diagnostics, owner-join control `50/72` proving the
join sound) classified all 22 unreachable assets as `owners=0 (0 archived, 0 deleted)` —
**the D9 archived-entity blind-spot hypothesis is refuted.** No owner query widening can
heal them: there is no owning row, active, archived, or tombstoned. Yet the bytes for at
least some demonstrably survive in the sandbox — the picker's APP VIDEOS tab (a raw
recursive scan of `Moves/`) lists them, with a byte-exact size match confirmed for
`69e13899` (`Thursday July 16th 2026`, 6 126 241 bytes).

The asymmetry that allows this: **playback** already treats the sandbox as byte authority
— `VideoPathResolver.resolve()` falls back to a recursive filename scan
(`video_player_widget.dart:951`) — while **upload** heals only from owning-entity path
candidates (`_healStaleLocalPath`). A file that moved on disk stays playable but becomes
un-uploadable, and the sweep re-queues it every cycle (`failed` grew +22/cycle, measured
242 → 264 across one cycle).

**Ruling:** the content hash is the identity of an asset; `localPath` is a cache hint;
the sandbox is the byte authority. Every canonical filename embeds the hash
(`Name - hash8.ext` or `<fullhash>.ext`), so a single recursive scan of `Moves/` +
`Combos/` indexed by hash-in-filename gives the engine the same self-healing the player
has. The heal gains a third lane: (1) stored path, (2) owning-entity candidates,
(3) hash-indexed sandbox scan — persisting the found path to the manifest as before.
Assets the scan cannot find have genuinely lost their bytes and flow into D9's terminal
classification plus a manifest tombstone (4.8), so the sweep stops re-queueing them and
`failed` stops growing.

This is enforcement of the existing model, not a new one: `asset_manifest` keyed by hash
already said this — the engine just never fully believed it.

## Open questions (owner)

- **O1:** Approve the Appwrite-scope approach for Phase 3 (re-consent tradeoff above)?
- **O2:** When the token path is proven, should the legacy `google_sign_in`-backed row be
  removed outright (one less consent surface) or kept as a power-user override?

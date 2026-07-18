# Tasks — fix-video-backup-truth-and-unify-account

> **Phase dependencies:** Phases 1 and 2 are independent of each other and start
> immediately. Phase 4 depends on Phase 1 (shipped) and is independent of 2 and 3;
> it is the next agent-runnable work. Phase 3 is owner-gated (design.md O1) and depends
> on nothing in 1–2 technically, but lands after them. Task 1.6 is a cross-change note,
> no code.
> Ledger rule: tick in the same commit as the work, with terminal evidence. Every fix in
> Phase 1 is red/green: failing test first against current behavior, then the fix.

## Phase 1 — Backup truth & throughput

- [x] 1.1 Integrity verifier path fix. Red: test with a manifest row whose relative
  `localPath` resolves to an existing temp file — current code reports it
  missing/unreadable. Green: resolve via `VideoPathResolver.toAbsolute()` before
  `computeHash` (also cover the genuinely-missing case staying missing). Verify:
  new tests green, `flutter analyze` clean.
- [x] 1.2 Sweep skip-not-abort. Red: two underprotected assets, first deferred by
  policy (`waitForWifi`), second transferable — current sweep queues neither. Green:
  per-file skip with deferred tally; all-deferred still surfaces `waitingForWifi`.
  Verify: tests green, analyze clean.
- [x] 1.3 Queue drain loop. Red: 5 queued ops, Wi-Fi (`maxConcurrent = 2`) — current
  cycle completes only 2. Green: batch loop until empty with pause check between
  batches (test pause interrupts drain). Verify: tests green, analyze clean.
- [x] 1.4 Honest health. Add `watchUnderprotectedCount()` to `AssetManifestDao`;
  `syncHealthProvider` computes from it per design D1 (busy → syncing, count>0 →
  pendingUpload, no unemitted-stream default). Show the pending count in the Video
  Backup section subtitle and Sync Status header (localized, ARB). Red: provider test
  with progress-stream silent + 1 underprotected row currently yields `allSynced`.
  Verify: tests green, analyze clean, `scripts/check_l10n.sh` green.
- [x] 1.5 Dev diagnostics dump: dev-only action printing/logging manifest count,
  copies grouped by provider×status, operations grouped by status (reuse the existing
  dev panel surface). Verify: analyze clean; output shape asserted in one unit test.
- [x] 1.6 File the reclassification note in
  `openspec/changes/make-sync-total-and-registry-driven/design.md` §D6:
  `AssetManifest`/`AssetCopies` move from `localOnly` to a field-split ruling
  (portable pointer fields sync; device-state fields stay local) — required for web
  playback later. Note only, no code; tick both ledgers per cross-change rule.
- [ ] 1.7 On-device proof (owner, 30s): rebuild, open Sync Status → header shows the
  real pending count (~66); tap Sync Now once on Wi-Fi; Drive shows the full library;
  Verify Integrity reports 67 OK. Evidence: screenshot + Drive file count in the tick.
  (First attempt 2026-07-18 surfaced 1.8/1.9 — re-run after that build.)
- [x] 1.8 Manifest path drift (found by the 1.7 device run: all 55 uploads failed
  "A negative content length is not allowed"). Root cause: renames/category moves/
  the semantic-path healer physically relocate the video and update the move row,
  but never `asset_manifest.localPath` — the engine then stats a missing file
  (size −1) which Drive's `Media` rejects with that cryptic error. Fixed at the
  three layers, red/green: (a) engine self-heals a stale `localPath` from the owning
  entities' current paths (`entityPathCandidatesForHash`) and persists it, else
  fails honestly with "Local file missing"; (b) `StorageOrchestrator` +
  `VideoPathHealer` carry the manifest pointer in the same operation that moves the
  file; (c) `GDriveProvider.upload` throws the honest error for a not-found file.
  Verify: 2 engine tests + 2 orchestrator tests (red pre-fix via stash), sync suite
  180 green ×2, analyze clean on touched files.
- [x] 1.9 Boot hairline never clears: `BootGate.pruning` was a dead gate no stage
  completes (the Janitor absorbed pruning), so `BootState.isComplete` never flipped
  and the 2px top progress bar sat at exactly 3/4 in every view forever. Removed the
  dead gate (enum + status screen label); `postFrameProgress` test updated to 3
  gates. Verify: boot_progress suite green.

## Phase 2 — Account clarity

- [x] 2.1 Drive row account email: surface the connected `GoogleSignInAccount.email`
  (silent sign-in read; cache last-known in the provider row's `configJson` so the
  email renders offline too). Localized "Connected · {email}". Verify: widget test,
  analyze clean, l10n check green.
- [x] 2.2 Web affordance: on `kIsWeb`, Drive row renders `ProviderStatus.unavailable`
  with reason copy ("backup runs from your phone"); no tap handler. Verify: widget test
  for web branch, `flutter build web` green.
- [x] 2.3 Per-asset sync detail (owner-requested 2026-07-18): Sync Status should show
  individual assets — name/thumb, per-provider op state (queued / uploading with
  progress / verified / failed+error), so "is it doing anything?" is answerable at a
  glance. Ground truth exists (`sync_operations.errorMessage`, `asset_copies` status,
  1.5 diagnostics dump); this is a read-only list over those tables.
  **DONE 2026-07-18.** `AssetSyncDetail` + the pure `buildAssetSyncDetails()`
  (`lib/core/sync/asset_sync_detail.dart`) classify each live asset as
  uploading / queued / failed / pending / backed up, sorted worst-first so the
  answer is the first row. `AssetManifestDao.watchSyncDetails()` reads it live
  from ONE joined query over the three tables, so a copy verifying or an
  operation failing re-emits without the manifest being touched; the
  copies × operations fan-out is de-duplicated by primary key on the way out.
  Two honesty rulings, both test-pinned: a verified **local** copy is never
  "backed up" (local bytes answer the may-I-delete question, not the
  cloud-protection one), and a transfer that has moved zero bytes reports a
  null fraction — an indeterminate bar — rather than a fabricated 0% that
  reads as stalled. **Name, not thumb:** renames and category moves relocate
  the file (task 1.8), so the current path's basename already tracks the
  owning move's name; a real thumbnail needs frame extraction that does not
  exist yet, and inventing one was out of scope for a read-only list.
  Binary truth: 27 new tests (20 unit + 7 widget on the pure-override
  harness), both load-bearing decisions proven by mutation — flipping
  `provider != 'local'` and swapping the sort ranks each go red, and the tree
  is green again after revert. Full suite **1021 green, 9 pre-existing reds,
  0 regressions**; `flutter analyze` 0 errors; `check_l10n.sh` green;
  `flutter build web` green. Copy stays hardcoded English to match the
  screen's existing idiom — **4.5 owns the ARB pass** for this surface.

## Phase 4 — Progress legibility & copy truth (2026-07-18 device run)

> Independent of Phases 2–3; depends on Phase 1 (shipped). Order matters *within* the
> phase: 4.1 is standalone; 4.2 → 4.3 (identity before reconcile, or the reconcile
> re-creates duplicates); 4.4 needs the 4.0 answer first. 2.3's per-asset list is the
> surface 4.1/4.5/4.4 all report into — land 2.3 before or alongside 4.5.

- [ ] 4.0 Ground-truth read before any fix (design D8, D9 blind spot). Run the 1.5
  diagnostics dump on the owner's device build and record in the tick: manifest count,
  copies by provider×status, operations by status, and the count of live assets whose
  local file exists but which have no `local` copy row. Separately answer the open
  device question: do the ~22 failing `Moves/Power moves/` videos still **play in the
  app**? (play = heal blind spot, widen `entityPathCandidatesForHash` to archived
  entities; don't play = bytes genuinely gone, terminal classification is correct.)
  No code. Evidence: dump output + a one-line verdict per question.
- [x] 4.1 Per-operation progress emission (design D6). Red proven: with 3 upload ops
  queued the stream carried exactly **2** events (cycle-start + cycle-end) and 2 again
  for a failing op — the counter cannot move mid-sweep. Green: `_emitProgress()` at the
  end of `_executeOperation`, after both the success and the failure path, so a failed
  upload also refreshes the count. Verify: 2 new tests green, engine suite 17 green,
  `flutter analyze` clean on touched files.
- [x] 4.2 Copy identity `(contentHash, provider)` (design D7). Red proven: two uploads of
  one asset to one provider left **2 `icloud` rows** (`copyCount` 3 with local).
  **Two spec corrections found in the code:** there are **six** write sites, not five —
  `video_import_sync_hook.dart:89` was missed — and **five** distinct id schemes, not
  two: `${moveId}_local` (import hook), `${move.id}_local` (legacy migration),
  `${canonicalHash}_local` (import machine), `${hash}_local` (canonical reconcile),
  `${contentHash}_local_redownload` (on-demand downloader), plus `_uuid.v4()` in the
  engine. Two of those key by **entity id** and two by **content hash**, so one logical
  local copy could occupy *three* rows — D7 described two. Also latent: `getLocalCopy`
  uses `getSingleOrNull()`, which **throws** once a duplicate local row exists.
  Green: (a) the scheme now lives in one place, `AssetCopiesDao.copyId(hash, provider)`,
  called at all six sites; (b) unique index `asset_copies_hash_provider_unique`,
  installed in `onCreate` *and* the migration (mirrors `_installIntegrityTriggers`);
  (c) schema **v28** collapses duplicate pairs — most-protective status wins, newest
  breaks ties — deletes losers before restating ids (a survivor's new deterministic id
  can collide with a duplicate's current id), then recomputes every `copyCount`.
  The step is guarded on `asset_copies` existing *and* carrying the columns it reads;
  without that guard it ran against hand-written legacy fixtures whose `asset_copies`
  never matched the real v10 shape (no `status`) and broke 27 unrelated migration tests.
  Honest transient recorded in the migration comment: recomputing drops assets that
  never got a `local` copy row from the `copy_count` default of 1 to their true count,
  so the underprotected total can *rise* on first open — the pre-existing gap becoming
  visible, which 4.3 reconciles. Verify: 6 new migration tests + 1 engine test, all red
  pre-fix; `flutter test test/core/database/ test/core/sync/ test/core/services/`
  **640 green / 0 failures**; full suite **988 green, 9 pre-existing reds, 0 regressions**;
  `flutter analyze` 0 errors (9 pre-existing infos).
- [x] 4.3 Copy reconcile from disk truth (design D8). Red asserted in the test itself:
  an asset whose bytes are on disk with a successful `gdrive` copy still reads
  `copyCount < 2` and `watchUnderprotectedCount() == 1`. Green: new
  `LocalCopyReconciler` (`lib/core/sync/local_copy_reconciler.dart`) inserts a verified
  `local` row for every live asset whose resolved path exists, inserts nothing when the
  file is gone (a missing video must never read as protected), and recomputes
  `copyCount`; idempotent, tombstone-skipping, reachable from the dev panel
  ("Reconcile local copies from disk", which re-dumps so the effect is visible).
  It deliberately avoids `getLocalCopy` — `getSingleOrNull()` throws on the legacy
  duplicate rows 4.2 collapses. **Also closes a 4.0 blocker:** the 1.5 dump could not
  produce the count 4.0 asks for, so it now reports `on disk without a local copy row: N`
  via `findMissingLocalCopies()` — the owner can answer 4.0's first half from the dump
  alone. Verify: 6 new tests green; sync+database+dev **324 green / 0 failures**; full
  suite **994 green, 9 pre-existing reds, 0 regressions**; `flutter analyze` 0 errors.
- [ ] 4.4 Terminal vs retryable failure (design D9). Gated on 4.0's second answer — if
  the heal has an archived-entity blind spot, widen `entityPathCandidatesForHash` first
  and re-measure before classifying anything terminal. Red: an upload whose file is
  genuinely missing currently consumes retry budget and is re-attempted on later cycles.
  Green: that path marks the operation terminal (distinct status, retry budget
  untouched, not re-attempted); every other failure keeps today's retryable behavior.
  Verify: both failure classes tested, retry-lane suite green, analyze clean.
- [ ] 4.5 Unbackupable and in-flight visibility (spec: last two requirements). Sync
  Status separates three counts — pending, uploading, unbackupable(+reason) — and the
  active transfer shows its asset and byte/percentage progress from
  `sync_operations.transferredBytes`. Localized (ARB). Verify: widget tests via the
  pure-override harness (live Drift streams flake widget tests), `scripts/check_l10n.sh`
  green, analyze clean.
- [ ] 4.6 On-device proof (owner, one sync cycle): the counter advances *during* the
  sweep (not only at the end); after the cycle, pending + unbackupable accounts for
  every live asset with no double-counting; a second Sync Now re-attempts nothing
  terminal. Evidence: screenshot mid-sweep + final counts in the tick.

## Phase 3 — One-account magic (owner-gated: design.md O1 ruling first)

- [ ] 3.1 [OWNER] Rule on O1 (Appwrite `drive.file` scope + re-consent tradeoff) and
  O2 (legacy row retirement). Record rulings in design.md.
- [ ] 3.2 Add `drive.file` to the Appwrite Google provider scopes (console/API step,
  owner-run per established recipe); verify a fresh session's `providerAccessToken`
  can list/create files via Drive REST with a curl proof.
- [ ] 3.3 `AppwriteTokenDriveProvider implements CloudProvider` using the session
  provider token (+ refresh via `account.updateSession` on 401), behind
  `DRIVE_VIA_APPWRITE` (default OFF). Reuses the existing upload/verify contract.
  Verify: unit tests with mocked HTTP, analyze clean, flag-OFF suite byte-identical.
- [ ] 3.4 Auto-enable on Google login when flag ON: session established → provider row
  present+enabled for the login account; Video Backup section shows the same email as
  the account row. Verify: unit test on the login hook, analyze clean.
- [ ] 3.5 On-device proof (owner): flag ON build, Google sign-in once → videos upload
  to the login account's Drive with no second consent; web build still green.

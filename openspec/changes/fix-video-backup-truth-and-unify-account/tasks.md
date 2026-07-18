# Tasks — fix-video-backup-truth-and-unify-account

> **Phase dependencies:** Phases 1 and 2 are independent of each other and start
> immediately. Phase 3 is owner-gated (design.md O1) and depends on nothing in 1–2
> technically, but lands after them. Task 1.6 is a cross-change note, no code.
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
- [ ] 2.3 Per-asset sync detail (owner-requested 2026-07-18): Sync Status should show
  individual assets — name/thumb, per-provider op state (queued / uploading with
  progress / verified / failed+error), so "is it doing anything?" is answerable at a
  glance. Ground truth exists (`sync_operations.errorMessage`, `asset_copies` status,
  1.5 diagnostics dump); this is a read-only list over those tables.

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

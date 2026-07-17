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
- [ ] 1.3 Queue drain loop. Red: 5 queued ops, Wi-Fi (`maxConcurrent = 2`) — current
  cycle completes only 2. Green: batch loop until empty with pause check between
  batches (test pause interrupts drain). Verify: tests green, analyze clean.
- [ ] 1.4 Honest health. Add `watchUnderprotectedCount()` to `AssetManifestDao`;
  `syncHealthProvider` computes from it per design D1 (busy → syncing, count>0 →
  pendingUpload, no unemitted-stream default). Show the pending count in the Video
  Backup section subtitle and Sync Status header (localized, ARB). Red: provider test
  with progress-stream silent + 1 underprotected row currently yields `allSynced`.
  Verify: tests green, analyze clean, `scripts/check_l10n.sh` green.
- [ ] 1.5 Dev diagnostics dump: dev-only action printing/logging manifest count,
  copies grouped by provider×status, operations grouped by status (reuse the existing
  dev panel surface). Verify: analyze clean; output shape asserted in one unit test.
- [ ] 1.6 File the reclassification note in
  `openspec/changes/make-sync-total-and-registry-driven/design.md` §D6:
  `AssetManifest`/`AssetCopies` move from `localOnly` to a field-split ruling
  (portable pointer fields sync; device-state fields stay local) — required for web
  playback later. Note only, no code; tick both ledgers per cross-change rule.
- [ ] 1.7 On-device proof (owner, 30s): rebuild, open Sync Status → header shows the
  real pending count (~66); tap Sync Now once on Wi-Fi; Drive shows the full library;
  Verify Integrity reports 67 OK. Evidence: screenshot + Drive file count in the tick.

## Phase 2 — Account clarity

- [ ] 2.1 Drive row account email: surface the connected `GoogleSignInAccount.email`
  (silent sign-in read; cache last-known in the provider row's `configJson` so the
  email renders offline too). Localized "Connected · {email}". Verify: widget test,
  analyze clean, l10n check green.
- [ ] 2.2 Web affordance: on `kIsWeb`, Drive row renders `ProviderStatus.unavailable`
  with reason copy ("backup runs from your phone"); no tap handler. Verify: widget test
  for web branch, `flutter build web` green.

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

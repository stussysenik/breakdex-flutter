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

- [x] 4.0 Ground-truth read before any fix (design D8, D9 blind spot). Run the 1.5
  diagnostics dump on the owner's device build and record in the tick: manifest count,
  copies by provider×status, operations by status, and the count of live assets whose
  local file exists but which have no `local` copy row. Separately answer the open
  device question: do the ~22 failing `Moves/Power moves/` videos still **play in the
  app**? (play = heal blind spot, widen `entityPathCandidatesForHash` to archived
  entities; don't play = bytes genuinely gone, terminal classification is correct.)
  No code. Evidence: dump output + a one-line verdict per question.
  **ANSWERED 2026-07-19** (device run with the extended forensics —
  `asset_resolution.dart` four-way classifier + owner-join positive control; tick this
  box in the commit that lands that forensics code): manifest 99 (72 live / 28
  underprotected / 27 tombstoned); copies gdrive×verified 50, local×verified 44,
  local×deleted 10, local×failed 6; ops completed 118 / failed 264 (+22 per cycle =
  exactly the 22 unreachable); on disk without a local copy row: **0**. Verdict:
  control 50/72 proves the join; all 22 read `owners=0 (0 archived, 0 deleted)` —
  **neither hypothesis was right**: no owner exists to widen toward, yet bytes for at
  least some survive on disk (picker APP VIDEOS scan lists them; byte-exact match
  confirmed for `69e13899`). Remedy = hash-indexed sandbox rescue (4.7, design D10),
  then tombstone the residue (4.8).
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
- [x] 4.4 Terminal vs retryable failure (design D9). ~~Gated on 4.0's second answer~~
  4.0 refuted the archived-blind-spot hypothesis (owners=0 across the board) — the gate
  is now **4.7**: the sandbox-rescue lane must land first so "terminal" is only reachable
  after a hash scan of the sandbox comes up empty, never by a path/query gap. Red: an upload whose file is
  genuinely missing currently consumes retry budget and is re-attempted on later cycles.
  Green: that path marks the operation terminal (distinct status, retry budget
  untouched, not re-attempted); every other failure keeps today's retryable behavior.
  **Scope widened by 4.5's read of the dedupe (design D9, corrected):** marking the
  *operation* terminal is not enough. `operationExists` dedupes only against
  `queued`/`in_progress` (`sync_operations_dao.dart:63-76`), so a `failed` row blocks
  nothing and the next sweep's `queueUpload` (`asset_sync_engine.dart:279`) inserts a
  fresh operation with `retryCount` back at zero — three attempts per cycle, forever.
  The terminal verdict must be visible at the re-queue site (or held on the manifest),
  or the sweep undoes it. Red must cover that second cycle, not just the first.
  Verify: both failure classes tested, retry-lane suite green, analyze clean.
  **DONE 2026-07-19.** Bytes-nowhere (all three heal lanes exhausted, including a null
  stored path — previously an unhealable insta-fail) → `markTerminal`: distinct
  `'terminal'` status, retry budget untouched; `queueUpload` checks `hasTerminal` before
  inserting, closing the re-queue hole. **Ruling added during implementation (D9
  addendum): the verdict is revocable-automatic** — `clearTerminal` fires from
  `OrphanRestoreService.restore()` and `VideoImportSyncHook` when bytes re-home (D11's
  lesson: permanent terminal = silent soft-delete of a recoverable video). Classifier
  honesty rode along: `isTerminal` now means the verdict, not an exhausted budget (an
  exhausted `failed` op IS re-swept), and `_latestFailed`/diagnostics read `'terminal'`
  as failure-class so a terminal asset can never fall through to "pending". Red proven:
  second-cycle re-queue test red pre-fix (fresh op inserted), classifier test red
  (terminal fell to pending), restore-revocation test red (verdict survived restore).
  Green: 6 new/rewritten tests; sync+db+services **710 green / 0 failures**; settings
  widget suite 15 green; `flutter analyze` 0 errors. Leftover recorded in D9: the
  "keeps failing" ARB copy may now say "will not retry" honestly — folded into 4.10.
- [x] 4.5 Unbackupable and in-flight visibility (spec: last two requirements). Sync
  Status separates the counts — uploading / waiting / retrying / keeps-failing /
  backed up — via a pure `AssetSyncTally.from()` folded over the same rows the list
  renders, so the buckets partition the library by construction (mutation-proven: a
  double-count makes `total` disagree with the row count and goes red). The active
  transfer shows byte *and* percentage progress; a transfer with no reported bytes says
  "Starting", never a fabricated 0%. The failure copy says "keeps failing", **not**
  "will not retry" — see the D9 correction above; that promise is false until 4.4 lands,
  and a test asserts the phrase is absent. Empty buckets are omitted rather than shown
  as zero. ARB pass covers the whole per-asset surface (18 keys); the pre-existing
  Network / Data-usage sections of the screen stay as they were — they predate this
  change and belong to no task here. Verify: 9 new tests (5 unit + 4 widget on the
  pure-override harness), suite **1030 green / 9 pre-existing reds / 0 regressions**,
  `flutter analyze` 0 errors, `scripts/check_l10n.sh` green.
- [ ] 4.6 On-device proof (owner, one sync cycle): the counter advances *during* the
  sweep (not only at the end); after the cycle, pending + unbackupable accounts for
  every live asset with no double-counting; a second Sync Now re-attempts nothing
  terminal. Evidence: screenshot mid-sweep + final counts in the tick.
- [x] 4.7 Hash-indexed sandbox rescue (design D10). One recursive scan of `Moves/` +
  `Combos/` builds a `contentHash → absolute path` index by parsing the hash embedded
  in canonical filenames (`Name - hash8.ext` and `<fullhash>.ext` forms; hash8 collisions
  resolved by full-hash verify before trusting). Wire as the third lane of
  `_healStaleLocalPath` (stored path → entity candidates → sandbox scan), persisting the
  found relative path to the manifest exactly like lane 2. Extend the diagnostics
  forensics line with `bytes found on disk at <path>` / `bytes not found in sandbox` per
  unreachable asset, so the rescuable/gone split is measured, not guessed. Red: manifest
  row with stale `localPath`, no owning entity, bytes present under a different category
  dir — current heal returns null and the upload fails "Local file missing". Green: heal
  returns the scanned path, manifest updated, upload proceeds. Also fix the stale
  `asset_manifest.localPath` doc comment ("Absolute path" → relative-to-Documents,
  healable). Verify: new tests red/green, sync suite green, analyze clean.
  **DONE 2026-07-19.** `lib/core/sync/sandbox_hash_index.dart`: a pure
  `sandboxHashToken()` parser plus `SandboxHashIndex.scan()/resolve()`. Wired as lane 3
  of `_healStaleLocalPath`, with lanes 2 and 3 sharing one `_persistHealedPath` that logs
  which lane fired. **One spec detail was wrong and the code corrects it:** the spec said
  parse "the hash embedded in canonical filenames", and the four existing inline parsers
  all use `split(' - ').last` — which returns the *whole basename* when there is no
  separator, so `IMG_4021.mov` would key the index under `img_4021`. The parser therefore
  validates hex and length (64 for `<fullhash>.ext`, 8 for `Name - hash8.ext`) and returns
  null otherwise; a junk key can only ever produce a wrong rescue, and handing the
  uploader wrong bytes under the right hash is the one failure mode this lane must not
  have. Uses `lastIndexOf(' - ')` so names containing the separator still parse.
  hash8 ties are resolved by full-hash verify; a lone hash8 match is trusted without
  re-hashing megabytes (documented tradeoff). Red proven by stashing the wiring: the new
  engine test read `Actual: []` (no upload). Green: uploads the stranded file and the
  manifest records `Moves/Power moves/Air Flare - 69e13899.mp4`. Diagnostics gained
  `sandbox rescue: N of M unreachable assets have bytes on disk` plus a per-asset
  `bytes found on disk at <path>` / `bytes not found in sandbox`, with a test proving the
  found-branch fires (a split that could only read 0 would send every asset to 4.8).
  Verify: 12 new index tests + 1 engine + 1 diagnostics test green; sync+database+services
  **697 green / 0 failures**; `flutter analyze` 0 errors; full suite **1157 green**, reds
  identical to baseline on the same files (42/6/9 with and without the change) — **0
  regressions**; `check_l10n.sh` and `flutter build web` green.
- [x] 4.8 Restore-and-re-adopt the quarantined orphans (design D11 — REWRITTEN
  2026-07-19: device evidence read `sandbox rescue: 22 of 22`, all in
  `Moves/.lost+found/`; the tombstone premise "bytes gone" is falsified, and
  tombstoning would soft-delete recoverable videos). An `OrphanRestoreService`
  (pure logic, injected deps, unit-testable) takes each live zero-owner manifest whose
  bytes the sandbox index finds and: (1) **full-hash verifies** the candidate file
  equals `contentHash` — mismatch is reported, never adopted (D11 ruling 2; two of the
  22 show name drift); (2) moves the file out of `.lost+found` to a canonical
  `Moves/Recovered/<name> - <hash8>.<ext>` path AND updates `localPath` in the same
  operation (the 1.8 rule); (3) creates an owning move in a `Recovered` category
  (original owners are hard-deleted; category truth is unrecoverable) so the asset is
  visible in the library and owned again. Idempotent: re-running adopts nothing new.
  Dev-panel action + inline re-dump, same idiom as reconcile; never automatic. Red:
  a stranded zero-owner manifest with bytes in the fake sandbox gains an owner, a
  healed path, and upload eligibility only after restore runs. Verify: unit tests
  (hash-mismatch refusal, idempotence, manifest+move atomicity), analyze clean.
  Device evidence in the tick: 22 restored, library shows Recovered category,
  unresolvable list reads 0, next sweep uploads them.
  **Code DONE 2026-07-19** — `OrphanRestoreService` (db + `MoveRepository` via the
  sync-aware provider, so restored moves enter record sync; hasher injected),
  panel button `sync-restore-orphans` + inline re-dump + `Recovered` category
  registration. Red embedded in the adopt test's before-assertions (zero moves,
  dead path). Verify: 5 new unit tests (adopt, hash-mismatch refusal w/ impostor
  file, idempotence, owned-skip, byte-less bucket) green; panel suite 14 green;
  sync+database+services **702 green / 0 failures**; `flutter analyze` 0 errors
  (9 pre-existing infos).
  **DEVICE EVIDENCE 2026-07-19 (owner run, DEV_SYNC_PANEL build): 18 restored,
  4 refused on full-hash mismatch, 0 byte-less.** Not the predicted 22/22 — and
  the shortfall is the gate working, not failing: four `.lost+found` files carry
  bytes that are not the hash their filename claims. Two of them (`69e13899`,
  `1bb10442`) wear *exactly* matching names, which is the whole argument for
  full-hash verification over the hash8 trust D10 allows for upload healing —
  name agreement is not evidence. Had this lane trusted the token, four videos
  would have been adopted under wrong identities, silently.
  **Follow-on shipped in the same pass:** a refusal now names what the bytes
  *are* (`_identifyBytes`) — duplicate of a live owned asset / a tombstoned
  asset / another orphan restorable under its true hash / unknown to the
  manifest. The prior line printed the expected hash and the path, which
  restated the question the operator was asking. Each verdict names its remedy,
  so the residue is triageable from the device log alone with no further
  instrumentation. Red proven by stash: both forensic tests read the old bare
  `<hash> at <path>` shape. Verify: 7 restore tests (2 new/tightened) green,
  panel suite 9 green, sync+database+services **711 green / 0 failures**,
  analyze 0 errors on both changed files.
- [x] 4.9 Janitor joins the registry (design D11 ruling 4 — loop closure). Before
  quarantining a file, `StorageJanitor` parses the hash from the canonical filename
  (reuse `SandboxHashIndex`'s validating parser — NOT the `split(' - ').last` idiom)
  and checks live `asset_manifest` rows: manifest-known files are never moved to
  `.lost+found`. Genuinely unknown files (no parseable hash, or hash not in the
  manifest) quarantine as before. **Spec deviation, recorded:** the janitor does NOT
  write `localPath` itself — 4.7's engine heal lane 3 already re-points it from the
  same sandbox scan on the next sweep, and two writers healing the same field is the
  two-bookkeepers defect this task exists to kill. The janitor's whole fix is "leave
  manifest-known bytes in place" (logged `[KNOWN]`); healing stays the engine's.
  Tombstoned manifests are not live claims — their files still quarantine.
  Red proven by stashing the janitor change: the manifest-known test quarantined the
  file (+3 −1), the other three passed — quarantine behavior otherwise unchanged.
  Green: 4 janitor tests (first-ever for this class), sync+database+services
  **706 green / 0 failures**, `flutter analyze` clean. DONE 2026-07-19.
- [ ] 4.10 Tombstone the true residue (fallback, gated on 4.8's device evidence).
  For assets restore confirms byte-less (`bytes not found` after 4.8 runs — currently
  zero), the dev-panel action tombstones the manifest rows (sets `deletedAt`, same
  soft-delete idiom as user deletes) so the sweep stops re-queueing them, with inline
  re-dump. Never automatic. Also clears the stale `failed` op rows for resolved assets
  so `sync_operations` counts reflect the present, not the archaeology (264 failed at
  the 2026-07-19 dump, most from healed pre-1.8 states). Red: tombstoned asset no
  longer queued; `failed` count flat across two cycles in the engine test. Verify:
  tests green, analyze clean. Device evidence in the tick: two cycles, flat `failed`
  count, unreachable list empty or all-terminal.
  **Premise update from 4.8's device run (2026-07-19) — read before building this.**
  The tombstone target set is **empty**: restore reported `bytes not found: 0`. Every
  remaining unresolvable asset has bytes on disk; the residue is 4 **hash-mismatch**
  assets, not byte-less ones. Tombstoning those would be exactly the soft-delete-of-
  recoverable-video defect that rewrote 4.8. So this task's *first* half currently has
  nothing to act on and MUST NOT be pointed at the mismatch set as a substitute.
  Its *second* half (clearing stale `failed` op rows — 264 at the dump, most from healed
  pre-1.8 states) is unaffected and still worth doing; consider landing that alone.
  The mismatch residue needs its own decision, informed by the forensic verdicts 4.8 now
  logs — duplicates are delete-safe, unknown bytes want adoption under their true hash,
  and the 4 missing identities may still exist in Drive (`gdrive×verified: 50`), which
  cannot be checked until the phone's dropped Google session is restored.

## Phase 3 — One-account magic (owner-gated: design.md O1 ruling first)

- [ ] 3.1 [OWNER] Rule on O1 (Appwrite `drive.file` scope + re-consent tradeoff) and
  O2 (legacy row retirement). Record rulings in design.md.
- [ ] 3.2 Add `drive.file` to the Appwrite Google provider scopes. Agent-runnable
  first: use the established `.env.local` credentials + console-cookie recipe (the same
  PATCH path that fixed the missing client secret — project API keys lack
  `projects.write`, the console session from `appwrite login` does not); owner fallback
  only if the cookie recipe fails. Verify a fresh session's `providerAccessToken` can
  list/create files via Drive REST with a curl proof.
- [ ] 3.3 `AppwriteTokenDriveProvider implements CloudProvider` using the session
  provider token (+ refresh via `account.updateSession` on 401), behind
  `DRIVE_VIA_APPWRITE` (default OFF). Reuses the existing upload/verify contract.
  Verify: unit tests with mocked HTTP, analyze clean, flag-OFF suite byte-identical.
- [ ] 3.4 Auto-enable on Google login when flag ON: session established → provider row
  present+enabled for the login account; Video Backup section shows the same email as
  the account row. Verify: unit test on the login hook, analyze clean.
- [ ] 3.5 On-device proof (owner): flag ON build, Google sign-in once → videos upload
  to the login account's Drive with no second consent; web build still green.

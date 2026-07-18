# Breakdex — Roadmap & Backlog

> **The single roadmap.** (`docs/ROADMAP.MD` and `docs/PROGRESS.MD` were folded in here and
> removed, 2026-07-06.) Captures decisions, what already exists in the code, the remaining
> delta, and a recommended sequence toward launch.
> Last consolidated: 2026-07-06.

> ⚠️ **Backend decision updated (2026-07-05).** The "Firebase (Firestore)" rows in the
> LOCKED table and workstreams below are **superseded**. The canonical backend is now
> **Appwrite** (open-source, self-hostable; decided after grilling, reversal was free —
> nothing was deployed). The provider-agnostic `SyncBackend` contract, LWW clock,
> non-destructive backfill, and dual-read cutover all carry over. See the root `CLAUDE.md`
> and `openspec/changes/migrate-canonical-backend-to-appwrite`. Read anything below that
> says "Firestore" as "the canonical sync backend, now Appwrite."

---

## NOW — the single active task (queue head; every session starts here)

> Any session, human or agent: read this block, open the named change's `tasks.md`, do
> exactly the next unticked task, verify (binary truth), tick + update this block **in the
> same commit**. Nothing else starts until this block says so.

- **Change (active, owner-launched 2026-07-17):** `fix-video-backup-truth-and-unify-account`
  — the video-backup pipeline was structurally dishonest (verifier reported 67/67 "missing"
  on a relative-path bug; one deferred file aborted the whole upload sweep; a cycle drained
  only one `maxConcurrent` batch; "All synced" was an unemitted-stream default). **Phase 1
  (backup truth & throughput) DONE by agent 2026-07-17**, each fix red/green: 1.1 verifier
  resolves relative paths (`9d6625c`), 1.2 sweep skips deferred files + all-deferred still
  surfaces waitingForWifi (`5e7db70`), 1.3 queue drain loop (`4a57587`), 1.4 honest health
  derived from `watchUnderprotectedCount()` in Drift + real pending count in Video Backup
  subtitle and Sync Status header, localized (`3e7c2c5`), 1.5 dev diagnostics dump
  (`5fd1380`), 1.6 field-split reclassification note filed in `make-sync-total`'s §D6.
  Binary truth: `flutter analyze` 0 errors (9 pre-existing infos untouched), targeted
  suites + provider/sync/database dirs green (317+), `check_l10n.sh` green, 0 regressions.
  **Phase 2 (account clarity) also DONE by agent 2026-07-17:** 2.1 the Drive row names
  the Google account holding the backup ("Connected · email" subtitle; captured on
  connect, cached in the row's `configJson`, silent-read refresh —
  `GDriveSetupService.connectedAccountEmail`), 2.2 on web the Drive row renders
  `unavailable` ("Backup runs from your phone"), no tap handler. Widget tests use a
  pure-override harness (live Drift streams flake widget tests — same class as the 9
  pre-existing reds); service caching unit-tested; `flutter build web` green.
  **2026-07-18 device run surfaced two more structural defects, both FIXED red/green
  (tasks 1.8/1.9):** 1.8 manifest path drift — renames/category moves relocated video
  files without carrying `asset_manifest.localPath`, so all 55 uploads failed with
  Drive's cryptic "negative content length" (missing file stats size −1); engine now
  self-heals the manifest from the owning move/combo's current path and fails honestly
  when the file is truly gone, and orchestrator/healer update the manifest in the same
  operation that moves a file. 1.9 the ever-present 2px blue hairline at the top of
  every view was `BootGate.pruning` — a dead gate nothing completes — pinning
  `isComplete` false forever; gate removed. Same run also confirmed the
  hydrate-on-login red screen fix (provider-build assertion; deferred via microtask).
  **2026-07-18 device run #2 — Phase 1 fixes CONFIRMED WORKING, next layer specced.**
  The run drained the entire queue in one cycle (~33 videos healed + uploaded, incl. 87/68/66 MB
  files); the localPath heal fired on 7+ stale manifests; failures now fail instantly with the
  real path instead of Drive's "negative content length". Three defects the run exposed are
  specced as **new Phase 4 (progress legibility & copy truth)** in that `tasks.md`, with
  rulings in design.md **D6–D9** — all verified against the code, not inferred:
  (a) the "17/72" counter freezes for the whole sweep — `_emitProgress()` is called only
  from `_setState()` (`asset_sync_engine.dart:693-696`), so it emits at cycle start/end and
  never per operation (**D6**);
  (b) copy identity is broken — `AssetCopies.primaryKey` is `{id}` alone and the engine
  writes each upload with a fresh `_uuid.v4()`, so `upsertCopy`'s `insertOnConflictUpdate`
  **always inserts**; every re-upload appends a duplicate `gdrive` row and `copyCount` can
  overstate protection (the documented two-copy minimum). A latent variant: legacy migration
  keys the local copy `'${move.id}_local'` while import keys it `'${hash}_local'` — two rows
  for one logical copy → an asset can read `copyCount == 2` with **zero** cloud copies (**D7**);
  (c) an asset whose bytes are gone burns 3 retries then sits failed forever, permanently
  inflating the pending count with no way to distinguish "uploading" from "unbackupable"
  (**D9** — note the earlier "infinite permafail storm" reading was too strong; `maxRetries`
  and `queueUpload`'s dedupe do bound it).
  **Phase 4 progress — 4.1 and 4.2 DONE by agent 2026-07-18, each red/green.** 4.1: the
  counter froze because the stream carried exactly 2 events per cycle regardless of how
  many operations ran; `_emitProgress()` now fires after every settled operation, success
  or failure (`asset_sync_engine.dart`). 4.2: copy identity is now
  `AssetCopiesDao.copyId(contentHash, provider)` at all **six** write sites (the spec said
  five — `video_import_sync_hook.dart:89` was missed), backed by a unique index and
  schema **v28** collapsing duplicates by most-protective status. Reading the code
  corrected D7 twice: there were **five** id schemes, two keyed by entity id and two by
  content hash, so one logical local copy could occupy *three* rows (D7 said two), and
  `getLocalCopy`'s `getSingleOrNull()` **throws** once a duplicate exists. Binary truth:
  db+sync+services **640 green / 0 failures**, full suite **988 green, 9 pre-existing
  reds, 0 regressions**, `flutter analyze` 0 errors.
  **Next unticked, and it needs the owner: 4.0** — read ground truth via the 1.5
  diagnostics dump on a device build (**D8**: don't guess which of three causes lags the
  counter), and answer the open question — do the ~22 failing `Moves/Power moves/` videos
  still **play**? (play ⇒ the heal has an archived-entity blind spot,
  `getActiveByContentHash` at `moves_dao.dart:42`; don't play ⇒ terminal classification is
  correct). **4.4 is blocked on that answer.** **4.3 also DONE 2026-07-18**
  (`LocalCopyReconciler` + dev-panel action), which clears the honest transient v28
  introduces — and it closed a 4.0 blocker: the 1.5 dump could not produce the
  missing-local-copy count 4.0 asks for, and now reports it directly, so the owner can
  answer 4.0's first half from the dump alone. Full suite **994 green, 9 pre-existing
  reds, 0 regressions**.
  **2.3 DONE 2026-07-18** — Sync Status now lists each video with what is actually
  happening to it (uploading with byte progress / queued / failed+error+will-it-retry /
  not backed up / backed up, worst-first), read live from ONE joined query over
  manifest × copies × operations, classified by a pure `buildAssetSyncDetails()`.
  Two honesty rulings pinned by mutation-proven tests: a verified **local** copy is
  never "backed up", and a zero-byte transfer shows an indeterminate bar rather than a
  fake 0%. Name comes from the on-disk basename (1.8 keeps it tracking renames); a real
  thumbnail needs frame extraction that does not exist. Full suite **1021 green, 9
  pre-existing reds, 0 regressions**; analyze 0 errors; `check_l10n.sh` + web build green.
  **4.5 DONE 2026-07-18** — the header's single number is now a split: uploading /
  waiting / retrying / keeps-failing / backed up, folded by a pure `AssetSyncTally.from()`
  over the *same* rows the list renders, so the buckets partition the library by
  construction rather than by a second count that could disagree. Transfers show a
  percentage as well as bytes; a transfer with nothing reported yet says "Starting".
  The whole per-asset surface is localized (18 ARB keys).
  **4.5 also corrected design D9, which had corrected itself in the wrong direction.**
  The "self-limiting, not a permafail storm" revision was wrong: `operationExists` dedupes
  only against `queued`/`in_progress` (`sync_operations_dao.dart:63-76`), so a `failed`
  row blocks nothing, and each sweep's `queueUpload` (`asset_sync_engine.dart:279`) inserts
  a **fresh operation with `retryCount` back at zero** — bounded per operation, unbounded
  per asset. Consequence: 2.3's "Failed — will not retry" was a false promise and is gone
  (a test now asserts the phrase never renders), and **4.4's scope widened** — the terminal
  verdict has to survive the next sweep's re-queue, so its red must cover the second cycle.
  Suite **1030 green, 9 pre-existing reds, 0 regressions**; analyze 0 errors; l10n gate green.
  Next agent-runnable: none in Phase 4 — 4.4 and 4.6 are owner-gated behind 4.0.
  **Also unticked:** 1.7 owner 30-second device proof.
  **Phase 3** stays owner-gated on design O1/O2.

- **Change (ACTIVE — queue head as of 2026-07-18, Phase 4 above being owner-gated):**
  `add-library-time-and-metadata-browsing` — the library is time-blind. Ordering is a
  hardcoded `createdAt DESC` in every DAO (`moves_dao.dart:29`, `combos_dao.dart:465`) with
  no user sort control anywhere; `moves.videoCreationDate` (when the clip was actually
  filmed) is stored and read by nothing; tiles show a thumbnail, a name, and a category label
  only when it isn't `'default'`. Adds: a persisted sort (added / filmed / practiced / A–Z)
  with a defined fallback chain per dimension (**D2**), month grouping on date sorts (**D3**),
  a date line on rows and tiles, and category recency computed in the existing count pass
  (**D5**). Sort stays client-side — the list is already fully in memory and filtered in Dart
  (**D1**). No schema change, no migration. **Owner-gated O1 (design D4):** metadata text on
  tiles pushes against the shipped visual-first ruling ("text is for input and settings"), so
  only the date is in scope by default; file size / original filename / backup state need a
  ruling. **5.3 is cross-change-blocked** on Phase 4 above — the tile's backup icon currently
  keys off `contentHash != null`, i.e. "tracked", not "backed up", and can't be made honest
  until `copyCount` can be trusted.
  **1.1 DONE by agent 2026-07-18** — `lib/core/models/library_sort.dart`: the `LibrarySort`
  enum, an `effectiveDate(sort)` extension per entity implementing D2's fallback table, and
  two comparators. The chains all terminate at the non-nullable `createdAt`, so
  `effectiveDate` is total — no entity can drop out of the ordering for lack of a date — and
  ties break by name then id, so ordering is deterministic rather than merely usually
  stable. Reading the code corrected D2: `watchLibraryRows` never hydrates `combo.updatedAt`
  (`combos_dao.dart:475-484`), so the practiced chain's middle link is dead in the only
  surface that uses it; the model is right, the SELECT is short one column, and that fix now
  sits in 2.1. Binary truth: 11 unit tests, each proven by mutation (reversing the date
  comparison and dropping the `videoCreationDate` fallback each go red), analyze 0 issues.
  **1.2 DONE by agent 2026-07-18** — `librarySortFromStored` (pure, in the model file) plus
  `librarySortProvider`/`LibrarySortNotifier` on the `library_sort` key, mirroring the
  `_viewModeProvider` idiom. Two deliberate departures: the key has no legacy vocabulary to
  migrate (it ships with one naming scheme), so tolerance is unknown-value → default rather
  than a migration map for values that never existed; and the provider is **public** where
  `_viewModeProvider` is private, because 2.1/2.2 both read it and because persistence is
  worth proving by driving the notifier against real SharedPreferences instead of asserting
  resolver symmetry the way `view_mode_test.dart` does. Default is `recentlyAdded` (today's
  behavior) and a stored preference is never overridden by it. Binary truth: 7 unit tests
  incl. a simulated-restart round-trip per sort, mutation-proven (changing the default goes
  −4; dropping the `setString` in `set()` goes −1, exactly the round-trip). `flutter analyze`
  0 errors (9 pre-existing infos), suite **1048 green / 9 pre-existing reds / 0 regressions**.
  **2.1 DONE by agent 2026-07-18** — `libraryMovesProvider`/`libraryCombosProvider` own
  filter-then-sort; the screen reads them instead of the raw streams. Reading the code
  corrected 1.1 by one surface: the library's combo tab never used `watchLibraryRows` —
  it used `watchAllWithMoveCounts`, which carries no `lastEntryAt`, and jotting does not
  stamp `combos.updatedAt`, so **both** middle links of the practiced chain were dead
  there, not one. Both library surfaces now read `watchLibraryRows`, with `c.updated_at`
  added to that SELECT and hydrated; `LibraryRow` maps to `(combo, moveCount)` at the
  sliver boundary so no widget signature moved. Ordering is proven by driving the
  derivation providers against a real in-memory DB, not by pumping the screen. Binary
  truth: 7 tests, mutation-proven (dropping both sorts −4, dropping the hydration −2;
  the fixture makes all four sorts yield four different orders, none the feed's own
  `createdAt DESC`). `flutter analyze` 0 errors, suite **1055 green / 9 pre-existing reds
  / 0 regressions**.
  **O2 RULED by owner 2026-07-18 — global, single key** (one `library_sort`, one control,
  both tabs together; per-tab can be widened later from the global value with no migration,
  the reverse cannot). Recorded in design.md; removed from task 5.1.
  **2.2 DONE 2026-07-18** — `LibrarySortToggle`, a third `_PillToggleRow` under the
  view-mode row: Added / Filmed / Practiced / A–Z, localized (4 ARB keys), persisting
  through `librarySortProvider`. Public so it can be pumped without the screen's live
  Drift streams. The shared `_PillToggleRow` needed one real fix to carry four pills — its
  bare `Text` label overflows a 320pt viewport at four items, so it is now `Flexible` +
  ellipsis; two and three pills are unchanged. Binary truth: 5 tests, each mutation-proven
  (remove `Flexible` → narrow-screen red; drop the `setString` → persistence red; hardcode
  `build()` to the default → restore-stored-sort red). `flutter analyze` 0 errors,
  `check_l10n.sh` green, suite **1060 green / 9 pre-existing reds / 0 regressions** (the 9
  re-confirmed against a clean stash of HEAD).
  **2.3 DONE 2026-07-18** — the combo tab now discloses the filmed-date fallback instead
  of quietly showing an added-date order under a "Filmed" pill: a caption
  (`LibraryFilmedFallbackNotice`) that renders for the filmed × combos pair only, naming
  both the absence and the substitute, in the user's own configured noun. The ordering
  half needed no code — 1.1's `effectiveDate` already resolved combo-filmed to
  `createdAt` — but it was unasserted at the provider level, so it was true only by
  construction; it is now proven against a real in-memory database on a fixture whose
  added order differs from its practiced order, so a leaked fallback reds rather than
  passing by luck. Binary truth: 5 tests, each mutation-proven (drop the segment guard →
  moves-tab silence red; hardcode the noun → rename red; point combo-filmed at the
  practiced chain → ordering red). `flutter analyze` 0 errors, `check_l10n.sh` green,
  suite **1065 green / 9 pre-existing reds / 0 regressions**.
  **2.4 DONE 2026-07-18** — date sorts now break the feed into month sections in scan and
  glance ("THIS MONTH" / "LAST MONTH" / "APRIL 2026"); study and A–Z stay flat per D3.
  Three pure functions (`library_month_sections.dart`) do the bucketing, labeling, and the
  should-we-group decision; `librarySectionedSliver` joins the caller's **existing**
  per-mode sliver builder once per section with `SliverMainAxisGroup`, so grid headers are
  full-width rows for free and **no row/cell/grid widget changed** — the alternative,
  interleaving headers into a flattened item list, would have moved `_MoveRow`'s stagger
  index and every builder signature with it. Two non-obvious rulings are pinned by tests:
  bucketing normalizes with `.toLocal()` (Drift hands back UTC; the raw instant puts a
  late-evening capture in the next month for anyone west of UTC — though that test is
  honestly vacuous under `TZ=UTC`), and a *future* month (wrong device clock) labels
  absolute rather than borrowing "This month" via a negative delta. Binary truth: 23 tests,
  five mutations each proven red (drop study exclusion, drop A–Z exclusion, never split a
  section, label from the month number alone, let the future fall into `thisMonth`).
  `flutter analyze` 0 errors, `check_l10n.sh` + `flutter build web` green, suite
  **1088 green / 9 pre-existing reds / 0 regressions**. Known gap, not papered over: the
  screen-level `dateOf: effectiveDate(sort)` junction is unasserted — reaching it means
  pumping the screen's live Drift streams, which flake widget tests.
  **3.1 DONE 2026-07-18** — the date line rows and tiles will show is now one localized
  formatter, built before any surface renders it, so "3 days ago" cannot come out four
  subtly different ways. Split in two: `libraryDateLine` in `lib/core/models/` classifies
  (`today` / `yesterday` / `daysAgo` / `absolute`) with no Flutter at all, and
  `formatLibraryDateLine` in the library's `widgets/` reaches for the ARB key or
  `DateFormat.yMMMd` — `lib/core/` imports no l10n anywhere in this repo and this did not
  become the first exception. Two rulings pinned by tests: the boundary is **calendar
  days, not elapsed hours** (something filmed at 11pm reads "Yesterday" at 1am, which
  24-hour arithmetic gets wrong), computed on UTC-normalized day ordinals so a 23/25-hour
  DST day cannot round a 7-day gap down into the relative arm; and a *future* date is
  absolute, the same ruling 2.4 made for months. Horizon: 7 days, exclusive.
  **Prior art acknowledged, not absorbed:** `lib/core/utils/time_format.dart`
  (`relativeTime`, compact + hardcoded English) and `_daysAgo` in `lab_detail_screen.dart`
  are unlocalized ancestors of this; converging them means ARB keys and context plumbing
  through unrelated features, so they stay put rather than becoming a drive-by refactor.
  Binary truth: 18 tests, **six** mutations each proven red (elapsed-hours instead of
  calendar days, drop the future guard, widen the horizon to 30, delete the yesterday arm,
  point the `daysAgo` arm at the yesterday key, drop the year from the absolute format).
  `flutter analyze` 0 errors (9 pre-existing infos), suite **1106 green / 9 pre-existing
  reds / 0 regressions**, `check_l10n.sh` green post-commit.
  **3.2 DONE 2026-07-18** — all four library surfaces now disclose a date, and it is the
  date the *active sort* ordered by. One `LibraryDateLabel` renders every one of them, so
  they differ only in the color the surface can afford (a row defers to the theme; a grid
  tile passes `white70` because it sits on a thumbnail). The screen resolves the date and
  the slivers carry it: a move resolves from the sort alone, but a combo cannot — its
  practiced date is `lastEntryAt`, which lives on `LibraryRow` and not on `Combo` — so the
  combo sliver payload widened from `(Combo, int)` to `(Combo, int, DateTime)`. That
  asymmetry is load-bearing: resolving combos downstream from the sort would silently show
  `updatedAt` where the sort used `lastEntryAt`, which is mutation M3. `_ComboRow` gained
  the same metadata `Wrap` `_MoveRow` already had, so the two row types read as one
  library. Study cards deliberately do **not** render the line (3.2 names four surfaces);
  their sliver takes the widened triple and discards the date. Binary truth: 12 widget
  tests pumping the **real screen** with the library providers overridden (no live Drift
  stream), **seven** mutations each proven red. `flutter analyze` 0 errors, suite
  **1118 green / 9 pre-existing reds / 0 regressions**, `check_l10n.sh` +
  `flutter build web` green.
  **Next agent-runnable: 4.1** (extend the per-category count pass in
  `MoveCategoryScreen:36-43` to also compute most-recent activity — design D5, same pass,
  no new query, no schema change). Phase 5 stays owner-gated on O1.

- **Change (owner-driven, parallel):** `add-dev-auth-and-sync-rehearsal` — de-risks the owner's Phase-M pass
  by letting a dev **user #0** rehearse the whole sync ladder without Google OAuth. **Agent
  wave DONE 2026-07-14** (owner greenlit; slots ahead of Phase M). Committed on `main`
  (UNPUSHED): proposal (`8da0253`) → **Phase 1** dev email/password auth seam (flag
  `DEV_EMAIL_AUTH`, OFF) → **Phase 2** runtime sync-cutover panel (flag `DEV_SYNC_PANEL`, OFF;
  the missing on-device switch-hand for `migrate-canonical-backend-to-appwrite` M.4) → **3.4**
  `docs/sync-rehearsal-runbook.md` (R1–R7 ledger + D7 fence). Binary truth: `flutter analyze`
  clean, `flutter test` green both flag configs, `flutter build web` green flags-OFF
  (byte-identical). **2026-07-14 owner-present wave:** 3.1/3.2 **DONE** — §A–§D all live
  (note tables + functions verified; web platforms `localhost` + `breakdex.vercel.app`
  registered via API, no console click); `dev0` minted (creds in `.env.local`) **plus** the
  owner account (`itsmxzou@gmail.com`, email-verified so Google OAuth later attaches to the
  SAME user — both auth doors, one account); spec gained **2.4** the panel's **Backfill now**
  takeover trigger (composed `fullBackfillServiceProvider`, per-entity row/batch report =
  M.3 parity evidence; backfill previously had NO runtime caller). **Remainder (owner-in-
  the-loop, next):** 3.3 `argent init` + smoke, **Phase 4** the live R1–R8 ladder on sim +
  web (owner drives; entry = `docs/sync-rehearsal-runbook.md`, prereqs banner says ready),
  then 4.9 ledger + the real **Phase M** pass (`docs/phase-m-runbook.md`) — the rehearsal
  raises its confidence but its M boxes stay the owner's. **2026-07-16: live Google OAuth
  PROVEN on the senik device** — two stacked faults fixed (SDK-25.x swallowed callback params
  → gateway rewritten to the token flow via `flutter_web_auth_2`; Appwrite Google provider had
  no client secret → pushed via console API). Server confirms the Google session + identity on
  the owner account; evidence in the Appwrite change's Phase-M note. **2026-07-16 (cont.):
  M.3 DONE + proven both layers** — owner's `Backfill now` seeded 139 rows into
  `itsmxzou@gmail.com`'s Appwrite space; a direct server `tablesdb …/rows` count == the
  phone's per-entity report exactly. **Inbound hydration built (unblocks M.6):**
  `Backfill now` was push-only and reads are local-Drift-only, so a fresh web client would
  show empty on sign-in → added `SyncService.hydrateAllFromBackend()` (inbound mirror,
  bypasses dual-read gates via the existing LWW core), fired **automatically on first login**
  + a dev **"Pull from backend now"** button. `flutter analyze` clean, `flutter test` 950
  green / 9 pre-existing reds / 0 regressions (+6 new), `flutter build web` green. **2026-07-17: M.6 DONE both halves** — agent-driven web proof
  (fresh Chrome profile, dev email door as owner: auto-hydrate 164 rows, library renders,
  session + data survive reload, re-hydrate no-ops) **plus the owner's live Google OAuth on
  web** (server sessions list shows `provider: google`, Chrome/Mac, expires 2027-07-17).
  D11 posture recorded in the M.6 tick: localStorage `cookieFallback` (cross-origin), httpOnly
  needs a custom API domain later. **Next unticked (owner-driven):** the **R1–R8 rehearsal
  ladder** (`docs/sync-rehearsal-runbook.md`, dev0 on sim + web) → then Phase-M remainder
  **M.4** cross-surface soak (phone must be signed in — its Google session was dropped when
  the owner dev password was set 2026-07-16; one re-sign-in) and **M.5** remote-config flip
  (provision the `appConfig/current` row). Push decision still the owner's (main ahead,
  unpushed).
  Prior queue head
  (`add-web-first-release-and-monetization`, launch wave L1–L6) is **DONE** — history below.

- **Change:** `add-web-first-release-and-monetization` — **🚀 Launch wave (owner ruling
  2026-07-13; launching today).** A fresh Opus 4.8 session executes it: read that `tasks.md`'s
  **"🚀 Launch wave — executor entrypoint"** preamble FIRST — it sets the order (L1 GUIDE.md →
  L2 versioning → L3 argent-driven web smoke → L4 Vercel deploy pipeline → L5 invites flag-OFF →
  L6 Lemon Squeezy payments seam) and records the four Phase-0 rulings (LS / 3-tier one-time
  $4.20–$6.99–$9.99 / `breakdex.vercel.app` / crew–beta–owner cohorts). Runs **parallel to the
  owner's Phase M device pass** (`docs/phase-m-runbook.md`, `migrate-canonical-backend-to-appwrite`) —
  neither blocks the other; nothing in the launch wave needs the soak, and nothing destructive
  (Appwrite 5.1/5.2, Phases 6–7) starts until the soak passes.
- **🚀 Launch wave (2026-07-13): L1–L6 ALL DONE — every agent-runnable item landed.** Commits on
  `main`, **PUSHED** to `origin/main` 2026-07-13 (owner-authorized, all 26 wave+launch commits,
  fast-forward `76840af..418c550`). Binary truth throughout: `flutter analyze` 0 errors,
  each Function `dart test` green, client `flutter test` green, `flutter build web` green, 0
  regressions. Summary:
  - **L1 (4.1 `GUIDE.md`)** — rider-facing guide at repo root.
  - **L2 (4.2 versioning)** — convention in GUIDE + **repaired rotted release pipeline** the verify
    surfaced (`@semantic-release/changelog` + `update_release_metadata.cjs` still pointed at
    root/deleted docs from the 2026-07-06 consolidation → would crash `semantic-release` on the next
    `feat`/`fix` push; now target the real `docs/` set; script dry-run exit 0).
  - **L3 (1.6 web smoke)** — `/breakdex`,`/add`,`/review` render clean in real Chrome, **0 console
    errors**; perf baseline FCP 772 ms / CLS 0.00 / main.dart.js 5.47 MB uncompressed. chrome-devtools
    MCP (sanctioned fallback); full canvas-tap click-through fenced to argent/Phase-M.
  - **L4 (4.3 Vercel pipeline)** — `deploy-web.yml` builds web + `vercel deploy --prod` to
    breakdex.vercel.app; `release.yml` auto-calls it on a published tag (sidesteps the GITHUB_TOKEN
    tag-trigger gotcha); `web/vercel.json` SPA + no-cache + **no COEP** (keeps Drive video + OAuth);
    rollback = dispatch on a prior tag / Vercel Instant Rollback; `docs/web-deploy.md` owner setup.
  - **L5 (Phase 2 invites, flag-OFF)** — `invites`/`entitlements` tables; `invites-redeem` Dart
    Function (idempotent per (user,code), typed rejections, 10/10); `EntitlementGate` pure gate +
    root `EntitlementGatePrompt` (`kEntitlementGateEnabled` **OFF** → inert, byte-identical builds);
    `userCohortProvider` binds cohort into `RemoteConfig.flag(cohort:)`; client tests 13/13.
  - **L6 (Phase 3 Lemon Squeezy payments)** — `payments-webhook` Dart Function (constant-time HMAC
    verify fail-closed, idempotent per LS order id, `order_created`→grant, `order_refunded`→revoke
    **status-only, never deletes data** = lockout not loss, 12/12); `checkout.dart` offerings
    ($4.20/$6.99/$9.99) + pure LS checkout-URL builder; entitlements schema gained `status`/`orderId`.
  - **Owner-gated remainder (NOT agent-runnable):** ~~the push decision~~ (✅ pushed 2026-07-13);
    **live provisioning** (targeted `tables-db create-*` for `invites`/`entitlements` + `push
    functions --activate` for `invites-redeem`/`payments-webhook` — NEVER `push tables --all`); the
    Vercel OAuth + 3 secrets (`docs/web-deploy.md`); the Lemon Squeezy account + variant ids + webhook
    secret; flipping `kEntitlementGateEnabled` on; `4.4` wave-1 mint+send; `4.5` soak; and the
    Appwrite Phase M device pass. **No agent-runnable launch task remains** — the wave is code-complete.
- **Prior change:** `migrate-canonical-backend-to-appwrite` — **⚡ Overnight wave (owner ruling
  2026-07-12), COMPLETE + maximally advanced pre-soak.** Its wave preamble + `design.md` D11
  remain the reference. `main` is the merged single source of truth; all wave commits **pushed**
  to `origin/main` 2026-07-13.
- **▶ NEXT SESSION ENTRYPOINT (`openspec apply migrate-canonical-backend-to-appwrite`):**
  **Phase M — the cross-surface "same data everywhere" proof.** Everything code-side is done,
  green, pushed, pref-OFF. What remains is the live half, run start-to-finish from
  `docs/phase-m-runbook.md` with the owner present: **(A)** CLI auth from `.env.local` (keys
  verified present 2026-07-13) → **(B)** provision `moveNoteEntries`/`comboNoteEntries` via
  targeted `create-*` (never `push tables --all`) → **(C)** `push functions --activate` →
  **(D)** console: register web origin(s) → **(E)** device pass **M.1–M.6** (build/boot → live
  iOS Google login → real-data backfill → **M.4 flip-the-prefs cross-surface soak** = phone edit
  seen on web + back, per-entity, notes+tombstones last → remote-config flip 1R.4 → web login) →
  tick M.1–M.6 + V.3 in the master `tasks.md`. Launch-side provisioning (invites/entitlements
  tables + `invites-redeem`/`payments-webhook` Functions + Vercel + Lemon Squeezy) can ride the
  same authenticated session — see the launch-wave block above.
- **Phase 5 advance (owner-directed 2026-07-13):** both unblocked Phase-5 tasks landed —
  `5.3` (Drive metadata safety-net export; code-complete + flag-OFF: tombstone-safe v10 codec +
  `MetadataBackupService`, gated `kMetadataDriveBackupEnabled` default OFF, commit `9e1748e`) and
  `5.4` (self-host runbook `docs/appwrite-selfhost.md`, commit `4b65df6`). **Phase 5 is now
  maximally advanced pre-soak.** Everything left in Phases 5–7 is hard-gated on the owner's
  Phase M device soak: `5.1`/`5.2` (destructive Firestore/Firebase removal) need "all entities
  green + soaked"; Phase 6 (web studio on new substrate) needs the Flutter cutover live; Phase 7
  is flagged "do not start before Phase 6 ships". Do not start any of them pre-soak.
- **Next task:** ✅ **Overnight wave COMPLETE** (2026-07-13). All items 1–7 landed on `main`
  (9 local commits `46abea0..` the V.1/V.2 commit, **not pushed** — owner-gated). `flutter analyze`
  0 errors; `flutter test` 916 green / 9 pre-existing reds / **0 regressions**; `flutter build web`
  green. See the master `tasks.md` **✅ Wave report — 2026-07-13** for the full proven-vs-Phase-M
  split. **Next is owner-in-the-loop: Phase M** (physical device, this morning) — M.1 build/install,
  M.2 live iOS Google login, M.3 real-data backfill, M.4 cross-surface soak (the flip-the-prefs
  proof), M.5 config flip, M.6 web login — plus the owner-gated live Appwrite provisioning
  (targeted `tables-db create-*` for the note-entry tables + `push functions --activate`; never
  `push tables --all`). ~~Push decision~~ ✅ done — everything is on `origin/main` (2026-07-13).
  **Done in the wave so far:** `0.5` → `0.2` → `3.3` → `3.4` → `4.1`–`4.3` (moves cutover template
  complete) → `4.4` (combos + combo_moves; 23/23) → `4.5` (reviews append-only; 18/18) → `4.6`
  (fsrs_cards pull-only server-derived; 13/13) → `4.7` (decks + deck_moves; 24/24) → `4.8`
  (tombstones end-to-end for all 5 delete-bearing entities, schema v26 `deleted_at`; 9/9) →
  **`4.9` (note entries become Appwrite-only synced entities: schema v27 `updated_at`+`deleted_at`
  on both note tables, `note_entry_codec`, `SyncEntityType.{move,combo}NoteEntry`, DAO
  dirty-tracking + soft-hide read-filters, dual-write/read + inbound-tombstone engines, backfill,
  config tables authored + Function allowlist→7 + tests; pref OFF until M.4. 24/24 new tests,
  Function tests 19/21 green, `test/core` 789 green 0 regressions; live provisioning + Function
  redeploy + two-device note soak ride M) → **web-first `1.4` (URL video seam: `networkVideoController`
  + `supportsUrlVideoPlayback` + `RobustVideoPlayer.videoUrl`; HTML `<video>` playback web-capable;
  Drive-URL resolver + web import + live playback ride M.4) + `1.5` (web Appwrite OAuth: success/failure
  redirect URLs on web via `Uri.base.origin`, httpOnly-cookie posture code-clean, SyncBackend transport
  already web-safe; live web login rides M.6) — cross-change, both ledgers ticked; auth 15/15 + video 7/7
  green, 0 regressions.**
  Remaining wave order: `V.1`/`V.2` sweep + wave report. **Phase M (morning 2026-07-13,
  owner on the physical device)** holds every owner-in-the-loop proof: live Google login (M.2),
  real-data backfill (M.3), two-surface soak (M.4), config flip 1R.4 (M.5), web login (M.6).
- **Owner-gated residue (parked, does not block the wave):** 0.4's Convex console delete; final
  brand art (`harden-code-ownership-and-config-purge`); web-first Phase 0 rulings
  (payments/domain/invites).
- **⚠ Ops hazard (learned 1R.1):** do **NOT** run `appwrite push tables --all` against the live
  `breakdex` project. This CLI (22.6.1) diffs omitted-`array` (config) vs `array:false` (deployed)
  as a change and **recreates existing columns** — it deleted all of `moves`'s attributes mid-run
  and left dangling `stuck` indexes (unrepairable via `delete-index`; only a table drop+recreate
  cleared them). `moves` was rebuilt from config (0-row, pre-cutover → no data loss) and all 10
  tables re-verified green. Provision NEW tables via **targeted** `tables-db create-*-column` /
  `create-index` calls (auth: `set -a; source .env.local` → export `APPWRITE_ENDPOINT/PROJECT_ID/
  KEY` — the CLI prefs `current` points at throwaway `6a51…` projects, not `breakdex 6a50f25b…`).
- **State pointer:** per-phase progress notes live in the ledgers (each change's `tasks.md`
  task notes), not here — this block stays a pointer. Shipped so far: master phases H, 0 (minus
  the 0.2-verify + 0.4 console click), 1, 1R (minus 1R.4), 2 complete; 3.1/3.2 built seam-only
  and unwired; web-first 1.0–1.3 done + the CI web-build half of 1.6.

## Backlog — OpenSpec change order (D8, canonical)

Priority order for pending OpenSpec changes, top first. This is the authoritative sequencing
(align-cross-client-foundations D8); the risk-ordered workstream narrative further down is the
older intra-app view and is kept for context.

1. **`migrate-canonical-backend-to-appwrite`** — the backend spine. Phase H done
   (`phase-h-hardening`); **Phase 0 provisioning is NEXT and owner-gated** (Appwrite Cloud
   project + Google OAuth; owner confirmed ready 2026-07-08). Now also carries **Phase 1R
   remote config** (flags, kill-switches, min-version gate, cohort profiles) and the flagged
   Shorebird code-push evaluation (7.4).
2. **`add-web-first-release-and-monetization`** — ⭐ NEW (2026-07-08 grilling): web-first
   private release of the product itself. Flutter Web bring-up (Phase 1, startable NOW),
   invite codes + entitlements + $4.20–$9.99 offerings (gated on Appwrite Phases 0–3/1R),
   GUIDE.md + release hygiene, then iOS TestFlight → App Store → Android after the web soak.
3. **`add-web-authoring-and-lifecycle-studio`** — web = trustworthy system-of-record +
   authoring studio; targeted by Appwrite Phase 6. **Supersedes
   `evolve-web-mirror-to-crud-platform` (owner ruling 2026-07-08; archived):** absorbed its
   unshipped write scope as Phases 4–6 plus the `web-library-crud` + `media-governance`
   deltas. Now also carries **Phase 7 MDX developer docs** (seam docs + runbooks live with
   the studio, build in CI).
4. **`redesign-visual-first-experience`** — ⭐ NEW (2026-07-08 product-finish): visual
   anchors over text (Add flow de-text, media-grid membership + 4-slot tiles), 3 view modes
   (Glance → Scan → Study), review WYSIWYG (one screen, `xxs` radius, customizable fill),
   Fluid/Morph motion doctrine. **Release-blocking for wave-1 invites**; no backend
   dependency — parallel with Appwrite phases.
5. **`harden-marathon-reliability`** — ⭐ NEW (2026-07-08): 8-hour soak bar, startup budgets
   (≤2.5s mobile / ≤5s web), **device-diagnostics status page** (deterministic per-device
   checks + redacted JSON export), 3-platform E2E matrix (Patrol/Maestro/Playwright) — the
   matrix IS the wave-1 invite gate. Phases 1–3 independent; startable now.
6. **`add-personalization-and-accessibility`** — NEW (2026-07-08): parametric naming of the
   Moves/Combos data-banks, add-flow order preference (edit-while-adding), party default ON
   (fresh installs only; stored prefs untouched), settings IA + live self-confirming
   customization, color-blind + monochrome themes, i18n foundation (gen-l10n + ARB).
7. **`add-capture-and-pro-metadata`** — NEW (2026-07-08): Record entry (system camera path
   already in `video_service.dart`), fps/resolution/codec probe + additive migration,
   bytes/names-preserved invariant + NLE JSON sidecar (DaVinci/Blackmagic interop),
   open-with-Breakdex (iOS/Android/web), deck/set annotations.
8. **`align-cross-client-foundations`** — this change (gap-filler: multi-user sync model,
   security posture, tokens, notes dirty-guard, web state machines, ledger hygiene). Wave 1
   lands now with no Appwrite dependency; Waves 2–3 ride Appwrite Phases 4/6.
9. **`harden-code-ownership-and-config-purge`** — NEW (2026-07-08): per-directory purge +
   justify sweep (zero behavior change, pure deletions, git history = undo). Rolling: a
   directory sweeps only after its migration lands; gate before invites go broad.
10. Nearly-done finishing passes: `foundation-data-resilience` (59/64),
    `tighten-combo-journey-and-review-polish` (33/36), `repo-organization-and-readme-refresh`
    (12/15), `add-historical-photos-bootstrap` (7/9), `add-web-mirror-player` (19/26).
11. **`state-machine-crud`** — kept open as the tracker for genuinely unshipped residual work
    (TrashMachine, MoveListMachine, AppMachine, notes/log overlays); the `Machine<S,E>`
    framework + move-detail vertical already shipped (see its `tasks.md` Residual header).
12. Everything else parked (labs, provenance/beam ingestion, research workbench, photo
    archive recovery, etc.).

**Recently reconciled (2026-07-06 ledger audit):** archived `add-convex-sync-backend`
(superseded by Appwrite), `add-discovery-graph-interface` (26/26 shipped), and
`add-silent-video-mode-and-accessible-drill-launcher` (duplicate of the 2026-06-16
silent-playback change). `add-quiet-playback-and-senior-drill-ui` re-scoped to its unshipped
settings-dedup Phase 4 only.

---

## Product steering (folded from docs/ROADMAP.MD + docs/PROGRESS.MD, 2026-07-06)

Product-lane view — what to stabilize now, what expands the practice loop next, what is
deferred. (Backend-sync lanes now mean **Appwrite**, per the banner above.)

| Horizon | Lane | Goal | Status |
| --- | --- | --- | --- |
| Now | Review-loop clarity | Calmer, more controllable, more trustworthy sessions. | Active |
| Now | Progress ergonomics | Parent-first navigation + immediate graph entry; less random analytics. | Active |
| Now | Flow truthfulness | Honest move-first graph before richer entities. | Active |
| Now | Native media reliability | Keep import/album/export stable on iOS. | Active |
| Next | Combo & set graphing | Graph beyond move-only nodes without overstating what is live. | Planned |
| Next | Planning surfaces | Make Lab / sprint tools genuinely useful prep boards. | Planned |
| Next | Stronger analytics | Calendar, heat-map, retention around real coaching decisions. | Planned |
| Next | Sync hardening | Tighten migration, conflict, cloud consistency (Appwrite). | Planned |
| Later | Cross-platform parity | Keep iOS quality while validating broader device support. | Deferred |
| Later | Research feedback loop | Feed scientific-workbench findings back into scheduling. | Ongoing |
| Later | Coach & team workflows | Shared practice intelligence after the solo loop is stable. | Deferred |

**Current product shape:** Arsenal (moves/combos/source video), Review (FSRS spaced
repetition), Flow (move-transition graph + set building), Stats (review history → progress
signals), Settings (theme/color/sync/export). Active WIP: Progress (parent-first + secondary
superfan analytics), Lab (marked unfinished in nav), Flow (honest move-first graph), Review
(instrument-panel controls, color-state customization, quieter playback tightening).

**Release snapshot:** `v1.3.0` (`1.3.0+5`), released 2026-04-28. Release/provenance metadata
is generated by `scripts/update_release_metadata.cjs`.

---

## North Star (the thesis)

**Breakdex is a thin shell + a logic kernel over data the user owns.** The footage and
the practice graph live in environments the user already trusts (their device + their
cloud), reachable anywhere — not locked inside the app. This is **local-first + BYO-cloud**
(the "your data is just files in your Drive" philosophy, applied to breaking).

- The **video (move) is the primitive.** Combos, journals, plans, FSRS all compose around it.
- The app is a **lens/editor**, not the vault.

### The product spine — the practice loop (the differentiator)

Review + journal + todo are **one loop**, not three features. The `ReviewCard`
(`flashcard_review/widgets/review_card.dart`) already fuses **watch → state → rate**;
the loop closes when reflection feeds the next session:

```
FSRS surfaces an item → ReviewCard (video) → RATE (again/hard/good/easy → reschedule)
                                            → STATE (idea→attempting→landed→clean; auto-logs kind='status')
                                            → JOT  (free reflection)            ← MISSING UI
                                            → PLAN (jot/state → ComboPlans date) → calendar → back to top
```

**Verified state of the parts:** rating (`rating_button_row`), state pill
(`state_picker_sheet`, `InstrumentPanel`), and the immutable status timeline
(`CombosDao.updateStatus` → `kind='status'`) all exist. **Only the inline jot capture is
missing** — `ComboNoteEntries(kind:'jot')` table + DAO exist, but `insertJot` has **zero
callers in any feature**. This is the cheapest, highest-leverage weave in the whole app.

---

## ⚠️ Brownfield reality — governing constraints

**This is a late-stage production app with real users and real data.** Risk discipline
overrides architectural purity. Every item below is filtered through these:

- **Additive over invasive.** New capability via new code paths; don't rewrite working ones.
- **Never delete or orphan user state.** Videos, the graph, Drive blobs — all sacred.
- **Migrations are one-way and tested.** Schema is at v22; any change = forward migration,
  proven on a copy of real data, never destructive.
- **Drive renaming is lazy + backward-compatible.** Write new (semantic) names going forward;
  resolve *both* old hash-names and new names; never bulk-move existing blobs blindly.
- **Risky changes ship behind feature flags + staged rollout**, reversible.
- **Don't refactor a working critical path without a test around it first** — especially the
  settings "delete all data" path and the sync engine.
- **Verify on a real build before claiming done.**

> Consequence: the "clean the kernel" refactor is **opportunistic + test-guarded**, not a
> prerequisite sweep. Reorder the sequence by **risk**, not just value (see below).

---

## Architecture decisions — LOCKED

| Decision | Choice | Notes |
|---|---|---|
| Cross-platform | **Flutter, one codebase** | Web is a build target, not a second app. No Turborepo (JS-only). Melos only if we split Dart packages later. |
| Source of truth | **Local sandbox** (SQLite + canonical folder) | Opens the proper move, works offline. |
| Video bytes | **Google Drive** | Human-named, browsable, user-owned; the web viewer reads from here. |
| Graph (moves/combos/FSRS/notes) | **Firebase (Firestore)** | Small relational state; syncs across devices (Android+iOS super-user); backs web login. |
| "Double-backed up" | **Split by type, not duplicate** | Videos = local + Drive. Graph = local + Firestore (+ JSON manifest mirrored to Drive). NOT every video copied into Firebase (cost). |
| Web layer | **Thin, login, view-only** | No recording on web — major simplification. |
| Conflict model | **Last-writer-wins + version log** | **No CRDT** — single user, ~one device at a time. Revisit only if real multi-device conflicts appear. |
| Scale | **Not a current problem** | Backend is the user's Drive/Firebase; Google handles scale. Ship to user #1 first. |
| Security baseline | **Keychain tokens + `drive.file` scope + no repo secrets** | `drive.file` already in use (app sees only its own files). Don't invent crypto. |

---

## Workstreams

### 1. Storage & Sync  — *partially built*
- **EXISTS:** `gdrive_provider.dart` (OAuth, upload/download/verify, `Breakdex/<hash>.mp4`),
  `canonical_folder_service.dart` (`.breakdex-master/`, ledger, relative paths),
  `video_path_resolver.dart` (relative DB paths + **semantic paths** `Moves/{Cat}/{Name} - {Hash}.ext`, path healing),
  `asset_sync_engine.dart` (2-copy minimum), `cloud_provider.dart` (provider interface),
  `library_manifest.dart` (whole-library JSON export).
- **DELTA:** Drive is currently a *replica*, not the user-facing library. Videos are
  **hash-named** in Drive (`a3f9.mp4`) — not browsable. Firebase provider is a stub.
  `MediaDeliveryProvider` (signed URLs) unimplemented.
- **TO DO:** use semantic naming **in Drive** so the folder is a real library; finish
  Firestore graph sync; mirror the JSON manifest to Drive.

### 2. Data ownership & deep-link ("open the literal video")  — *~80% built, just disconnected*
- **EXISTS:** iOS registers as viewer for `public.movie`/`public.video` (`Info.plist:11`);
  `AppDelegate.swift` `FileOpenPlugin` buffers the opened file URL;
  `deep_link_resolver.dart` has 3-tier matching (filename → size → combo notes) → returns move/combo route.
- **DELTA:** the **Swift→Dart bridge is unwired** — `deep_link_resolver` has no caller.
  (This is the "zombie" the quality scan flagged: not dead, *disconnected*.)
- **TO DO:** wire the channel → resolver → router. Opening a video lands on **that move**, not home.

### 3. Thin web viewer  — *not started*
- **EXISTS:** nothing web (no `web/` dir; 33 `dart:io` imports in `lib/core`).
- **DELTA:** view-only viewer = login (Firebase Auth) + list Drive folder + play + show notes.
- **TO DO:** cheap **once #1 (readable Drive) + #6 (clean kernel) are done.** Build last.

### 4. Combos UX  — *~80% built; needs reshaping*
- **EXISTS:** `combos_screen.dart` — one screen, 3-segment toggle **Library / Planned / Calendar**.
  Calendar = month grid with activity heat + future plan-dots + day-detail. Planner flow
  (`plan_combo_flow.dart`) writes `ComboPlans(planDate)`. Status: idea/attempting/landed/clean.
- **DELTA:** Calendar **first** (currently last); fold **Planned into Calendar**
  (2 modes, not 3 — the calendar *is* the planning timeline); add **week/day zoom**;
  unify CTA to **View / Plan**. No status filtering today.
- **OPEN Q:** 2 modes (fold Planned in) vs keep a separate flat "upcoming" list. *(lean: fold in)*

### 4b. Combo planning — audited logical errors (2026-06-16)
- **GOOD:** the historical disposed-`ref` silent-plan-drop bug is **genuinely fixed** —
  `plan_combo_flow.dart:25-65` moved the write onto a live caller `ref`, every async gap guarded.
- **P1 — silent jot/completion-stamp failure: ✅ FIXED.** `jot_composer.dart` `_send`/`_attachVideo`
  catch blocks now surface a `mounted`-guarded SnackBar ("Couldn't save your jot." / "Couldn't link the
  video.") instead of swallowing the error. Pure additive.
- **P1 — TZ/DST mis-stamp: ✅ FIXED (read-path only, no migration).** `combo_plans_dao.stampCompletionsFromEvidence`
  now anchors `plan_date` at local **noon** (`date(plan_date,'unixepoch','localtime','+12 hours')`) before
  comparing days, so any device-offset change under 12h can't flip the plan's day. Chose this over the
  `'yyyy-MM-dd'` write-format change to avoid a migration on deployed data; fixes existing and new rows alike.
- **P1 — `deleteCombo` orphan leak: ✅ FIXED (non-destructive).** `deleteCombo` now also clears the
  structural `combo_moves` (joins the comboPlans precedent — meaningless once the combo is gone), but
  **deliberately keeps user-authored `combo_note_entries`**. The "Practiced" strip (`watchProgressStrip`)
  and calendar heat (`watchActivityRollup`) are now **scoped via `EXISTS (... combos ...)`** so orphaned
  jots stop inflating stats without anything being deleted. Honours the never-delete-user-state rule.
- **Coverage:** `test/core/database/combo_journey_dao_test.dart` adds orphan-scoping + jot-preservation cases.
- **P2s:** cross-day reorder bounce-back; non-transactional combo create (partial moves); same combo
  plannable twice for one day; calendar counts completed plans as "planned". (See audit for file:line.)

### 5. Loading reliability  — *WIP*
- **EXISTS:** `stall_detector.dart` (uncommitted), boot/transfer progress (commit `757d909`).
- **PROBLEM:** loading gets stuck in a stage, no 0→100 — likely **video access coupled to a
  cloud/boot stage that can hang**.
- **TO DO:** (a) **local video access never blocks** on any sync/cloud stage; (b) optimistic
  paint from cached DB; (c) incremental render from Drift `watch*` streams; (d) per-stage
  watchdog via `stall_detector` → **degrade, don't freeze**; determinate aggregate progress.
- **OPEN Q:** where does it stick — cold boot / opening a video / during sync?

### 6. Headless kernel cleanup  — *the prerequisite*
- **PROBLEM (P0 from scan):** views touch the DB / filesystem directly —
  `settings_screen.dart:542` raw `db.delete`, `battle_providers.dart:184` raw `insert`,
  `metadata_video_picker_sheet.dart:160-202` raw file I/O. 13 widgets import `dart:io`.
- **TO DO:** push these through services/repos. This **is** your "function kernel vs view
  rendering" split, and it's the gate for any web layer.
- **ZOMBIES to delete:** `S3Provider` (6 TODO stubs, never instantiated), `DeleteStateMachine` (never constructed).

### 7. Journaling = the practice-loop weave  — *seed exists, the spine is one gesture away*
- **EXISTS:** `ComboNoteEntries` (kind: jot/status/plan/duplicate, optional `videoPath`),
  `MoveNoteEntries`, `ComboPlans`. Status changes already log immutable `kind='status'` entries
  (a state timeline). Review card already does watch → state → rate.
- **THE WEAVE (highest leverage, additive, ~1 day):** add a **jot affordance to
  `InstrumentPanel`** → quick-capture sheet writes `ComboNoteEntries(kind:'jot', comboId,
  videoPath, body)`. `insertJot` currently has **zero callers in any feature** — wiring it
  closes the practice loop. Fast-follow: jot → "plan it" → `ComboPlans(planDate)` → calendar.
- **DEFER:** revision history; "notes-as-files (Obsidian)" vs "notes-in-DB".
- **OPEN Q:** notes browsable as files in Drive, or DB-only with Markdown export later? *(lean: DB now, export later)*

---

## Recommended sequence — ordered by RISK (brownfield)

Lowest-risk / highest-live-value first. Risk tag = blast radius on existing users' data.

```
Phase 1  Never-stuck loading     → decouple video access from cloud; wire watchdog  (#5)  [ADDITIVE · live bug]
Phase 2  Open the literal video  → wire deep-link bridge (already ~80% built)       (#2)  [ADDITIVE · new path]
Phase 3  Combos: calendar-first  → fold Planned in, week/day zoom, unified CTA      (#4)  [UI-ONLY · safe]
─── feature-flagged from here; migration-sensitive ───
Phase 4  Own your footage        → semantic Drive names, lazy + back-compat         (#1)  [MIGRATION-RISK]
Phase 5  Multi-device + web      → Firestore graph sync → thin view-only viewer     (#1,#3)[NEW INFRA · staged]
opportunistic  Kernel cleanup    → fix P0 leaks only when already in the file,      (#6)  [TEST-GUARDED]
               + delete true zombies (S3Provider, DeleteStateMachine)                     [safe deletes]
```

**Defer (write down, don't build):** CRDT, "massive scale", journal revision history,
notes-as-files, Drive-as-canonical inversion, big-bang kernel refactor.

**Brownfield guardrails per phase:** P1 touches no data (pure decoupling + watchdog).
P2 adds a path, changes none. P3 is UI-layer only. P4 must resolve *both* old hash-names
and new semantic names + never delete Drive blobs. P5 is a new backup channel behind a flag.

---

## Open questions still to resolve (the parked grill)

- **Storage Q2 — Auth:** what identity backs the web login + multi-device? (Firebase Auth w/ Google sign-in is the natural fit — already have GIDClientID config.)
- **Storage Q3 — Sync mechanics:** what exactly syncs, and how do the super-user's two devices reconcile? (last-writer-wins + version log)
- **Storage Q4 — Web shape:** Flutter-web build vs a genuinely separate thin web app reading Firestore+Drive directly.
- **Storage Q5 — Deep-link details:** custom `breakdex://` scheme + share-intent, or file-open only.
- **Combos:** 2 modes vs 3.
- **Loading:** which stage stalls.
- **Journaling:** notes-as-files vs DB-only.

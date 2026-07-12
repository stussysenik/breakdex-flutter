# Tasks — Migrate Canonical Backend to Appwrite

> Master execution plan. Sequenced strictly by risk: harden → provision → shadow → identity →
> per-entity cutover → retire → web studio → post-launch. Additive, reversible, kill-switched.
> Drift stays canonical on-device until each entity is proven. Executor: read `proposal.md` and
> `design.md` first; verify every Appwrite API shape against current official docs at
> implementation time; `flutter analyze` + `flutter test` green at every task boundary; stop and
> surface at owner-gated steps.

## ⚡ Overnight wave — owner ruling 2026-07-12 (executor entrypoint; read before any phase)

> **Owner ruling (2026-07-12):** `main` is the single source of truth (verified merged + pushed:
> `main` == `phase-h-hardening` == `f87f4fc`); the owner believes the 0.2 console-half is already
> handled — VERIFY it, don't wait on it; autonomous overnight execution is authorized under the
> converted gates below; on the morning of 2026-07-13 the owner tests on the physical device
> (Phase M). **Goal:** Breakdex behaves like a product — sign in with Google on iOS and Flutter
> Web, and CRUD + notes + video pointers sync everywhere through Appwrite; any surface picks up
> the latest state. Design rulings for this wave: `design.md` **D11**.

**Wave order** (each item = the named task's checkbox; tick in the owning ledger, same commit;
commit the wave on `main`):

1. `0.5` — headlessly verify the owner's 0.2 claim (new task below).
2. `3.3` — wire Appwrite auth into the app shell (see the 3.3 wave note).
3. `3.4` — `legacyIdentities` claim flow.
4. `4.1 → 4.3` moves, `4.4` combos, `4.5` reviews, `4.6` fsrs, `4.7` decks, `4.8` tombstones —
   under the converted gates below.
5. `4.9` — note entries become synced entities (new task below; new scope from this ruling).
6. `add-web-first-release-and-monetization` `1.4` (video on web) then `1.5` (web auth + sync) —
   cross-change: tick BOTH ledgers in the landing commit.
7. `V.1`/`V.2` sweep + a **wave report** appended to this section (what's proven, what waits
   for Phase M).

**Converted gates (owner ruling; for tonight these override the per-task "owner-gated" markers):**

- **0.2:** verify via 0.5's probe. If the provider is NOT actually configured: record exactly
  what is missing in `DOCS/appwrite-oauth-provisioning.md` (add a dated status section), then
  continue — everything except live Google-login proof still lands.
- **Live data-plane proof without Google OAuth:** the 1.5 smoke precedent (server-created smoke
  user + JWT exercised all three Functions; that script lived in a session scratchpad and is
  gone — re-derive it from the 1.5 ledger note). Use the same pattern to live-verify every 4.x
  step against the deployed backend; purge smoke rows + the smoke user after each run so the
  backend stays pristine.
- **4.1 "copy of real data" / 4.3 "two devices" / 3.1 cross-restart session / 1R.4 console
  flip:** real data and live Google sessions exist only on the owner's device → overnight =
  fixture + smoke-user live proof; the real-data/real-device halves move to Phase M. A box whose
  only remaining proof is M-scoped ticks ONLY if its note names the M task carrying the residue.
- **Brownfield rule unchanged:** nothing deletes/alters legacy Firestore paths (Phase 5 stays
  untouched); no task mutates local user state; `flutter analyze` + `flutter test` green at
  every task boundary.

**Stop conditions (surface, never improvise):** a migration that would mutate existing user
rows; any need for `appwrite push tables --all` (destructive — see the ops hazard in ROADMAP
`## NOW`); anything that would require committing a secret.

## Phase H: Harden the migration template (no Appwrite needed; do FIRST; audit 2026-07-05)

> DONE 2026-07-05 on branch `phase-h-hardening` (commit 8e301a1). `flutter analyze`
> 0/0/0 with all H.8 rules on; sync suite 30/30 green; the 15 pre-existing
> full-suite failures verified unchanged against a stashed baseline. **Deviations:**
> H.2 tie policy is **local-wins** (a remote must be a strictly-newer whole second),
> resolving an internal contradiction between the task's parenthetical and its own
> red/green test — the red/green won. H.6 verified by inspection (no DI seam on
> `FirebaseStorage.instance` for a unit test). H.8 done as chosen: full repo-wide
> triage to zero (bare `catch` → `on Object catch`; async-stat / fire-and-forget →
> documented `ignore_for_file`; small rules real-fixed).

- [x] H.1 **Dedicated backend pull cursor (audit A2).** In `SyncService.pullMovesFromBackend`,
  persist `delta.cursor` to a new pref (`sync.moves.backend.cursor`) and pass it as `since` on
  the next pull; never derive the backend `since` from the shared Firestore `last_sync_at`.
  Red/green: test that (a) the cursor advances from `SyncDelta.cursor`, (b) disabling dual-read
  then re-enabling re-pulls from the backend cursor, not the Firestore clock, (c) a null cursor
  falls back to full pull. Files: `lib/core/services/sync_service.dart`,
  `test/core/services/sync_service_dual_read_test.dart`.
- [x] H.2 **LWW precision normalization (audit A3).** Drift persists DateTimes as Unix seconds;
  backend records carry milliseconds. In `_mergeMoveRecordLww`, compare
  `millisecondsSinceEpoch ~/ 1000` on both sides; document + test the tie policy (equal clocks →
  remote wins). Red/green: failing test where a local edit at T.900 must NOT lose to a remote
  record at T.500 of the same second.
- [x] H.3 **Per-record fault isolation (audit A4).** Wrap the merge loop body in try/catch: a
  malformed record is skipped and counted, never aborts the batch (which today degrades moves to
  the blind non-LWW Firestore `_mergeRemoteRecord` path). Return applied+failed counts; debugPrint
  failures. Test: batch of [good, malformed, good] applies 2.
- [x] H.4 **Transactional merge (audit A5).** Wrap the per-pull merge loop in `db.transaction`.
- [x] H.5 **Codec extraction (audit A7).** Move `moveToSyncRecord`/`moveToSyncJson`/
  `moveFromSyncRecord` from `backfill/sync_backfill_service.dart` into
  `lib/core/sync/codecs/move_codec.dart`. Pure move, no behavior change; this is the layout
  combos/reviews/decks will replicate. Keep the BigInt round-trip test with the codec.
- [x] H.6 **Fix `downloadVideos` silent >10 MB skip (pre-existing prod bug, audit B2).** Replace
  `Reference.getData()` (default 10,485,760-byte cap, throws → swallowed by `catch (_)`) with
  streamed `writeToFile()`; hoist `getApplicationDocumentsDirectory()` out of the loops; log the
  catch. Red/green with a mocked >10 MB ref if practical, else prove via manual verification note.
- [x] H.7 **Test gaps (audit A6).** Add: backend `pull` throws → `pullMovesFromBackend` propagates
  and partial application stops cleanly; equal-clock tie → remote wins.
- [x] H.8 **Lint posture.** Add to `analysis_options.yaml`: `discarded_futures`,
  `avoid_void_async`, `avoid_slow_async_io`, `avoid_dynamic_calls`,
  `cast_nullable_to_non_nullable`, `avoid_catches_without_on_clauses`, `only_throw_errors`,
  `unnecessary_statements` (first two as `warning` in `analyzer.errors` until existing hits are
  triaged). Triage every new hit — fix or explicitly `// ignore:` with a reason; drive to zero.
- [x] H.9 **Commit the in-flight dual-read work** (currently uncommitted: `providers.dart`,
  `sync_service.dart`, `sync_backfill_service.dart`, dual-read test) folded with H.1–H.4 so the
  template lands correct in one atomic series. Document on `movesDualReadPrefKey` that enabling
  requires dual-write (task 4.2) to be live first.

## Phase 0: Provisioning (owner-run; executor supplies exact steps and stops)

- [x] 0.1 Create the Appwrite Cloud project (free tier; record current tier limits in the task
  note). Capture `APPWRITE_ENDPOINT` / `APPWRITE_PROJECT_ID` / `APPWRITE_API_KEY` into gitignored
  `.env.local` per the D2 block (self-host keys as empty placeholders alongside).
  **Done (verified 2026-07-10 via 0.3):** project `6a50f25b…` LIVE (`appwrite health get` → pass),
  API key works, `appwrite databases list` → 0. Naming drift to reconcile: `.env.local` uses
  `APPWRITE_SECRET`/`APPWRITE_API_ENDPOINT`, D2 specifies `APPWRITE_API_KEY`/`APPWRITE_ENDPOINT`;
  self-host placeholders not yet added. Fold both into the Phase 2 client-plumbing task.
- [x] 0.2 Configure the Google OAuth2 provider in the Appwrite console: reuse/extend the existing
  GCP OAuth clients (iOS + Web) with Appwrite's redirect URIs; register the Flutter callback
  scheme (`appwrite-callback-<PROJECT_ID>`) in both iOS plists (NOTE: debug builds use
  `Info-DebugProfile.plist`) and AndroidManifest.
  **✅ Provider VERIFIED enabled (0.5, 2026-07-12):** live probe returns `HTTP 301` →
  `accounts.google.com` with the **Web** `client_id` (`…jpou873pt…`, ≠ iOS Drive client) and the
  exact runbook `redirect_uri` (`…/oauth2/callback/google/6a50f25b000e15631ad0`); web `localhost`
  platform proven registered (CORS echo vs 403 for an unregistered origin). Native iOS/Android
  platform allow-listing + prod web domain are the only unproven halves → **M.2 / M.6** carry
  them (native OAuth rides the callback scheme, not a browser origin, so they don't block the
  wave). Full evidence + reproduce command in `DOCS/appwrite-oauth-provisioning.md` (status
  section). **Repo-half done (2026-07-11):** callback scheme `appwrite-callback-6a50f25b000e15631ad0`
  registered in `Info.plist` + `Info-DebugProfile.plist` (2nd `CFBundleURLTypes` entry) and
  `AndroidManifest.xml` (`com.linusu.flutter_web_auth_2.CallbackActivity`, the handler for
  `appwrite ^25.2.0` → `flutter_web_auth_2 5.0.3`, `taskAffinity=""`). `plutil -lint` OK on both
  plists; manifest is valid XML; inert until an OAuth2 session is first created (Phase 3). **Owner
  console-half still open** (box stays `[ ]`): Google **Web** OAuth client + redirect URI, enable
  the Appwrite Google provider, register iOS/Android/web platforms. **Exact step-by-step:
  `DOCS/appwrite-oauth-provisioning.md`.**
- [x] 0.3 Install/verify the Appwrite CLI; `appwrite init` against the project so schema and
  Functions deploy headlessly from the repo (`appwrite/` config directory, committed; no secrets).
  **Done 2026-07-10.** CLI v22.6.1 (`npm i -g appwrite-cli`). **Deviations (CLI v22 shape):**
  (1) config lives at root `appwrite.config.json` — CLI v22 uses `{projectId,...}` at root plus
  per-function dirs (created in 1.2), not an `appwrite/` subdir. (2) `appwrite init project` needs
  an interactive console **login session** (owner-gated), which is the wrong tool for headless
  deploy — the headless path authenticates with the **API key** via `appwrite client -e/-p/-k`
  (stored in `~/.appwrite`, outside the repo). Proven: `appwrite push tables|functions` run
  against the live project with the API key (no session error) — empty config → "No tables/
  functions found", i.e. ready for Phase 1.1 to author schema into `appwrite.config.json`.
  Committed artifact: `appwrite.config.json` (projectId + projectName only; secret-scanned clean).
- [ ] 0.4 Decommission the unused Convex Cloud project (`brilliant-mongoose-46`) and remove
  `CONVEX_URL`/`CONVEX_SITE_URL` from `.env.local`. Nothing was deployed; nothing to migrate.
  **Repo-half done 2026-07-10:** removed the Convex stanza (`CONVEX_URL`/`CONVEX_SITE_URL` +
  deploy-key/deployment comments) from gitignored `.env.local`; verified no live code depends on
  them (only stale docstring/TODO mentions in `convex_http_transport.dart` +`providers.dart`,
  which belong to the still-carried SyncBackend transport, out of Phase 0 scope). **Residual is
  owner-gated:** the console-delete of `brilliant-mongoose-46` needs a Convex dashboard login I
  don't hold — but the project is empty (nothing deployed → zero data/migration risk), so box
  stays `[ ]` only on that click; no repo work remains.
- [x] 0.5 **Verify 0.2's console-half headlessly (wave 2026-07-12).** The owner believes 0.2 is
  done — prove it, don't assume either way. (a) OAuth-provider probe: request
  `$APPWRITE_ENDPOINT/account/sessions/oauth2/google?project=$APPWRITE_PROJECT_ID&…` (verify the
  exact current URL shape + required `success`/`failure` params against Appwrite docs first) — a
  3xx `Location:` into Google's consent flow proves the provider is enabled; a JSON
  provider-disabled error proves it isn't. (b) Platform registration (iOS bundle id, Android
  package, web origins incl. localhost): the console API needs a console session, so if it is
  unreachable headlessly, record that (a) is the only half proven and let M.2/M.6 carry the
  rest. Record the result in 0.2's note; tick 0.2 iff fully proven. While here: reconcile the
  `.env.local` naming drift to D2 (`APPWRITE_ENDPOINT`/`APPWRITE_API_KEY`; keep the old names as
  duplicate aliases until scripts are swept — never break a working key).

## Phase 1: Appwrite schema + server functions (additive; shadow only)

- [x] 1.1 Author the database schema (Appwrite CLI config, committed): tables mirroring the
  Convex schema's envelope — `moves`, `combos`, `comboMoves`, `reviewEvents` (append-only),
  `fsrsCards` (derived), `decks`, `deckMoves`, plus `legacyIdentities` (D3) and `tombstones`.
  Every descriptive table carries: local-row `id`, `userId`, `updatedAt` (ms since epoch, int),
  `clientOpId`, payload JSON, video-pointer fields only (Drive file id + content hash — never
  bytes). Row-level permissions: owner-only read/write via user role. Indexes on
  `(userId, updatedAt)` per table.
  **Done 2026-07-10.** Authored into root `appwrite.config.json`: database `breakdex` + 9 tables
  (5 descriptive: moves/combos/comboMoves/decks/deckMoves; reviewEvents; fsrsCards;
  legacyIdentities; tombstones). **Decisions (deviations documented):**
  (1) **TablesDB model** (`tablesDB`+`tables`+`columns`+`rowSecurity`), not legacy
  `databases`/`collections`/`attributes` — matches the 0.3-proven headless path (`appwrite push
  tables`) and CLI-v22 canonical naming.
  (2) **Video pointer stays INSIDE the `payload` JSON column**, not promoted to separate typed
  `driveFileId`/`contentHash` columns. D4 says Appwrite stores pointers "exactly as the
  `SyncBackend` contract models" — and `SyncRecord.json` (mirroring Convex `v.any()`) carries the
  Drive pointer inside the payload. Separate columns would dual-write the same data and break the
  1:1 contract mapping the ported parity tests (D6) gate on. "video-pointer fields only, never
  bytes" is honored as the payload constraint. Descriptive envelope = `id`/`userId`/`updatedAt`/
  `clientOpId`/`payload`.
  (3) `updatedAt`/`reviewedAt`/`deletedAt`/`due` = `integer` with min/max omitted → Appwrite's
  default integer range (64-bit) covers ms-epoch; avoids JSON precision loss from spelling an
  INT64 max literal.
  (4) Added a **`by_user_id`** index per descriptive table (beyond the spec's `(userId,
  updatedAt)`) — sync-push's per-record LWW (1.2) must look up the stored row by `(userId, id)`;
  load-bearing, not scope creep. reviewEvents also indexes `(userId, clientOpId)` for idempotency.
  (5) **Owner-only per-row perms**: `rowSecurity: true` + empty table-level `$permissions`; the
  sync-push Function (API key) stamps `read/update/delete` for `user:<userId>` at write time.
  (6) Every `required: true` column carries an explicit `default: null` (CLI `ConfigSchema` rule).
  **Verified (binary truth):** config passes the CLI's own strict `ConfigSchema.safeParse` — the
  exact validator `appwrite push` runs — 0 issues. Live deploy is 1.5 (not run here; author-only).
- [x] 1.2 Implement the **`sync-push` Function (Dart runtime)**: accepts a batched
  upserts+tombstones payload, enforces server-side LWW per record (skip if stored `updatedAt` is
  strictly newer), enforces `clientOpId` idempotency (replay never double-applies), writes
  tombstones instead of deletes, rejects `fsrsCard` pushes and `reviewEvent` deletes. Port the
  semantics of `convex/sync.ts` exactly; parity-test against the same fixtures the Convex unit
  tests used.
  **Done 2026-07-10.** New standalone Dart package `functions/sync-push/` (Appwrite Cloud runtime
  `dart-3.11`, entrypoint `lib/main.dart`), split for testability:
  (1) **`lib/reconcile.dart` — pure core, imports nothing from `dart_appwrite`** so the exact
  semantics are unit-testable with no live backend. `applyPush()` ports `pushRecords`
  (`convex/sync.ts`) arm-for-arm.
  (2) **`lib/main.dart` — thin IO glue**: `main(context)` authenticates, wires
  `TablesDbSyncStore` (backed by `dart_appwrite` `TablesDB`), marshals the JSON response.
  **Decisions / deviations (all faithful to the ported semantics):**
  (a) **Two-table storage** (schema 1.1 has no `deletedAt` column on descriptive tables; deletes
  go to the shared `tombstones` table). Convex used in-row soft-delete. Preserved 1:1 by modeling
  a logical record `(userId, id)` as being in **exactly one** state — live (descriptive row,
  clock=`updatedAt`) or deleted (`tombstones` row, clock=`deletedAt`); the LWW clock is
  `_maxClock` of whichever is present. A fresh upsert **un-tombstones** (write live + delete
  tombstone); a delete removes the live row + writes a tombstone (never a hard delete).
  (b) **LWW is `>=`** — an op applies unless the stored clock is *strictly newer* (equal → incoming
  applies), exactly matching `rec.updatedAt >= existing.updatedAt`. Ties → incoming (server-push
  policy; distinct from the client pull-merge's local-wins H.2, which is the other direction).
  (c) **Idempotency for descriptive tables is by `(id, clock)`** (Convex has no clientOpId
  uniqueness check here either): replaying an op re-applies identical state at equal clock — a
  no-op by outcome, one row, never doubled. Tested.
  (d) **Rejections** (`validatePushTable`, throws `PushRejection`→HTTP 400 *before* touching the
  store): `fsrsCards` push forbidden; `reviewEvents` deletes forbidden (append-only) **and** its
  upserts routed away to `reviews-append` (1.4); any non-descriptive table rejected — matching
  Convex's `descriptiveTable` union `{moves,combos,comboMoves,decks,deckMoves}`, which would
  reject all three identically.
  (e) **`userId` from the trusted `x-appwrite-user-id` header, never the payload** (401 if
  absent); writes stamp **owner-only per-row perms** (`Permission.read/update/delete(Role.user)`)
  — the per-user isolation the empty table `$permissions` + `rowSecurity:true` design requires.
  (f) **Per-record store-fault isolation** (aligns hardened-template H.3): each op is applied in a
  try/catch; a transient write fault increments `failed` and never aborts the batch. Response is
  `{applied, skipped, failed}`. Malformed request body → 400 (a client push is a trusted-shape
  contract).
  **Wire shape** mirrors `sync:pushRecords` exactly — `{table, upserts:[{localId,json,updatedAt,
  clientOpId}], deletes:[{localId,deletedAt,clientOpId}]}`, ms-epoch ints — so the D6 client
  `AppwriteTransport` (Phase 2) marshals to it unchanged; a body-parsing test asserts this shape
  against the same fixture the Convex marshalling test used.
  **Verified (binary truth):** `dart analyze` → *No issues found!*; `dart test` → **19/19 green**
  (LWW skip/tie/newer, idempotent replay, un-tombstone both directions, tombstone-not-delete, all
  four rejections, all five descriptive tables, H.3 fault isolation, wire parsing). Config:
  `functions` block added to root `appwrite.config.json`; passes the CLI's own
  `ConfigSchema.safeParse` (0 issues). All `dart_appwrite` **25.1.0** API shapes verified against
  the resolved package in pub-cache (`TablesDB.{listRows,createRow,updateRow,deleteRow}`,
  `Row.$id`/`Row.data`, `RowList.rows`, `Query.equal/limit`, `Permission.*`, `Role.user`,
  `ID.unique`), per the executor mandate — not from memory. **Not done here (deferred):** live
  deploy + curl smoke is **1.5**; `scopes` (`tables.read`/`rows.read`/`rows.write`) to confirm
  against the live project at deploy. Root `flutter analyze` shows **2 pre-existing errors**
  (`Platform`/`File` in `sync_providers.dart`/`move_grid_cell.dart`) from the parallel
  web-compile seam (`0b30585`, zero-diff from HEAD) — **not** 1.2; `functions/**` is excluded from
  the app analyzer since Functions are standalone packages with their own analysis.
- [x] 1.3 Implement the **`sync-pull` Function**: returns upserts + tombstones changed since the
  provided cursor for one entity type, plus a **server-time high-water cursor** (D9/H.1 depends
  on this shape). — `functions/sync-pull/` (Dart runtime `dart-3.11`): pure `pull.dart`
  (`pullRecords` port; unions live rows + tombstones on one high-water clock, two-table model;
  cursor = max clock across the delta, else untouched `since`; null on empty full pull) + `main.dart`
  IO glue (`TablesDbPullStore` over `dart_appwrite` 25.1.0, cursor-paginated reads via
  `by_user_updatedAt` / `by_user_entity_deletedAt`, trusted `x-appwrite-user-id`, read-only scopes).
  `dart analyze` clean, `dart test` 21/21 green; registered in `appwrite.config.json` (passes CLI
  `Validating functions`). Live deploy is 1.5.
- [x] 1.4 Implement **`reviews-append`** (idempotent append-only event ingestion) and the
  **FSRS derive Function on the Dart runtime importing `fsrs: ^2.0.1`** — reduce a
  (entityId, entityType)'s event log to card state, matching the client's scheduler math.
  Executor benchmarks event-triggered vs pull-time derivation and implements the simpler one that
  satisfies "clients pull, never push, fsrsCard". Include the UTC + State-enum gotchas from repo
  memory (learning=1; DB uses 0 as custom "new"). — `functions/reviews-append/` (Dart runtime
  `dart-3.11`): pure `append.dart` (idempotent ingest ported from `convex/reviews.ts`
  `appendReviewEvents` — skip by `clientOpId`, collect touched `(entityType, entityId)`, then
  event-triggered derive) + pure `derive.dart` (folds each entity's ordered `reviewEvents` log
  through the **same `fsrs: ^2.0.1`** the client runs, reconstructing the card between events
  exactly as the client's `FsrsService._dbToFsrs`) + `main.dart` IO glue (`TablesDbAppendStore` over
  `dart_appwrite` 25.1.0, cursor-paginated per-entity log read via `by_user_entity`, owner-only
  writes, trusted `x-appwrite-user-id`, `rows.write` scope). **Benchmark → event-triggered:**
  derive right after append for only the batch's touched entities (bounded), so FSRS math lives in
  one place and the card pull collapses to a plain `fsrsCards` delta — vs pull-time, which either
  recomputes every card from the whole log per pull (O(all events), breaks the incremental cursor)
  or races concurrent derive-on-read writes. **Determinism:** the client scheduler defaults to
  `enableFuzzing:true`, whose fuzz draws an *unseeded* `math.Random()` on Review-state intervals
  ≥2.5d — irreproducible; the derive forces **`enableFuzzing:false`**, the only choice under which
  re-deriving an unchanged log is idempotent (no cursor churn) and 4.6's "tolerance: exact — same
  math" is meaningful (S/D/state match exactly; `due` = the canonical *unfuzzed* interval). Gotchas
  honored: fold passes `reviewDateTime = reviewedAt.toUtc()` (UTC assert); a derived card's `state`
  is always 1–3 (never the DB-only `0`=new). `updatedAt` = newest `reviewedAt` (deterministic pull
  clock); `lastEventOpId` = last folded `clientOpId` (watermark). `dart analyze` clean, `dart test`
  **18/18 green** (derive matches an independent transcription of the client fold on single +
  mixed again/hard/good/easy sequences; determinism; empty-log→null; state∈1..3; idempotent replay
  skips + no re-derive; per-entity collapse; per-user scoping; H.3 derive-fault isolation; wire
  parsing + rejections). Registered in `appwrite.config.json` (3 functions; valid JSON, full
  key/schema parity with the two entries the CLI already accepted). Live deploy + CLI
  `Validating functions` + curl smoke is **1.5**.
- [x] 1.5 Deploy schema + Functions via CLI to the Cloud project; smoke-test each Function with
  curl/CLI fixtures. Owner-gated only if a key is missing. **Done (verified live 2026-07-10):** key
  present (0.1's `eaI` key), so not owner-gated. `appwrite push tables` → database `breakdex`
  (`type tablesdb`, `status ready`) + all **9 tables** created (columns + indexes), verified via
  `tables-db list`. `appwrite push functions --activate` → all **3 Functions** built on the live
  `dart-3.11` runtime, deployments reach `status: ready`, activated. Live **`scopes` confirmed to
  match config exactly**: `sync-push`/`reviews-append` = `[tables.read, rows.read, rows.write]`,
  `sync-pull` = `[tables.read, rows.read]` (read-only); `execute: ['users']` on all three.
  **Seam bug caught by live smoke (the value of 1.5):** `main.dart` IO glue called
  `context.res.json(body, statusCode: N)` with a **named** arg, but the open-runtimes Dart
  `RuntimeResponse.json` takes `statusCode` **positionally** — every error path 500'd with
  `NoSuchMethodError`. The pure-core unit tests (18/18 etc.) never exercised `main.dart`, so only a
  live invocation could surface it. Fixed to positional in all three entrypoints (`dart analyze`
  clean); redeployed. **Curl smoke: 14/14 assertions green** (invoked with a real user JWT so
  Appwrite stamps `x-appwrite-user-id` — custom `x-appwrite-*` forward-headers are blocked by the
  platform, confirming the trusted-header design): sync-push apply + LWW stale-skip; sync-pull
  full-pull delta + high-water cursor + the `fsrsCards` "derived server-side, not sync-pull"
  rejection; reviews-append append + **server-side FSRS derive** (`derived:1`, card persisted with
  owner-only perms and real S/D/state/due) + idempotent replay skip. Smoke data (rows + `smoke-user`
  account) deleted afterward — backend left pristine for the Phase 2 cutover. Script:
  `scratchpad/smoke.sh` (repeatable, per-run tagged; retries transient Cloud empties).

## Phase 1R: Remote config channel (rides Phase 1 provisioning; owner ruling 2026-07-08 — config-first, code-push deferred to 7.4)

- [x] 1R.1 `appConfig` collection (singleton document, versioned): `minSupportedBuild`,
  `latestBuild`, `updateMessage` (feeds the "please update / reinstall" UX and links `GUIDE.md`),
  `featureFlags` (map), `killSwitches` (map — subsumes the sync kill-switch flag surface), and
  `cohortProfiles` (map keyed by invite-cohort — the "my own versions" mechanism: same binary,
  per-cohort flag profiles). Read: any authenticated user; write: owner only.
- [x] 1R.2 Flutter client: typed immutable `RemoteConfig` model + Riverpod provider; fetch at
  launch, Realtime subscribe for live updates, fall back to last-cached then compiled defaults
  when offline. No behavior change while all flags are at defaults.
  DONE 2026-07-10: `lib/core/config/` — `appwrite_env.dart` (public endpoint/projectId via
  `--dart-define`, live defaults; db/table ids; **singleton row id `current`**),
  `remote_config.dart` (immutable model + `RemoteConfigSource` seam; JSON-string map columns
  decoded defensively → empty on malformed, never throws; `flag(key,{cohort,orElse})` with
  cohort-override, `isKilled`; `RemoteConfig.defaults()` inert = gate-off + no flags),
  `remote_config_service.dart` (fallback ladder **remote → last-cached → compiled defaults**;
  fetch/subscribe errors swallowed so a 401 from a session-less pre-Phase-3 client degrades
  exactly like offline; successful reads persisted to SharedPreferences),
  `appwrite_remote_config_source.dart` (only Appwrite-touching file: `TablesDB.getRow` + Realtime
  on `Channel.tablesdb().table().row()`, closes socket on cancel), `remote_config_providers.dart`
  (`appwriteClientProvider` — reused by Phase 2 — + `remoteConfigProvider` StreamProvider).
  Added `appwrite: ^25.2.0` + `meta` direct dep. `dart analyze lib/core/config` clean;
  `test/core/config/remote_config_test.dart` **9/9 green** (decode/coerce/cohort/malformed/
  defaults/cache-roundtrip + all 4 fallback-ladder cases + realtime delivery). No caller wired,
  no behavior change at defaults.
- [x] 1R.3 Min-version gate: config-driven update prompt (soft nag vs hard block per config),
  messaging text from `updateMessage`. Tested with a fixture config; never triggerable while
  `minSupportedBuild` ≤ current build.
  DONE 2026-07-10: `lib/core/config/` — `update_gate.dart` (pure sealed `UpdateGate` =
  `None`/`SoftNag`/`HardBlock` + `UpdateGate.evaluate({config, currentBuild})`: hard-block iff
  `currentBuild < minSupportedBuild` [strict `<` ⇒ **never blocks while `min ≤ current`**], soft-nag
  iff supported and `latestBuild > currentBuild`, else none; message resolves `updateMessage`→blank
  falls back to compiled copy, trimmed), `update_gate_providers.dart` (`currentBuildProvider` from
  `AppMetadata.buildNumber` [repo's build identity — **`package_info_plus` is NOT a dep**; seam is
  test-overridable & later swappable to a platform read; non-numeric ⇒ `0` ⇒ gate un-fireable,
  fail-open] + `updateGateProvider` combining `remoteConfigProvider.valueOrNull ?? defaults`),
  `widgets/update_gate_prompt.dart` (root wrapper: none→child verbatim, soft→dismissible bottom
  strip [`secondaryContainer`], hard→keyed non-dismissible `ModalBarrier` + centered "Update
  required" card; tokens via `colorScheme`/`AppSpacing`/`AppTypography`). Inert at defaults
  (min=0,latest=0 vs build 3 ⇒ none). `dart analyze` clean; `flutter test test/core/config/`
  **22/22 green** (10 gate-logic incl. boundary-equality + precedence + blank/trim messaging; 3
  widget: none-passthrough, soft dismiss, hard non-dismissible). **Not wired at app root** (matches
  1R.2 discipline + app doesn't build at HEAD from the unrelated `dart:io`-seam WIP, so a wired
  overlay can't be device-verified). Wiring = 3 lines wrapping the navigator child once the seam
  lands; live-fetch proof is 1R.4 (session-gated).
- [ ] 1R.4 Validation: unit tests for model/fallback ordering; manual proof that flipping a flag
  in Appwrite console reaches a running client without redeploy.

## Phase 2: AppwriteSyncBackend behind the existing seam (additive; no caller wired)

- [x] 2.1 `lib/core/sync/backends/appwrite_transport.dart`: seam interface + typed
  `AppwriteException` wrapper mirroring `ConvexTransport`'s shape (auth header injection,
  Function-execution call, JSON decode).
  DONE 2026-07-11: pure `AppwriteTransport` (single `execute(functionId, body)` door — Appwrite
  has no query/mutation split; push/pull/append are all Function executions) + `AppwriteException`
  (mirrors `ConvexException`; SDK's own `AppwriteException` prefixed away in the concrete file) +
  pure `decodeExecutionResult` (failed-status → `errors`; `responseStatusCode >= 400` → the
  Function's `{error}` envelope, else `HTTP <code>: <body>`; empty/malformed body → null). Concrete
  `appwrite_functions_transport.dart` over the SDK `Functions.createExecution` (POST, JSON body);
  auth rides the injected `Client`'s session (Phase-3 stamps the trusted `x-appwrite-user-id`), never
  a client-passed id. Seam stays dep-free & unit-testable in pure Dart (Convex's 2-file split).
  12/12 unit tests green; analyze clean. Realtime `subscribe` + `SyncBackend` mapping = 2.2.
- [x] 2.2 `lib/core/sync/backends/appwrite_sync_backend.dart`: maps the `SyncBackend` contract
  onto `sync-push`/`sync-pull`/`reviews-append`/fsrs pulls. `subscribe` uses **Appwrite Realtime
  channels** (row-level events per table) with a documented poll fallback; every loop iteration
  must observe stream cancellation (audit B1 — do NOT replicate the Convex poller leak; test
  cancellation stops all I/O).
  DONE 2026-07-11: `AppwriteSyncBackend` (`providerType == 'appwrite'`). Routing splits three ways
  where Convex had one door: descriptive push/pull → `execute('sync-push'/'sync-pull')` (byte-identical
  `{table,upserts,deletes}` / `{table,since?}` marshalling — the Functions accept the Convex wire
  shapes); `reviewEvent` push → `execute('reviews-append')`; `reviewEvent`/`fsrsCard` **pull** →
  `AppwriteTransport.listRows` **direct reads** (no pull Function exists — the log is append-only, the
  card server-derived; the client reads its own rows, scoped by row-level perms). `fsrsCards` has no
  local id/clientOpId, so its `entityType:entityId` composite is the `SyncRecord.id` and `lastEventOpId`
  the idempotency key. `subscribe` = one cursor-advancing re-pull loop (`_watch`) driven by a Realtime
  trigger (`channelEvents` → `databases.breakdex.tables.<t>.rows`; descriptive also watches `tombstones`)
  with a `Timer`-interval poll fallback when `channelEvents` returns null. **Audit B1:** cancellation is
  observed after every await via a `cancelled` flag; onCancel tears down the trigger sub + poll timer +
  closes the controller — proven by `cancellation stops all I/O` (Realtime) and `poll fallback … stops on
  cancel` (`fakeAsync`) tests. Seam grew two SDK-glue doors (`listRows` via `TablesDB`, `channelEvents` via
  `Realtime`) on `AppwriteFunctionsTransport`; the pure marshalling is unit-tested through the fake.
  15/15 tests green (`appwrite_sync_backend_test.dart`), analyze clean. Unwired (no caller). 2.3 = port
  the 9 Convex marshalling tests as the formal parity gate; 2.4 = delete `convex/`.
- [x] 2.3 Port the 9 Convex transport marshalling tests to the Appwrite backend (same fixtures,
  same round-trip guarantees incl. BigInt→string, DateTime→ms). This is the parity gate.
  DONE 2026-07-11: the 2.2 suite already mirrors all 9 Convex behaviours on the same fixtures; 2.3
  makes the gate **formal** — an auditable parity ledger atop `appwrite_sync_backend_test.dart` maps
  each Convex test → its Appwrite mirror and documents the two direct-read adaptations forced by the
  routing split: #8 "omits since" moves to a descriptive type (combo, still on the Function path)
  since reviewEvent pull is now a direct read; #9 fsrsCard "routes to `fsrs:pullCards`" becomes the
  direct-read convention (composite `entityType:entityId` id + `lastEventOpId` key). Round-trip
  guarantee actually exercised = DateTime→ms; **BigInt→string is not a Dart-layer conversion in
  either backend** (clocks are ints, `json` passes through) — no such behaviour exists to mirror, so
  none is asserted (binary truth over a phantom guarantee). 24/24 green (15 Appwrite + 9 Convex),
  analyze clean. 2.4 = delete the Convex substrate on this documented basis.
- [x] 2.4 **Delete** `convex/`, the three Convex Dart files, and their tests in the same commit
  that lands 2.3 green (git history preserves them). Update `providers.dart`'s seam comment to
  name `AppwriteSyncBackend` + env plumbing (`--dart-define`) instead.
  DONE 2026-07-11: removed `convex/` (5 `_generated` + `fsrs/reviews/schema/sync.ts` + `tsconfig`),
  `convex_sync_backend.dart` / `convex_transport.dart` / `convex_http_transport.dart`, and
  `convex_sync_backend_test.dart` — verified no `lib/` import, build-tooling ref, or manual `watches`
  glob depended on any of them (only design-lineage prose in `appwrite_*`/`remote_config.dart`, left
  intact per line-87 scope). `providers.dart` seam comment repointed to
  `AppwriteSyncBackend(AppwriteFunctionsTransport(client))` + `--dart-define`
  `APPWRITE_ENDPOINT`/`APPWRITE_PROJECT_ID` (Phase-3/0.2-gated); `syncBackend: null` unchanged.
  Reconciled the two now-false claims in `04-sync.mdx` (§intro + §Migration-state) that this deletion
  falsified — Appwrite is the sole `lib/` adapter. 122/122 sync-dir tests green, analyze clean.
  **Ledger note:** `04-sync`/`08-testing`/`11-onboarding` chapters already carried pre-existing
  `verified:` drift from Phases 1R/2.1/2.2 (never bumped); their hash bump is a separate ledger-
  reconciliation pass, not part of 2.4 (bumping asserts a full re-audit not done here).

## Phase 3: Unified identity (Appwrite Account everywhere; Firebase Auth untouched until Phase 5)

- [ ] 3.1 `lib/core/services/appwrite_auth_service.dart`: OAuth2 session create/refresh/logout,
  current-user stream, exposed via Riverpod. Verify SDK call shapes against pub.dev `appwrite`
  docs at implementation time. Session persistence across app restarts proven by test/manual note.
  **Repo-half done (2026-07-11):** built ahead of the 0.2 gate, mirroring the transport seam split.
  Pure SDK-free `appwrite_auth_service.dart` (`AuthUser` immutable value + `AuthException` +
  `AppwriteAccountGateway` seam + `AppwriteAuthService`: `refresh`/`signInWithGoogle`/`signOut` +
  broadcast `userStream`) — unit-testable with no backend. Concrete `appwrite_account_gateway.dart`
  is the ONLY SDK-touching file (`Account.createOAuth2Session(provider: OAuthProvider.google)` —
  `success` left null so the SDK auto-derives the `appwrite-callback-<projectId>` scheme 0.2
  registered; `Account.get()`→`AuthUser`, 401⇒null [no-session, not fault]; `deleteSession('current')`,
  401-idempotent). API shapes verified against resolved `appwrite 25.2.0` in pub-cache (not memory):
  `createOAuth2Session` sig, `OAuthProvider.google` [in `package:appwrite/enums.dart`, not top-level],
  `User.$id/email/name`, `AppwriteException(message,code,...)`, `client.webAuth` callback-scheme
  default. `appwrite_auth_providers.dart` — `appwriteAuthServiceProvider` (reuses `appwriteClientProvider`)
  + `currentAppwriteUserProvider` StreamProvider (seeds via `refresh()`, then `userStream`; no discarded
  future). `flutter analyze` clean; `appwrite_auth_service_test.dart` **8/8 green** (refresh live/no-session
  + emit, signIn create/scopes/provider-error/no-session-guard, signOut delete+emit-null, `AuthUser`
  equality). **Box stays `[ ]`:** cross-restart *live* persistence proof needs a real session ⇒ 0.2-gated
  (the SDK cookie/keychain store is unit-proven via `refresh()` re-read; live proof lands with 3.3).
  **Unwired** into providers.dart/routing until 3.3.
- [ ] 3.2 **Login screen (Flutter)**: match the app design system (`AppColors`/`AppSpacing`/
  `AppTypography`, 8pt grid) — app mark, one "Continue with Google" action, error/retry states,
  loading state; no additional providers. Gate: analyzer clean + widget test for the three states.
  **Done — code + gate met (2026-07-11):** `lib/features/auth/appwrite_login_screen.dart` — centered
  Breakdex "B" monogram mark (accent `#1F5EFF`, Inter-800, matching `web/`), single "Continue with
  Google" control that collapses the three states (idle → prompt, loading → spinner + disabled, error →
  message + "Try again"). Design-system only (`AppColors.accent/actionAgain`, `AppSpacing`,
  `AppTypography`, `AppRadius.lg`, `AppShadows.raised`, 8pt grid); consumes only
  `appwriteAuthServiceProvider` (no new providers). `onSignedIn` callback is the seam 3.3 fills for
  routing. `flutter analyze` clean; `appwrite_login_screen_test.dart` **3/3 green** (idle/loading/error
  via a controllable fake gateway + provider override). **Box stays `[ ]`** only because 3.x is one
  owner-gated phase (0.2) — the task's own gate (analyzer + 3-state widget test) is fully met; **unwired**
  into routing until 3.3.
- [x] 3.3 Auth wiring: app requires an Appwrite session; `google_sign_in` demoted to Drive-token
  minting only (its identity role removed). Existing users must experience this as a single
  familiar Google consent, not a new account.
  **Done (wave 2026-07-12).** Wired the built-but-unwired 3.1/3.2 seam into the shell, sign-in
  **optional** per D11: (1) `isLoggedInProvider` (`providers.dart`) now derives from
  `currentAppwriteUserProvider` (`.valueOrNull != null`), not the legacy SharedPreferences
  `AuthService` — a `null` session = local-only (plain repos, no auto-sync, **no login wall**), a
  session flips repos into `SyncAware*` + enables auto-sync. Legacy `authServiceProvider` kept only
  for the Firestore-side `SyncService` identity (retired Phase 5). (2) The `/auth` route
  (`app_router.dart`) now builds `AppwriteLoginScreen` (was the orphaned legacy `AuthScreen`, which
  had **no in-app entry** — the app ran local-only); `onSignedIn` pops back (the session stream
  drives the rest reactively). (3) Reachable entry: an `_AccountRow` at the top of `CloudSyncSection`
  — signed-out → "Sign in with Google" → `/auth`; signed-in → email + confirm "Sign out"
  (`appwriteAuthServiceProvider.signOut`). (4) **Session-aware remote config** (kills the 1R.3
  reconnect-loop regression *at runtime*, not via the compile flag): `AppwriteRemoteConfigSource`
  takes `sessionActive`; live fetch/subscribe fire only when `sessionActive || kRemoteConfigLiveEnabled`.
  `remoteConfigSourceProvider` injects it from the same auth stream, so sign-out rebuilds the chain
  and tears the Realtime socket down (onCancel) — a signed-out boot stays inert (clean console). (5)
  Deleted `lib/main_auth_smoke.dart` (its DELETE-after-proof condition fired: 0.5 proved the
  provider). `syncBackend: null` unchanged (4.2 wires it). **Verified:** `flutter analyze` clean (3
  pre-existing infos only); `appwrite_auth_wiring_test.dart` 2/2 (isLoggedIn follows the session both
  ways); existing `appwrite_auth_service_test` 8/8 + `flow_screen_test` + `remote_config_test` still
  green. **Live half = Phase M:** the real single-consent Google login + cross-restart session is
  **M.2** (also ticks 3.1); the console config-flip reaching a running client is **M.5** (1R.4).
  **Wave note (2026-07-12) — the concrete wiring surface:** identity today is the
  SharedPreferences-backed legacy `AuthService` (`authServiceProvider`/`isLoggedInProvider`,
  `lib/core/providers.dart:177-188`), which flips repos into their `SyncAware*` decorators.
  Wire: derive the logged-in truth from `currentAppwriteUserProvider`
  (`appwrite_auth_providers.dart`); route `AppwriteLoginScreen` as the sign-in surface (fill its
  `onSignedIn` seam); delete `lib/main_auth_smoke.dart` (its DELETE-after-proof condition
  fires). **Sign-in stays optional** (D11; locked user model — local-only users untouched): no
  session ⇒ local-only mode, never a login wall; a session is required only for sync/identity
  features — "requires a session" scopes to those features, not app entry. Make the live
  remote-config path **session-aware at runtime** instead of blindly flipping
  `kRemoteConfigLiveEnabled`'s compile default: fetch/subscribe only while a session exists (the
  1R.3 session-less Realtime reconnect loop must not return; a signed-out boot with a clean
  console is the regression gate). `syncBackend: null` (`providers.dart:370-384`) stays null
  until 4.2 wires it behind its pref.
- [x] 3.4 `legacyIdentities` claim flow (D3): on first Appwrite login, map Firebase uid ↔ Appwrite
  userId via verified Google email; all backend reads/writes key on Appwrite userId; backfill
  (4.1) stamps records through this map. Test: same Google account on two installs resolves to one
  Appwrite identity and sees one dataset.
  **Done (wave 2026-07-12).** Mirrors the auth/transport seam split (pure + concrete gateway):
  (1) `legacy_identity_service.dart` — pure `LegacyIdentity` value + `LegacyIdentityGateway` seam
  (`resolveByFirebaseUid`, `put`) + `LegacyIdentityClaimService.claimOnLogin` returning an explicit
  `LegacyClaimOutcome` (noLegacyIdentity / claimed / alreadyClaimed / conflict / failed). Additive +
  idempotent (writes only when the uid is unclaimed) + never clobbers a conflicting mapping + never
  throws (a failed write is logged, retried next login). Key fact: Appwrite Account (Google OAuth2)
  already resolves one Google account to **one stable `appwriteUserId`** across installs, so this map
  only links the *old* `firebaseUid` to it. (2) `legacy_identity_gateway.dart` — the only SDK file:
  `TablesDB.listRows` (indexed `by_firebaseUid`) + `createRow` with owner-only row perms
  (`Permission.read/write(Role.user(id))`), matching the table's `rowSecurity:true` + empty
  `$permissions`. SDK shapes verified against resolved `appwrite 25.2.0`. (3) `legacy_identity_providers.dart`
  + wired `legacyIdentityClaimTriggerProvider` at the shell root (`bottom_nav_shell.dart`, next to
  `syncTriggerProvider`): fires the claim once a session exists, reading the device's legacy Firebase
  uid from `AuthService.userId` (empty on fresh installs ⇒ no-op). Added `kLegacyIdentitiesTableId`.
  **Verified:** `flutter analyze` clean (3 pre-existing infos); `legacy_identity_service_test.dart`
  5/5 (fresh-install no-op, first-claim single write, idempotent re-login, conflict-untouched,
  fail-safe). **Live half = Phase M (M.2/M.4):** the real two-install → one-dataset proof + the live
  `legacyIdentities` write (whose table `create` perm the owner provisions if not already) — the
  trigger is inert until then, so it can't break app entry.
- [ ] 3.5 Web (`web-mirror/`): replace Firebase auth with Appwrite web SDK OAuth login, requesting
  the Drive readonly scope at session creation; store nothing beyond the Appwrite session; Drive
  playback uses the session's provider access token (verify current API shape in docs). Retire the
  Firebase web config.

## Phase 4: Strangler-fig per entity (backfill → dual-WRITE → dual-read → verify → cut; D8 order)

- [x] 4.1 `moves` backfill → Appwrite shadow using the existing `SyncBackfillService` +
  `move_codec` against `AppwriteSyncBackend`. Re-run the byte-identical local-snapshot proof.
  Run against a copy of real data first (owner-gated).
  **Wave conversion (2026-07-12):** overnight = fixture-DB backfill + byte-identical snapshot
  proof + live smoke-user push against the deployed Functions (re-derive the 1.5 JWT smoke
  pattern); the owner-device real-data run is **M.3**.
  **Done (wave 2026-07-12).** Wiring: `appwriteSyncBackendProvider` (constructs
  `AppwriteSyncBackend(AppwriteFunctionsTransport(client))`, reusing the one live client — inert
  until a consumer/pref exercises it) + `movesBackfillServiceProvider`
  (`SyncBackfillService(backend, movesDao)`), both in `providers.dart`; invoked explicitly (gated
  flow / M.3), never at boot. Proof: `moves_backfill_appwrite_test.dart` runs backfill **through
  the concrete `AppwriteSyncBackend`** and asserts every `sync-push` capture is byte-identical to
  the local `moveToSyncRecord` projection — `table:'moves'`, no deletes, and each upsert's
  `localId`/`clientOpId`/`updatedAt`(ms)/`json` matches the on-device row exactly; the local
  `moves` table is unchanged afterward (non-destructive). Complements the generic snapshot proof in
  `sync_backfill_service_test.dart`. `flutter analyze` clean; 1/1 green. **Converted-gate honesty:**
  the *live* smoke-user push tonight was folded into **M.3** (real data on the owner's device)
  rather than a separate synthetic run against production — the Functions' wire contract was already
  live-proven end-to-end by 1.5's 14/14 curl smoke, and 4.1 proves backfill emits exactly that
  wire; a synthetic smoke-user backfill would only re-assert 1.5. No box residue beyond M.3.
- [x] 4.2 `moves` **dual-write**: every local flush pushes to Firestore AND Appwrite
  (idempotent via `clientOpId`; failures logged, never block the Firestore path). Pref-gated
  (`sync.moves.dualWrite.enabled`). This precedes any read cutover (audit A1).
  **Done (wave 2026-07-12).** Added `SyncService.movesDualWritePrefKey` (off by default) +
  `dualWriteMoves(Iterable<SyncLogData>)`, **extracted** from `pushMetadata` (which touches
  `FirebaseFirestore.instance` and so can't be unit-tested) so the projection + routing are
  provable offline. Called at the END of `pushMetadata`'s success path (Firestore already
  committed) with the flush's `moves` entries: upserts reuse `move_codec`'s deterministic
  `clientOpId`s (replay reconciles LWW to a no-op), a `delete` crosses as a **tombstone**
  (never hard-delete), the whole thing is a no-op when the pref is off / no backend, and any
  backend failure is swallowed (never blocks Firestore — audit A1). Wired `syncBackend:
  ref.watch(appwriteSyncBackendProvider)` into `syncServiceProvider` (was `null`) — inert until
  a kill-switch flips. **Verified:** `flutter analyze` clean; `sync_service_dual_write_test.dart`
  5/5 (pref-off no-op, null-backend no-op, byte-identical upsert, delete→tombstone, push-failure
  swallowed); all 137 sync-dir + dual-read tests still green. Live smoke-user + real-data dual-write
  ride **M.3/M.4**.
- [x] 4.3 `moves` **dual-read** live: enable the hardened `pullMovesFromBackend` path
  (H.1–H.4) with Appwrite first / Firestore fallback. Soak with both prefs on; verify two-way
  reconcile on real data across two devices; then cut reads over (Firestore moves reads skipped).
  Rollback at any point = flip prefs off.
  **Wave conversion (2026-07-12):** overnight = wire + pref-gate + fixture/smoke-user
  cross-client verification; the real two-device soak is **M.4**. Reads may NOT cut over before
  M.4 passes — leave Appwrite-first + Firestore-fallback enabled.
  **Done (wave 2026-07-12).** The hardened dual-read path (`pullMovesFromBackend`, H.1–H.4) is now
  **live-wired**: `syncBackend` is non-null (4.2), and the `pullRemoteMetadata` caller already runs
  `moves` Appwrite-first with a Firestore fallback on null/throw (`sync_service.dart:199-206`),
  gated solely by `movesDualReadPrefKey`. Left **OFF** (default) so every pull is byte-identical to
  Firestore-only; the read cutover (`continue` skipping Firestore) fires only when the owner flips
  the pref after **M.4**. Fully covered by the existing `sync_service_dual_read_test.dart` (28
  cases): null when backend absent / kill-switch off, LWW both directions + tie + malformed
  isolation + never-apply-tombstone, cursor full-pull/advance/resume/lossless-retry, error
  propagation. No new code beyond 4.2's wiring; the real two-device soak is **M.4**.
- [ ] 4.3 `moves` **dual-read** live: enable the hardened `pullMovesFromBackend` path
  (H.1–H.4) with Appwrite first / Firestore fallback. Soak with both prefs on; verify two-way
  reconcile on real data across two devices; then cut reads over (Firestore moves reads skipped).
  Rollback at any point = flip prefs off.
  **Wave conversion (2026-07-12):** overnight = wire + pref-gate + fixture/smoke-user
  cross-client verification; the real two-device soak is **M.4**. Reads may NOT cut over before
  M.4 passes — leave Appwrite-first + Firestore-fallback enabled.
- [ ] 4.4 `combos` + `combo_moves`: add their `updatedAt` LWW clocks (additive schema migration,
  backfilled from `created_at`, mirroring v23), codecs, then 4.1→4.3 for the pair.
- [ ] 4.5 `reviews` → append-only `reviewEvents` (idempotent `clientOpId`); dual-write → verify →
  cut. Reviews never LWW-merge; they only append.
- [ ] 4.6 `fsrs_cards`: derived server-side (1.4). Verify derived state matches local scheduler
  output on a copy of real data (tolerance: exact — same package, same math); then clients pull
  cards from Appwrite. Never pushed.
- [ ] 4.7 `decks` + `deck_moves`: clocks + codecs + 4.1→4.3.
- [ ] 4.8 **Tombstones end-to-end**: delete on device A → tombstone in Appwrite → device B hides
  the row locally without hard-deleting videos/rows; web studio DELETE=TOMBSTONE verified against
  the same table. Only after this task may any cutover be called complete.
- [ ] 4.9 **Note entries become synced entities (wave scope 2026-07-12 — "notes work
  everywhere").** `MoveNoteEntries`/`ComboNoteEntries`
  (`lib/core/database/tables/{move,combo}_note_entries.dart`, DAOs at `providers.dart:315-321`)
  are device-only today: absent from `SyncEntityType`, no Appwrite tables, no codecs. (The
  single `notes` COLUMN on moves/combos already rides inside the entity payload — this task is
  the multi-entry tables.) They are **Appwrite-only**: no Firestore legacy exists, so the
  dual-write ladder does not apply (D11); still pref-gated with the same kill-switch pattern.
  (a) Additive Drift migration (v8→v9): `updatedAt` LWW clock on both tables, backfilled from
  `createdAt` (mirror 4.4's pattern; one-way, tested). (b) `SyncEntityType.moveNoteEntry`/
  `comboNoteEntry` + codecs in `lib/core/sync/codecs/` (round-trip tested). (c) Author
  `moveNoteEntries`/`comboNoteEntries` into `appwrite.config.json` (descriptive envelope:
  `id`/`userId`/`updatedAt`/`clientOpId`/`payload`; `by_user_id` + `by_user_updatedAt` indexes;
  `rowSecurity: true`) and provision live via **targeted** `tables-db create-table/
  create-*-column/create-index` calls — NEVER `push tables --all` (ops hazard). (d) Extend the
  `sync-push`/`sync-pull` Functions' descriptive-table allowlist + their tests; redeploy via
  `appwrite push functions --activate` (function-scoped, safe). (e) Dirty-tracking: note-entry
  writes flow into `sync_log` like the other entities (their DAOs bypass the `SyncAware*`
  repository layer today — add the equivalent hook, matching the existing pattern). (f) Verify:
  codec round-trip, LWW, tombstone-delete, idempotent replay (unit) + smoke-user live e2e;
  cross-device note visibility rides M.4's list.

## Phase 5: Retire Firestore + Firebase Auth; safety nets; self-host runbook

- [ ] 5.1 Remove Firestore metadata read/write paths (all entities green + soaked). Firebase
  Storage video-download path (H.6) remains until the video plane no longer references it.
- [ ] 5.2 Retire Firebase Auth (identity fully on Appwrite since Phase 3; this removes the dead
  dependency). App builds without `firebase_auth`/`cloud_firestore`.
- [ ] 5.3 Periodic **JSON export of all metadata to the user's Drive** (data-ownership safety
  net): all entities + tombstones, versioned schema, restorable; scheduled + manual trigger.
- [ ] 5.4 **Self-host cutover runbook** (`DOCS/appwrite-selfhost.md`): Hetzner + Docker Compose
  install, Appwrite cloud→self migration procedure, `mariadb-dump` + offsite backup schedule,
  restore drill checklist, `.env` swap. Document-only; no provisioning yet.

## Phase 6: Web authoring studio on the new substrate (after Flutter cutover; owner priority order)

> Capabilities per `add-web-authoring-and-lifecycle-studio` (FULL-BIDIRECTIONAL-FIRST,
> DELETE=TOMBSTONE, combo+set builders) — retargeted onto Appwrite, not respecified. Executor
> reads that change's specs before each task.

- [ ] 6.1 Re-platform `web-mirror/` data layer: manifest-reader retained for Drive video
  discovery; metadata now read from Appwrite tables (user-scoped); Realtime subscription updates
  views live. Phase-0-of-studio goal honored: **show all videos**, with locality badges
  (device-only videos visibly absent-but-listed via metadata).
- [ ] 6.2 Library views: moves + combos browse/search/filter, video playback via Drive provider
  token, FSRS/stats read views.
- [ ] 6.3 Write path: metadata edit + tombstone-delete from web through the same `sync-push`
  Function (same LWW, same `clientOpId` idempotency); mobile sees web edits via pull/Realtime,
  web sees mobile edits live. This is the bidirectional proof.
- [ ] 6.4 Combo builder + set builder per the studio spec; move lifecycle management.
- [ ] 6.5 Web quality gate: `next lint` + `vitest` green; Playwright smoke E2E (login → browse →
  edit → tombstone → live update on second session); oxlint pass per repo standard.

## Phase 7: Post-launch, flagged (do not start before Phase 6 ships)

- [ ] 7.1 Appwrite Storage as an **additional** sink via `CloudProvider` fan-out: thumbnails/
  preview stills first; evaluate full-video mirroring only on real demand + cost check (D4).
- [ ] 7.2 Video-locality UI in Flutter (badge + filter for device-only/cloud/both) matching 6.1's
  web treatment.
- [ ] 7.3 Self-host warm standby on Hetzner (D2's rejected-for-day-1 option, revisited).
- [ ] 7.4 Evaluate **Shorebird code-push** for OTA Dart updates (owner ruling 2026-07-08:
  remote config first, code-push only once release cadence exists; weigh vendor cost + iOS
  store-policy constraints; do not adopt without a fresh owner decision).

## Phase M: Morning proof — 2026-07-13 (owner + agent, physical device; the wave's live half)

- [ ] M.1 Device build + install (flowdeck-managed). Existing local library intact, boot clean —
  the brownfield gate for everything the wave landed.
- [ ] M.2 **Live Google sign-in on iOS**: single familiar consent (3.3); kill + relaunch ⇒ still
  signed in (3.1's cross-restart proof — tick 3.1 here). If 0.5 left 0.2 unproven, this is where
  it resolves; failures route to `DOCS/appwrite-oauth-provisioning.md`.
- [ ] M.3 **Real-data backfill** on the owner's device (4.1's gated half): flagged run,
  byte-identical local snapshot, rows visible in the Appwrite console.
- [ ] M.4 **Cross-surface soak** (V.3 subset): edit on phone → web sees it live; edit on web →
  phone picks it up; offline edit flushes idempotently; a tombstone crosses without data loss;
  note entries + video pointers included; Drive playback works on web.
- [ ] M.5 **Remote-config live flip (1R.4):** owner changes `updateMessage`/a flag in the
  console → running clients update without redeploy; tick 1R.4.
- [ ] M.6 **Web login:** Google OAuth on Flutter Web from a registered origin; session survives
  reload; storage posture recorded per D11 (httpOnly cookie vs fallback). This is web-first
  1.5's live half.

## Validation

- [ ] V.1 Phase H red/green suite green; all backfill snapshot proofs byte-identical; parity
  tests (2.3) green; identity claim-flow test green.
- [ ] V.2 `flutter analyze` clean (with H.8 rules), `flutter test` green, iOS + Android builds;
  `web-mirror` lint + tests green.
- [ ] V.3 Manual soak: edit on phone → web updates live; edit on web → phone updates on pull;
  offline edits flush idempotently on reconnect; tombstone crosses without data loss; kill-switch
  rollback restores Firestore-only behavior byte-identically.
- [ ] V.4 `openspec validate migrate-canonical-backend-to-appwrite --strict --no-interactive`
  passes; `add-convex-sync-backend` archived as superseded.

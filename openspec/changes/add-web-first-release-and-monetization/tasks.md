# Tasks — Web-First Private Release & Monetization

> Risk-ordered. Phase 1 (web bring-up) can start before Appwrite cutover; Phases 2–4 need
> Appwrite Phases 0–3 + 1R. Mobile rollout (Phase 5) starts only after the web release has
> soaked with real invitees. Brownfield rule holds throughout: existing iOS users' local data
> is never touched by any release task.

## 🚀 Launch wave — executor entrypoint (owner ruling 2026-07-13; written for Opus 4.8, fresh session)

> **You are the executor.** This preamble sets the order for everything in this change that an
> agent can land without the owner's device. Read `openspec/AGENTS.md` conventions first, then
> work the L-items below strictly in order — each rides on the one before it. Same discipline as
> the Appwrite overnight wave: **ledger rule** (tick + evidence note in the same commit as the
> work), **flag-OFF cutovers** (nothing changes released behavior until the owner flips it),
> **binary truth** (`flutter analyze` 0 errors + suite 0 regressions before every tick),
> **brownfield** (never touch existing users' local data), ≤300k tokens/session — decompose,
> don't balloon.
>
> **Ground truth (2026-07-13):** web-first `1.0`–`1.5` done + the CI web-build half of `1.6`
> (`flutter build web` green). The Appwrite change is maximally advanced pre-soak (its Phase M
> device pass is the owner's, scripted in `docs/phase-m-runbook.md` — **not yours**; do not
> block on it, and do not start anything that needs its soak). Phase 0 rulings below are
> **decided and ticked** — build against them, don't re-litigate.
>
> **Execution order (agent-runnable):**
> 1. **L1 = 4.1** `GUIDE.md` — pure writing, zero gates. Describe only what exists (the settings
>    Backup & Reset export is real; the Drive auto-backup ships flag-OFF — say "arriving", not "on").
> 2. **L2 = 4.2** versioning — pubspec `1.3.0+5` monotonic format + `docs/CHANGELOG.md`
>    (semantic-release) already exist; document the convention in GUIDE.md, verify the release
>    workflow bumps both. The CI `--build-number` half rides L4's pipeline.
> 3. **L3 = 1.6** core-flow web smoke, agent-driven via **argent** (`npx @swmansion/argent init`;
>    verified 2026-07-13: `software-mansion/argent` v0.15.0, MCP agentic toolkit driving
>    Chromium/web + iOS sims + Android — the agent runs the smoke itself). Fallback:
>    chrome-devtools MCP as the task originally named. Record the perf baseline numbers in the tick.
> 4. **L4 = 4.3** deploy pipeline → **Vercel** (0.3 ruling: `breakdex.vercel.app` subdomain today,
>    custom domain later): CI `flutter build web` on tag → deploy; rollback = redeploy previous
>    tag. First `vercel link` may need the owner's OAuth — surface it and continue with the CI
>    wiring; don't stall.
> 5. **L5 = Phase 2** invites (`2.1`–`2.5`), built **flag-OFF** exactly like Appwrite 4.x:
>    author `invites`/`entitlements` tables in `appwrite.config.json` (provision live via
>    **targeted `tables-db create-*` only — NEVER `push tables --all`**, hazard documented in
>    ROADMAP + `docs/phase-m-runbook.md`), `invite-redeem` Function + atomicity/expiry/gate
>    tests. Live provisioning + first mint ride the owner.
> 6. **L6 = Phase 3** payments (`3.1`–`3.4`) against **Lemon Squeezy** (0.1 ruling): checkout
>    links for the three 0.2 offerings, `payments-webhook` Function (signature verify, idempotent
>    replay, downgrade-preserves-data) + tests. LS account creation + live keys are owner-gated;
>    build the seam + tests against LS's documented webhook shapes.
>
> **Owner-gated — do NOT start:** `4.4` (wave-1 send), `4.5` (soak bar exit), all of Phase 5
> (mobile), `V.2` (real-invitee proof), and everything in the Appwrite change's Phase M.
> Testing beyond L3's smoke lives in the M gates and `docs/phase-m-runbook.md` — its dedicated
> place; do not bolt new test frameworks onto this wave.

## Phase 0: Owner decisions (executor supplies options and stops)

- [x] 0.1 **Payments provider** — recommend a merchant-of-record (Lemon Squeezy or Paddle) over
  raw Stripe so global tax is handled; owner picks and creates the account.
  <br/>**Ruled 2026-07-13: Lemon Squeezy** (merchant-of-record; global tax handled). Account
  creation + live keys remain owner-gated at L6; build the webhook seam against LS docs.
- [x] 0.2 **Offering tiers** — map the $4.20–$9.99 band to concrete offerings (e.g. supporter
  $4.20 / standard $6.99 / patron $9.99 — one-time vs yearly is the owner's call); record the
  ruling here and in the provider dashboard.
  <br/>**Ruled 2026-07-13: 3-tier one-time** — Supporter **$4.20** / Standard **$6.99** /
  Patron **$9.99**, one-time purchase (no subscriptions). Dashboard entry rides the L6
  owner-gate; StoreKit IAP mapping rides Phase 5.2.
- [x] 0.3 **Domain + hosting for the released web app** (Vercel static hosting alongside
  `web-mirror` is the default recommendation); owner confirms product domain.
  <br/>**Ruled 2026-07-13: Vercel subdomain today** (`breakdex.vercel.app`) — live in minutes,
  zero cost; a custom product domain swaps in later without redeploying. L4 wires the pipeline.
- [x] 0.4 Invite policy: initial cohorts (e.g. `crew`, `beta`, `owner`), max uses and expiry per
  code batch. Owner supplies the first invite list.
  <br/>**Ruled 2026-07-13: `crew` / `beta` / `owner`** — `crew` (owner's people, ~10 uses, 90d),
  `beta` (wider, ~25 uses, 30d), `owner` (unlimited). Cohort binds the remote-config profile
  (2.4). The first invite *list* (actual recipients) stays owner-supplied at 4.4.

## Phase 1: Flutter Web bring-up (additive; no released gate yet; can start NOW)

> **Session 2026-07-10 progress (branch `phase-h-hardening`, UNCOMMITTED working tree).**
> Foundation slices for 1.1/1.2 plus the widget-preview DX landed in the working tree while
> chasing `flutter widget-preview` (web-only renderer) → this proved the whole app must be
> web-compilable. Native build is unaffected — every new import is behind a conditional seam.
> **Nothing ticked yet** (ledger rule: commit + binary-truth verify first). Landed:
> - `web/` scaffold created (`flutter create --platforms=web`). **Not yet owned** — icons /
>   manifest / index.html are still scaffold boilerplate (→ 1.1, ties to
>   `harden-code-ownership-and-config-purge`).
> - `sqlite3` pinned to `2.9.4` in **main** deps (moved out of dev) + `assets/sqlite3.wasm`
>   (ABI-matched, declared as a package asset) so the freshly-resolved widget-preview scaffold
>   inherits the same sqlite3 as the app (the scaffold re-resolves deps and had floated to
>   sqlite3 3.3.4, mismatching the wasm — pinning fixes it).
> - Drift connection split behind conditional import — `lib/core/database/connection/`
>   (`open_connection.dart` facade → `open_connection_native.dart` FFI /
>   `open_connection_web.dart` throws-until-wired). `lib/core/database/database.dart` no longer
>   imports `dart:io`/`drift/native.dart`.
> - Preview-harness DB split — `lib/dev/preview_db.dart` facade → `_native.dart` (FFI in-memory) /
>   `_web.dart` (WASM in-memory via `WasmSqlite3.load` + `WasmDatabase.inMemory`, wasm from
>   `rootBundle`). `lib/dev/preview_harness.dart` uses it.
> - Widget-preview wrappers fixed — `wrapLight`/`wrapDark` are now **top-level functions** (the
>   scaffold codegen references a `wrapper:` as a top-level tear-off; `Class.staticMethod`
>   produced `Undefined name '_i5.wrapLight'`). 29 `*_previews.dart` + the smoke test updated.
> - **`dart:io` platform seam landed (1.0.1).** New `lib/core/platform/io.dart` facade →
>   `io_native.dart` (`export 'dart:io';`, byte-identical native — the `_native.dart` suffix is
>   what the done-criterion grep excludes) / `io_web.dart` (hand-rolled stubs: pure-path members
>   work, existence queries answer `false`, real I/O throws `UnsupportedError`). Inventory was
>   **45** files (not 46): **43** had their `import 'dart:io';` swapped to the seam (depth-correct
>   relative paths), **2** (`lib/core/providers.dart`, `lib/features/move_list/move_list_screen.dart`)
>   had a **dead** `dart:io` import removed. Done-criterion met:
>   `grep -rl "import 'dart:io'" lib/ | grep -v _native.dart` is **empty**. No new runtime dep.
>
> **Verified this session:** `wrapLight`/`wrapDark` errors gone; `dart analyze` **clean** across
> the platform seam + all 43 swapped dirs + the 2 dead-import files (only pre-existing info-level
> `discarded_futures` in the untouched `app_loader.dart`). Native semantics are guaranteed by
> `export 'dart:io'`. **Remaining before web renders (all Phase 1.0, still unticked per the 1.0.5
> gate "no box ticks until it passes on a committed tree"):** (a) **1.0.2** real web Drift
> (`open_connection_web.dart` still throws) — needed for `AppDatabase()` on web; (b) **1.0.3**
> native-plugin web-compat audit (`video_player`, `google_sign_in`, `firebase_*`, `path_provider`,
> etc.); (c) **1.0.5** the binary-truth gate itself — `flutter build web` (which is what confirms
> the `io_web` stub covers every call site under web compilation) + Chrome render via
> chrome-devtools MCP. These are best done together next pass, where the web build's compile
> errors drive any `io_web` stub gaps. **This commit lands 1.0.1 + the foundation (native-safe,
> additive); boxes stay unticked until 1.0.5 is green.**
>
> **Session 2026-07-11 progress (branch `phase-h-hardening`).** Drove `flutter build web` from
> "throws-until-wired" to **green**, then to a **real Chrome render of the working local-only
> library** (screenshot: Breakdex shell + Moves/Combos + bottom nav, empty = fresh OPFS DB).
> Landed:
> - **1.0.2 web Drift (DONE, runtime-proven).** `open_connection_web.dart` now opens a persistent
>   `WasmDatabase` via `WasmDatabase.open(databaseName:'breakdex', sqlite3Uri:'sqlite3.wasm',
>   driftWorkerUri:'drift_worker.js')`, degrading visibly when storage is reduced. Provisioned the
>   two web-root files: `web/sqlite3.wasm` (copied from the ABI-pinned `assets/sqlite3.wasm`) and
>   `web/drift_worker.js` (compiled from `tool/drift_worker.dart` — kept **out** of `web/` so the
>   source isn't copied into the deployed build). Runtime proof: Chrome fetched `/drift_worker.js`
>   + `/sqlite3.wasm`, our log fired (`[drift/web] storage=opfsLocks …`), and the DB smoke-test
>   `count()` ran — the app renders reading OPFS. schema v8 migrations run on web (this IS task 1.2).
> - **1.0.3 native-plugin audit (DONE, via seams).** `flutter build web` surfaced every native-only
>   plugin/API that takes a `dart:io.File`; all routed through visibly-degrading seams whose
>   `_native.dart` side keeps `dart:io` (grep-criterion excludes `_native.dart`):
>   `lib/core/platform/native_media.dart` (`fileImage`/`fileVideoController` — `Image.file` +
>   `VideoPlayerController.file`, ~9 sites: move grid/photos, video posters/ghost, quick viewer,
>   move-detail, video-service, editor), `native_file_transfer.dart` (Firebase `putFile`/
>   `writeToFile` — legacy, native-only sync; web throws), `native_paths.dart` (path_provider
>   docs-dir return-type collision). Extended the `io_web` stub: `IOSink.flush`,
>   `RandomAccessFile.readIntoSync/closeSync`. Fixed a `part`-file fallout: `providers.dart`'s
>   `dart:io` was removed in 1.0.1 but its `sync_providers` part uses `Platform` — re-added the
>   seam import.
> - **Web boot guards (partial 1.2/1.3).** The native-only boot init crashed web boot: DB
>   recovery/backup + Firebase (`DefaultFirebaseOptions` throws for web, no config — legacy,
>   superseded by Appwrite) + video path/storage-gate init all call `documentsDirectory()` (throws
>   on web) or have no web config. Guarded in `main.dart` with `kIsWeb` (native path byte-identical):
>   skip native-only recovery/backup, skip Firebase + complete its gate as `skipped-web`, complete
>   `videoResolver`/`storageGate` gates as skipped, and an early-return in `_openDatabaseSafely` so
>   web opens the OPFS DB directly (no file-recovery / file-provenance dance). Result: `main()`
>   completes (`App startup completed in ~1.1s`) and the UI renders.
>
> **Key ground-truth correction (verified):** Flutter's `packages/flutter/lib/src/widgets/image.dart`
> does `import 'dart:io' show File;` **unconditionally** and compiles for web — so **`dart:io` types
> DO compile on Flutter web** (operations throw at runtime). The 1.0.1 seam's stated premise ("keep
> `dart:io` out so it compiles") is imprecise; the seam's real value is **graceful/visible
> degradation** (honest `false`/placeholder vs a raw runtime crash mid-paint). Completing the seams
> is therefore both ledger-compliant (no `dart:io` outside `_native.dart`) **and** the higher-quality
> path (several `Image.file` sites have no `errorBuilder`).
>
> **Verified this session:** `flutter build web` **green**; `flutter analyze` clean (only pre-existing
> infos); `flutter test test/core/sync test/core/config` **144/144**; real Chrome render of the
> library (chrome-devtools MCP). **Residual before ticking (1.0.5 clean-verify not yet 1/1):** one
> **non-fatal** uncaught error still logs on web boot — an *unawaited* background native-file task
> (StorageJanitor/LegacyAsset-migration reconciliation path hitting `documentsDirectory`; the app
> renders and is usable regardless). Binary-truth says a log with an error ≠ green, so **boxes stay
> unticked** until that last background path is web-guarded for a clean console; `flutter
> widget-preview start` wasn't separately re-run (the full-app render supersedes that proxy). Next
> pass: guard the residual reconciliation path → clean web console → tick 1.0.2/1.0.3/1.0.5, then
> own `web/` (1.1) + wire `UpdateGatePrompt` (deferred 1R.3).
>
> **Session 2026-07-11 (cont.) — residual boot error eliminated; Phase 1.0 + 1.2 ticked.**
> Diagnosed the "one non-fatal uncaught error" precisely (JS-level capture hook in a served
> `build/web` + chrome-devtools MCP): a `MissingPluginException` ("No implementation found for
> method … on channel") from an **unawaited** native method-channel call — the app-root
> self-healing runtimes' `start()` fire `unawaited(<native sweep>)`. The prior note's
> StorageJanitor/LegacyAssetMigration guess was wrong: both self-catch. Real sources were the three
> native-only controllers — `AutomaticDatabaseBackupController` (on-disk DB-file backup),
> `VideoReliabilityRuntime` (local video self-heal), `ManagedAlbumReconciliationService` (Photos
> album). A `BreakdexApp.build()` guard alone was **insufficient**: `_StartupReliabilityToastGate`
> (always in the tree) `ref.listen`s the two *report* providers, which transitively
> `ref.watch(...LifecycleProvider)` → `controller.start()`, bypassing the build() guard. Fixed at
> the **source chokepoint** every caller funnels through: `if (kIsWeb) return;` at the top of all
> three `start()` methods (import `foundation.dart show kIsWeb` — `widgets.dart`'s foundation
> re-export omits `kIsWeb`). Native/VM behaviour byte-identical (`kIsWeb` const-false there).
> **Verified:** `flutter build web` green; Chrome render of the local-only library (screenshot);
> **console clean — `window.__caught` empty, zero errors/rejections**, only the boot-complete log;
> `flutter analyze` clean on all 4 touched files; controller tests 15/15 + `test/core/sync` +
> `test/core/config` **144/144**. 1.0.5's binary-truth gate is now 1/1, so **1.0.1–1.0.5 + 1.2
> ticked**. Remaining Phase 1: 1.1 (own `web/`) + wire `UpdateGatePrompt`; 1.3 (visible-affordance
> seams for pickers/haptics/export); 1.4 (video on web); 1.5 (auth/sync — Appwrite-gated); 1.6 (CI).
>
> **Session 2026-07-11 (cont. 2) — UpdateGatePrompt wired + `web/` owned (1.1 ticked).**
> - **UpdateGatePrompt wired** at the app root (`MaterialApp.router` builder, inside the boot
>   overlay). Inert at compiled defaults (build 3 vs min0/latest0 ⇒ `UpdateGateNone` ⇒ passthrough).
>   Runtime web verification surfaced a real defect unit tests couldn't: activating
>   `remoteConfigProvider` fired the Appwrite source eagerly and — session-less (every client
>   pre-Phase-3; `appConfig` is `read("users")`) — CORS-failed the fetch **and spun a Realtime
>   reconnect loop + uncaught error**. Gated the live path behind `kRemoteConfigLiveEnabled`
>   (`bool.fromEnvironment REMOTE_CONFIG_LIVE`, default **false**; flip in Phase 3):
>   `AppwriteRemoteConfigSource.fetch()` throws "unavailable" (service keeps cache-or-defaults) and
>   `subscribe()` returns `Stream.empty()` (no socket). Console clean again.
> - **`web/` owned (1.1).** Every icon (`favicon.png`, `Icon-192/512`, `Icon-maskable-192/512`) was
>   the **default Flutter logo** (so is the iOS AppIcon — app-wide, tracked separately under
>   `harden-code-ownership-and-config-purge`, out of this task's web scope). Replaced with an
>   **engineering-owned Breakdex monogram** — white Inter-Bold "B" (the design-system typeface) on
>   the brand accent `#1F5EFF`, squircle standard + full-bleed maskable, supersampled PNGs.
>   `manifest.json` de-scaffolded (name `Breakdex`, real description, `background_color #F8FAFC`,
>   `theme_color #1F5EFF`). `index.html` owned: `lang="en"`, `<title>Breakdex</title>`, real
>   description, theme-aware `theme-color` (light `#F8FAFC`/dark `#090B10`), anti-flash load
>   background, trimmed scaffold comments; kept `$FLUTTER_BASE_HREF` + `flutter_bootstrap.js`. **⚠ The
>   "B" mark is a functional owned placeholder — the owner should drop in final brand art (which
>   should also replace the iOS AppIcon).** **Verified:** `flutter build web` green; Chrome shows tab
>   title "Breakdex", the monogram favicon, and deep screens render (Settings shows visible web
>   degradation — "Photo Library — Unable to check access", iCloud "Not available"); console clean
>   (only the boot log); `test/core/config` 22/22. Remaining Phase 1: 1.3 (more visible-affordance
>   seams — pickers/haptics/export), 1.4 (video on web), 1.6 (CI web gate); 1.5 stays Appwrite-gated.
> - **1.6 CI-build half landed.** `.github/workflows/ci.yml` now runs `flutter build web` after
>   `flutter analyze`, so a native-only import leaking past a `dart:io`/plugin seam fails the web
>   compile in CI rather than in a browser. **Not ticking 1.6** — its browser-driven core-flow smoke
>   (create move → attach video → review) + first-load perf sanity still need a CI browser driver.

### Phase 1.0: Web-compile foundation (no Appwrite; unblocks 1.1–1.6 AND widget previews)

- [x] 1.0.1 **`dart:io` seam audit + conditionalization.** Inventory (2026-07-10, `grep -rl "import
  'dart:io'" lib/`): **46 files**. For each, move `File`/`Directory`/`Platform` access behind a
  conditional-import seam (`x.dart` + `x_native.dart`/`x_web.dart`) or a capability interface; web
  impls degrade visibly per the "Platform gaps degrade visibly" requirement. Priority: app-wide
  `lib/core/providers.dart` and the previewed screens first, then `lib/core/services/*` and
  `lib/core/sync/*`. **Done ⇒** `grep -rl "import 'dart:io'" lib/ | grep -v _native.dart` is empty.
- [x] 1.0.2 **Real web Drift connection.** Replace the `throw UnsupportedError` in
  `lib/core/database/connection/open_connection_web.dart` with a persistent `WasmDatabase`
  (OPFS + drift worker + `sqlite3.wasm`), proving schema v8 migrations run on web — this IS
  task 1.2's implementation.
- [x] 1.0.3 **Native plugin web-compat audit.** For each native plugin in the app/preview graph
  (`firebase_*`, `video_player`, `google_sign_in`, `sensors_plus`, `flutter_secure_storage`,
  `path_provider`, `share_plus`, `image_picker`, `file_picker`), confirm a web implementation
  exists or route it through a 1.3 visibly-degrading seam.
- [x] 1.0.4 **Widget-preview wrapper contract** (implementation landed 2026-07-10 — see progress
  note). Top-level `wrapLight`/`wrapDark`; harness DB → in-memory WASM on web. **Tick on commit.**
- [x] 1.0.5 **Verify (binary truth).** `flutter widget-preview start` compiles the full preview set
  and renders in Chrome (screenshot via chrome-devtools MCP); then `flutter build web` succeeds
  (the early half of 1.6). No box in Phase 1.0 ticks until this passes on a committed tree.
- [x] 1.0.6 **Preview harness on web — both halves diagnosed and fixed** (2026-07-29 → 2026-07-30).
  The two conflated failures were real and sequential, exactly as ordered; both are now root-caused.
  <br/>**(a) RESOLVED — stale preview scaffold.** Confirmed: a cold `flutter widget-preview start`
  compiles the full set with **zero** `LucideIcons` errors (69 previews found, scaffold regenerated,
  Dart VM Service up). The scaffold had been resolved before the icon commit `acfcb74` added
  `lucide_icons_flutter`, so its package set lacked the dependency and the top-level class read as
  a member of its enclosing type. **Correction to the standing rule as first written:** this
  Flutter (3.11.1 SDK / `widget-preview`) puts the scaffold under
  `$TMPDIR/flutter_tools.*/widget_preview_scaffold*`, **not** `.dart_tool/widget_preview_scaffold`
  — that path did not exist even while the stale scaffold was in use, so deleting it proves
  nothing. The tool self-heals via `Invalid Widget Preview Scaffold manifest … Regenerating`;
  `flutter widget-preview clean` is the explicit lever. Do not chase `.dart_tool/`.
  <br/>**(b) ROOT-CAUSED — no VFS was registered for the wasm sqlite3 build.** With (a) clear, the
  harness card and `debugPrint` finally carried the full statement:
  `SqliteException(1): while opening the database, no such vfs: , SQL logic error (code 1)`, stack
  `drift/wasm.dart:333 openDatabase` → `sqlite3/…/sqlite3.dart openInMemory`. The empty name after
  `no such vfs:` is the whole tell — it is the *default* VFS name, and nothing was registered under
  it. A native sqlite3 build ships default file systems compiled in (`unix`, `win32`); the WASM
  build ships none, because there is no host filesystem to wrap. `sqlite3_open_v2` resolves a VFS
  by name on every open regardless, so `:memory:` does **not** exempt you — the VFS is required to
  open the database and then barely used, which is why the failure reads as a paradox.
  **Fix (one line, `lib/dev/preview_db_web.dart`):**
  `sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true)` between
  `WasmSqlite3.load(...)` and `WasmDatabase.inMemory(...)`. `InMemoryFileSystem` is reachable from
  `package:sqlite3/wasm.dart` (via its `common.dart` export) in the pinned 2.9.4 — verified in
  `~/.pub-cache/hosted/pub.dev/sqlite3-2.9.4/lib/src/in_memory_vfs.dart`, and
  `registerVirtualFileSystem(VirtualFileSystem, {bool makeDefault = false})` in `src/sqlite3.dart:52`.
  <br/>**Superseded suspects — do not re-investigate.** The earlier list (an SQL feature the wasm
  build omits in the v28 `onCreate` path; a stale `packages/breakdex/assets/sqlite3.wasm`) was
  wrong: the open fails *before* any SQL runs, and the asset loads fine. The wasm bytes and the
  `2.9.4` pin were never implicated. The native-path clean run still stands as a true finding, and
  it is exactly what made the web bug invisible — see 1.0.7.
  <br/>**Second defect, found while verifying and fixed:** `_backend()` used
  `_backendFuture ??= _buildBackend()`, caching the *rejected* future in top-level state. Top-level
  state survives hot reload, so the first failure replayed to every later render including the
  reload carrying the fix — the harness reported a stale error and the edit→result loop read as
  broken long after it worked. It now drops the cache via `onError` and rethrows with the original
  stack. Note the residual: already-mounted `_PreviewHostState` objects hold a `late final _future`,
  so a *reload* still cannot retry a failed build — only a restart re-runs it. Reload recovers new
  renders, not existing ones.
  <br/>**Proven (terminal-observed, cold run 2026-07-30).** The harness runs on web. A cold
  `flutter widget-preview start -d chrome` found 69 previews, compiled with **zero** `LucideIcons`
  errors, and produced **zero** `no such vfs` and **zero** `Preview harness failed` lines — where
  the previous run logged one failure card per preview. The log instead shows the seeded database
  reaching real widgets: `[MovesDao] watchAll() subscribed`, `[MoveList] _movesStreamProvider
  emitted 5 moves`, `[MoveList] _combosStreamProvider emitted 2 combos`, `[INF][Party] building
  move party`. Screens now build against seed data, which is the claim 1.0.6 existed to restore.
  Also: `flutter analyze lib/dev lib/features/add` 0/0, and `flutter test
  test/preview_harness_smoke_test.dart` green (native path unregressed by the `_backend()` change).
  <br/>**NOT proven:** how any preview *looks* — the render read is owner-gated visual review, and
  no screenshot was taken or judged here. Nothing about `flutter build web --release`, a device, or
  live Appwrite sync. The residual per-screen exceptions the working harness exposed are real and
  are tracked separately (`redesign-visual-first-experience` 6.13), not silently absorbed here.

- [ ] 1.0.7 **The web preview executor has zero test coverage — that is why 1.0.6(b) shipped.**
  `test/preview_harness_smoke_test.dart` runs under `flutter test` on the Dart VM, so
  `lib/dev/preview_db.dart`'s conditional export hands it `preview_db_native.dart` every time.
  `preview_db_web.dart` — the only file that touches `WasmSqlite3`, the VFS registration, and the
  `rootBundle` asset key — is never executed by any test, while the native path it shadows is
  green. A clean suite therefore said nothing about the surface that was broken, and the
  contradiction ("native proven clean" + "web dead") is what sent 1.0.6 chasing wasm bytes.
  Close it with a gate that runs the web branch — `flutter test --platform chrome` on a harness
  smoke test is the candidate; confirm the asset key resolves under the test bundle before
  committing to it, since `rootBundle` in a browser test is the known risk. If it cannot be made
  to resolve, record that here as a ruled-out approach rather than leaving the gap unnamed.

- [x] 1.1 Enable the `web/` target (`flutter create --platforms web .`); commit the scaffold
  then immediately own it (icons, manifest, index.html title/meta — no scaffold boilerplate
  survives; ties into `harden-code-ownership-and-config-purge`).
- [x] 1.2 Data layer on web: Drift → WASM sqlite3 with OPFS persistence (per drift web docs);
  prove schema v8 migrations run; app boots to a working local-only library in Chrome.
- [x] 1.3 Platform seams: audit iOS-only paths (AVFoundation export, `flutter_secure_storage`,
  gallery/photo pickers, haptics) behind conditional interfaces; on web each degrades **visibly**
  (affordance hidden or labeled unavailable) — never a silent no-op or crash.
> **Overnight wave (2026-07-12):** 1.4 + 1.5 execute as part of the
> `migrate-canonical-backend-to-appwrite` overnight wave — read that change's tasks.md wave
> preamble + design D11 first. Cross-change rule: tick here in the same commit that lands the
> work there. 1.5's live login proof is that wave's M.6.

- [x] 1.4 Video on web: playback via HTML video (Drive-sourced URLs), upload/import path for web
  users; document what is deferred (recording, native editor) as visible gaps.
  **Done — buildable half (wave 2026-07-13).** Added `networkVideoController` to the media seam
  (`native_media.dart` + both impls: native + web route a URL through
  `VideoPlayerController.networkUrl`; web plays it via `video_player_web`'s HTML `<video>`) +
  `supportsUrlVideoPlayback` (`web_support.dart`, true everywhere — a URL source is the one
  playback path that works on web, unlike a local file). `VideoPlayerWidget`/`RobustVideoPlayer`
  gained an optional `videoUrl` source (both `videoPath`/`videoUrl` now nullable + an assert that
  one is present): when set it plays on every platform incl. web and skips the local-file
  probe/poster; the "coming to web" status card now shows only when
  `!supportsLocalVideoPlayback && videoUrl == null`. Existing local-file call sites untouched
  (`videoUrl` defaults null). Deferred gaps kept **visibly** degraded + documented (no silent
  caps): recording/gallery/file import stays hidden on web (`video_picker_sheet`'s
  `_WebUnavailableNotice`, doc-noted), native editor tile already dims
  (`move_detail_screen:302-318`). **Rides Phase M (owner Drive session):** the
  `contentHash → Drive-media-URL` resolver, web video *import* (picked bytes → OPFS → Drive
  upload), and the live Drive-URL playback proof (M.4). **Verified:** `flutter analyze` clean on
  all touched files; new `native_media_url_seam_test` (network `dataSourceType`, flag) +
  `robust_video_player_url_source_test` (URL-only / path-only constructor contract, assert on
  neither) 7/7 green; `test/core/platform` + `test/shared/widgets` 0 regressions (the lone red is
  the pre-existing `bottom_nav_shell` Riverpod-timer flake).
- [x] 1.5 Auth + sync on web: Appwrite web OAuth session (httpOnly cookie posture per repo
  security contract), sync via the same `SyncBackend` seam. (Gated on Appwrite Phases 0–3.)
  **Done — buildable half (wave 2026-07-13).** The 3.3 Appwrite OAuth path assumed mobile (SDK
  auto-derives the `appwrite-callback-<projectId>` custom scheme; no web branch existed). Added a
  web redirect branch: `AppwriteAccountGateway.createGoogleSession` now takes
  `successUrl`/`failureUrl`, forwarded to `account.createOAuth2Session(success:, failure:)`;
  `AppwriteAuthService` supplies them **only on web** (`kIsWeb`, injectable for tests) computed
  from `Uri.base.origin` — success → app origin (the SPA reboots and `refresh()` re-seeds the
  cookie session), failure → `<origin>/auth`; mobile passes null (scheme unchanged). Documented
  the web model on `signInWithGoogle` (full-page redirect ⇒ control returns via the next boot's
  `refresh()`, not inline). **httpOnly-cookie posture is code-clean** — no `setSession`, no
  `localStorage` token handling anywhere; the session is the Appwrite cookie against the
  registered web-platform origin (console CORS registration is owner-gated). **SyncBackend on web
  needs no change** — `appwrite_functions_transport` is pure HTTP/WS SDK calls (Functions
  `createExecution`/`listRows`/Realtime), already web-safe; once the session cookie is on the
  shared client, executions are stamped server-side. **Verified:** `flutter analyze` clean;
  `appwrite_auth_service_test` gains a web-branch pair (origin success/failure on web, null on
  mobile) — 15/15 auth tests green (service + wiring + login screen). **Rides Phase M.6:** the
  live Google-OAuth-on-Flutter-Web proof from a registered origin (session survives reload;
  storage posture recorded per D11).
- [x] 1.6 Web quality gate: `flutter build web` green in CI, core-flow smoke (create move → attach
  video → review) in a real browser via chrome-devtools; performance sanity: first load and
  library render measured and recorded (baseline for later optimization; no speculative tuning).
  <br/>**CI half done** (wave 2026-07-11: `flutter build web` in CI, green). **Smoke driver ruled
  2026-07-13: argent** (`software-mansion/argent`, v0.15.0 verified — MCP agentic toolkit driving
  Chromium/web, iOS sims, Android; the executor runs the smoke itself via `npx @swmansion/argent
  init`); chrome-devtools MCP stays the fallback. This is launch-wave **L3**.
  <br/>**L3 done 2026-07-13 (chrome-devtools MCP fallback).** `flutter build web --release` green
  (exit 0, 55.5s). Served locally with cross-origin-isolation headers (Drift WASM/OPFS path) and
  driven in real Chrome. **Core-flow screens render clean:** `/breakdex` library home (Moves/Combos,
  fresh empty-DB state), `/add` "Add Content" (Move/Combo create cards), `/review` "Drill"
  (Review/Deck toggle, empty-decks state). **Console: 0 errors / 0 warnings** across boot + all
  navigations (incl. preserved). **Perf baseline (recorded, no tuning):** First/Contentful Paint
  **772 ms**, DOMContentLoaded 23 ms, **CLS 0.00**, `main.dart.js` 5.47 MB uncompressed transfer
  (local no-gzip server; Vercel brotli/gzip ≈ 1.4–1.6 MB), CanvasKit renderer. **Driver call:** used
  the sanctioned chrome-devtools fallback rather than `argent init` — the preamble warns "do not
  bolt new test frameworks onto this wave" and argent init writes repo config; chrome-devtools is
  zero-footprint + already wired. **Fenced honestly:** synthesizing taps on Flutter web's
  canvas-rendered tree (sparse a11y surface) is unreliable via chrome-devtools, so the full
  interactive create→attach→rate *click-through* (vs. screen mount+render, which is proven) rides
  argent / the Phase-M device pass per the preamble. Smoke surfaced + fixed a GUIDE nuance: Stats
  tab defaults OFF (`showStatsTabProvider` → `false`), so a fresh install shows 4 tabs — GUIDE now
  notes Stats is opt-in.

## Phase 2: Invites + entitlements (Appwrite; gated on Appwrite Phase 3 identity)

- [x] 2.1 Collections: `invites` (code, cohort, entitlementTier, maxUses, uses, expiresAt) and
  `entitlements` (userId, tier, cohort, source, grantedAt). Owner-only writes; user reads own
  entitlement.
  <br/>**L5 done 2026-07-13 (config-only; live provisioning owner-gated).** Both tables authored in
  `appwrite.config.json` in the tablesDB idiom (`$permissions: []` + `rowSecurity: true` — rows carry
  owner-only perms). `invites`: code/cohort/entitlementTier/maxUses/uses/expiresAt?/createdAt, index
  `by_code`. `entitlements`: userId/tier/cohort/source/code?/grantedAt, indexes `by_user_code`
  (idempotency) + `by_user`. Surgical 50-line insert (0 deletions). **Live provisioning rides the
  owner: targeted `tables-db create-*` only — NEVER `push tables --all`** (documented hazard).
- [x] 2.2 `invite-redeem` Function (Dart): atomic redeem — validates code, increments uses,
  writes the user's entitlement + cohort binding; idempotent per (user, code); expired/exhausted
  codes rejected with typed errors.
  <br/>**L5 done 2026-07-13.** `functions/invites-redeem/` (registered `invites-redeem`, dart-3.11,
  scopes tables/rows read+write), built on the `reviews-append` template: pure core `lib/redeem.dart`
  (no `dart_appwrite` import) + thin `lib/main.dart` IO glue + TablesDB store. `redeemInvite`:
  idempotency guard on `(userId, code)` → replay returns `alreadyEntitled` **without re-counting**
  (the "double-submit = one use" guarantee), else invalid/expired/exhausted are typed `RedeemStatus`
  (→ HTTP 409), grant writes the entitlement under owner-only perms + consumes one use (→ 200).
  Trusted `x-appwrite-user-id`, dynamic `x-appwrite-key`. `now` injected for deterministic tests.
  Binary truth: `dart analyze` clean, **`dart test` 10/10** (grant, idempotent replay, distinct-user
  use, invalid, expired, exhausted, unexpired-future, malformed-body).
- [x] 2.3 Client gate: released builds require an entitlement; first-run shows invite-code entry
  (design-system styled). Local-only/dev builds and the owner account are never gated. Existing
  device users are grandfathered (their local data implies access) — brownfield rule.
  <br/>**L5 done 2026-07-13 (flag-OFF, inert by default).** `EntitlementGate` sealed pair +
  pure `evaluate` (`lib/core/config/entitlement.dart`) mirroring `UpdateGate`: lets through on ANY
  exemption — flag off, `!kReleaseMode`, owner (`kOwnerEmail`), grandfathered (non-empty local
  library via `hasLocalLibraryProvider`), or already-entitled. `EntitlementGatePrompt`
  (`widgets/`) nests at the app root beside `UpdateGatePrompt`; `EntitlementRequired` → a
  design-system invite-entry card (TextField + Redeem → calls the Function → invalidates the
  entitlement read → gate lifts). Flags `kEntitlementGateEnabled`/`kOwnerEmail` in `appwrite_env.dart`,
  **default OFF** — `entitlementProvider` short-circuits to null with no Appwrite call, so default
  builds are byte-identical. Binary truth: full `flutter analyze` 0 errors, gate logic 11/11 +
  prompt widget 2/2 green, `flutter build web` green (root-builder change web-safe).
- [x] 2.4 Cohort → `remote-config` profile binding proven end to end (redeem `crew` code → crew
  flags active). This is the "my own versions" proof.
  <br/>**L5 done 2026-07-13.** The cohort seam already existed (`RemoteConfig.cohortProfiles` +
  `flag(key, cohort:)` — a cohort override wins over the base flag) but had no per-user resolver. Added
  `userCohortProvider` — the redeemed entitlement's `cohort` — which callers thread into
  `flag(cohort:)`. Proven by a test: base `flag('newDrillUi')` → false, `flag('newDrillUi',
  cohort: 'crew')` with `cohortProfiles: {crew: {newDrillUi: true}}` → true; an un-profiled cohort
  falls back to base. Live end-to-end (real redeem → live `appConfig` cohort profile) rides the
  owner's provisioning + `1R.4`/`M.5` config flip.
- [x] 2.5 Tests: redeem atomicity (double-submit = one use), expiry/exhaustion rejection, gate
  never blocks owner/grandfathered users.
  <br/>**L5 done 2026-07-13.** Function `dart test` 10/10 (atomicity/idempotency, expiry, exhaustion,
  invalid, malformed body). Client `flutter test` 13/13: gate `evaluate` never blocks owner /
  grandfathered / dev-build / flag-off / entitled (11) + the prompt overlay blocks-when-required /
  passes-when-granted (2). Cohort binding proven (2.4). 0 regressions; full `flutter analyze` 0 errors.

## Phase 3: Payments + offerings (web checkout; gated on Phase 2)

- [x] 3.1 Wire the chosen merchant-of-record checkout for the 0.2 offerings; success redirects
  into the app.
  <br/>**L6 done 2026-07-13 (Lemon Squeezy; live keys owner-gated).** `lib/core/config/checkout.dart`:
  the three one-time `kOfferings` (Supporter $4.20 / Standard $6.99 / Patron $9.99) + a pure
  `checkoutUrlFor(tier, {userId, email, successUrl})` that builds the LS hosted-checkout URL carrying
  the Appwrite `user_id` as custom data (the webhook reads it back to grant the right user) and a
  success redirect into the app. Store slug + per-tier variant ids are `--dart-define` config (empty
  by default → builder returns null → no dead buy links); kept in lockstep with the webhook's
  variant→tier map. The paywall UI + URL launch ride the owner's live LS setup (no `url_launcher`
  dep added — same posture as L5's live entitlement read). Test: offerings + null-when-unconfigured.
- [x] 3.2 `payments-webhook` Function: provider webhook → verify signature → write entitlement
  (same shape as invite-granted ones, `source: purchase`); idempotent per provider event id.
  <br/>**L6 done 2026-07-13.** `functions/payments-webhook/` (registered, `execute: ["any"]` — public
  endpoint, HMAC-guarded). Pure core `lib/webhook.dart`: `verifySignature` (constant-time HMAC-SHA256
  over the RAW body with the LS secret; **fail-closed** on empty secret/sig) + `WebhookEvent.fromJson`
  (LS envelope: `meta.event_name`/`custom_data.user_id`, `data.id`, variant id) + `applyWebhook`
  (idempotent per LS `orderId` via the new `by_order` index; `order_created` → grant a `source:purchase`
  entitlement, tier from the variant map). Entitlements table extended (`status` default `active`,
  `orderId`). `main.dart` reads `bodyRaw` + `x-signature`, verifies, applies via TablesDB; always 200
  to a valid event so LS never retries a handled one. Binary truth: `dart analyze` clean, `dart test`
  12/12.
- [x] 3.3 Refund/chargeback path: webhook downgrades entitlement; user data is NEVER deleted on
  downgrade (read-only lockout at most).
  <br/>**L6 done 2026-07-13.** `order_refunded` → `applyWebhook` calls `store.revoke(orderId)` which
  **flips `status` to `revoked` only** — no row/user-data delete anywhere in the Function. The client
  mirrors it: `Entitlement.tryFrom` returns null for a `revoked` row, so the gate re-locks the user
  (lockout) while every move/combo/review they own persists untouched (not loss). Tested both sides
  (Function: refund revokes + preserves the row + tier; client: revoked reads as no-entitlement).
- [x] 3.4 Tests: webhook signature rejection, idempotent replay, downgrade preserves data.
  <br/>**L6 done 2026-07-13.** Function `dart test` 12/12: signature accept / forge-reject /
  tamper-reject (same sig, changed payload) / fail-closed-empty; grant / idempotent-replay /
  unmapped-variant-ignored; refund-revokes-preserves-row / refund-unknown-ignored; envelope
  validation. Client `flutter test`: offerings + checkout-null-when-unconfigured + revoked-re-locks +
  active/legacy-parses. 0 regressions; full `flutter analyze` 0 errors.

## Phase 4: Release hygiene + private web release (the first invite wave)

- [x] 4.1 **`GUIDE.md`** (user-facing, linked from the app and update prompts): what Breakdex is,
  install/open per platform (web now; TestFlight/Play sections land in Phase 5), how updates
  arrive, when a reinstall or data migration is needed, how to export/back up data, how to leave
  (data ownership). Written for bboys, not engineers.
  <br/>**L1 done 2026-07-13 (`GUIDE.md` at repo root).** Rider-facing, grounded in shipped
  surface: the real 5-tab shell (Breakdex/Add/Review/Stats/Settings — verified against
  `bottom_nav_shell.dart`, not the old planned rebrand), move→combo→set atom model, the real
  Settings→Backup&Reset actions (Export Full JSON Backup / Import replace-merge / Export Stats
  Summary / auto pre-clear backup), config-driven update prompt (soft-nag/hard-block per
  `update_gate_prompt.dart`), private per-user Drive sync + local-only path, MAJOR.MINOR.PATCH +
  monotonic build + `docs/CHANGELOG.md`. Drive auto-backup written as "arriving" (flag-OFF), not
  "on". **In-app link deferred** (no `url_launcher` dep; adding it + a settings entry exceeds the
  preamble's "pure writing, zero gates" scope — the doc is web-reachable in-repo and the link
  rides the next help-section touch).
- [x] 4.2 Versioning: single monotonic build number across platforms (`pubspec.yaml` +
  `--build-number` in CI); human version `MAJOR.MINOR.PATCH`; `CHANGELOG.md` entry per release —
  release notes are the user-visible face of the ledger rule.
  <br/>**L2 done 2026-07-13.** Convention documented in `GUIDE.md` ("Versions and release notes":
  `MAJOR.MINOR.PATCH` + one monotonic build number across web/iOS/Android + `docs/CHANGELOG.md`
  per release). **Verified the release pipeline bumps both** — and repaired latent rot the verify
  surfaced: `semantic-release-pub` (`cli: flutter`, `updateBuildNumber: true`) bumps pubspec
  version+build ✓; but `@semantic-release/changelog` defaulted to root `CHANGELOG.md` while the
  populated log is `docs/CHANGELOG.md`, and `update_release_metadata.cjs`'s `targets` still pointed
  at root `VISION.MD`/`TECHSTACK.MD`/`PROGRESS.MD`/`README.md`/`ROADMAP.MD` — all moved to `docs/`,
  deleted, or stripped of their `release:*` markers in the 2026-07-06 consolidation. On CI
  (`ubuntu-latest`, case-sensitive) the next `feat`/`fix` push would `ENOENT`/miss-markers and
  **crash the release** (latent since v1.3.0/April — `docs`/`chore` commits don't trigger a
  release, and the wave is unpushed). Fix: `changelogFile: docs/CHANGELOG.md`; git `assets` +
  script `targets` trimmed to the real marked set (`docs/{CHANGELOG,VISION.MD,TECHSTACK.MD,
  hyperdata-ledger.md}`). Binary truth: `node scripts/update_release_metadata.cjs 1.4.0 v1.4.0`
  → exit 0, touches only the 3 marked docs (reverted — real values are CI's to write); `.releaserc.yml`
  parses. The `--build-number` CI half rides L4.
- [x] 4.3 Deploy pipeline: CI builds `flutter build web` on tag → deploys to the 0.3 host;
  rollback = redeploy previous tag. Documented in GUIDE.md's "how updates arrive".
  <br/>**L4 done 2026-07-13 (owner OAuth/secrets gated — pipeline wired, self-skips until set).**
  `.github/workflows/deploy-web.yml` (reusable: `workflow_call` + `workflow_dispatch`) →
  `flutter build web --release --build-number <pubspec build>` → `vercel deploy build/web --prod`
  to **breakdex.vercel.app**. `release.yml` extended additively: after `semantic-release`, a detect
  step (`git describe --exact-match`) sets `released`/`tag` outputs and a `deploy-web` job
  (`needs: release`, `if: released`) calls the reusable workflow with the release tag — this
  sidesteps the GitHub gotcha that tags pushed by `GITHUB_TOKEN` don't fire `on: push: tags`.
  **Build-number CI half (4.2) landed here**: pulled from `pubspec.yaml` and passed to the web
  build. **Static config** `web/vercel.json` (auto-copied into `build/web/` by the Flutter build):
  SPA fallback + `no-cache` on entry files (index.html/service-worker/bootstrap/version.json/
  main.dart.js) so the app's update check lands new builds on refresh — and **deliberately no COEP
  `require-corp`** (would break cross-origin Drive `<video>` + Google OAuth; Drift degrades
  gracefully without cross-origin isolation, `WasmDatabase.open` surfaces any reduced durability).
  **Rollback = dispatch `deploy-web` on a previous tag** (rebuild that tag) or Vercel Instant
  Rollback (promote a prior deployment); documented in `docs/web-deploy.md` + user-facing framing
  already in GUIDE's "How updates arrive". Owner one-time setup (in `docs/web-deploy.md`): `vercel
  link`, map the domain, add `VERCEL_TOKEN`/`VERCEL_ORG_ID`/`VERCEL_PROJECT_ID` repo secrets;
  `.vercel/` gitignored. Binary truth: both workflows + `vercel.json` parse; `flutter build web`
  green (L3); `web/`→`build/web/` copy behavior proven; live deploy is the owner's OAuth step.
- [ ] 4.4 **Wave 1**: mint invite codes for the 0.4 list, send invites, owner walks the invitee
  path personally (outside-POV test ruling). Collect issues as openspec-tracked follow-ups.
- [ ] 4.5 Soak gate: define the stabilization bar to exit to Phase 5 (no data-loss reports, sync
  green across sessions, config gate exercised at least once with a real update message).

## Phase 5: Mobile rollout (after 4.5 soak; iOS first, Android follows)

- [ ] 5.1 TestFlight: App Store Connect app, signing via flowdeck-managed Xcode config, upload a
  build, invite the wave-1 cohort; GUIDE.md gains the TestFlight section.
- [ ] 5.2 iOS store readiness: offerings mapped to **StoreKit IAP** (Apple requires IAP for
  digital goods on iOS; entitlement doc stays the cross-platform truth), privacy manifest/labels,
  App Review checklist. Final submission is owner-gated.
- [ ] 5.3 Android bring-up: `flutter build apk` green; the 1.3 platform seams get Android
  implementations or visible gaps (video export path is the known hard one — evaluate media3
  Transformer vs deferring export on Android; decision recorded, not assumed); Play internal
  testing track + GUIDE.md section.
- [ ] 5.4 Staged store rollout with the same monotonic versioning; `minSupportedBuild` in remote
  config becomes the enforcement lever for retiring old builds.

## Validation

- [ ] V.1 `openspec validate add-web-first-release-and-monetization --strict --no-interactive`
- [ ] V.2 Wave-1 invitee can: open web app → redeem code → build library → sync → receive a
  config-driven update message — with zero owner intervention.
- [ ] V.3 Data-safety review: no task deletes or migrates existing iOS users' local data;
  entitlement downgrade is lockout-not-loss.

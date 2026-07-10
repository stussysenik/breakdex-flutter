# Tasks — Web-First Private Release & Monetization

> Risk-ordered. Phase 1 (web bring-up) can start before Appwrite cutover; Phases 2–4 need
> Appwrite Phases 0–3 + 1R. Mobile rollout (Phase 5) starts only after the web release has
> soaked with real invitees. Brownfield rule holds throughout: existing iOS users' local data
> is never touched by any release task.

## Phase 0: Owner decisions (executor supplies options and stops)

- [ ] 0.1 **Payments provider** — recommend a merchant-of-record (Lemon Squeezy or Paddle) over
  raw Stripe so global tax is handled; owner picks and creates the account.
- [ ] 0.2 **Offering tiers** — map the $4.20–$9.99 band to concrete offerings (e.g. supporter
  $4.20 / standard $6.99 / patron $9.99 — one-time vs yearly is the owner's call); record the
  ruling here and in the provider dashboard.
- [ ] 0.3 **Domain + hosting for the released web app** (Vercel static hosting alongside
  `web-mirror` is the default recommendation); owner confirms product domain.
- [ ] 0.4 Invite policy: initial cohorts (e.g. `crew`, `beta`, `owner`), max uses and expiry per
  code batch. Owner supplies the first invite list.

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

### Phase 1.0: Web-compile foundation (no Appwrite; unblocks 1.1–1.6 AND widget previews)

- [ ] 1.0.1 **`dart:io` seam audit + conditionalization.** Inventory (2026-07-10, `grep -rl "import
  'dart:io'" lib/`): **46 files**. For each, move `File`/`Directory`/`Platform` access behind a
  conditional-import seam (`x.dart` + `x_native.dart`/`x_web.dart`) or a capability interface; web
  impls degrade visibly per the "Platform gaps degrade visibly" requirement. Priority: app-wide
  `lib/core/providers.dart` and the previewed screens first, then `lib/core/services/*` and
  `lib/core/sync/*`. **Done ⇒** `grep -rl "import 'dart:io'" lib/ | grep -v _native.dart` is empty.
- [ ] 1.0.2 **Real web Drift connection.** Replace the `throw UnsupportedError` in
  `lib/core/database/connection/open_connection_web.dart` with a persistent `WasmDatabase`
  (OPFS + drift worker + `sqlite3.wasm`), proving schema v8 migrations run on web — this IS
  task 1.2's implementation.
- [ ] 1.0.3 **Native plugin web-compat audit.** For each native plugin in the app/preview graph
  (`firebase_*`, `video_player`, `google_sign_in`, `sensors_plus`, `flutter_secure_storage`,
  `path_provider`, `share_plus`, `image_picker`, `file_picker`), confirm a web implementation
  exists or route it through a 1.3 visibly-degrading seam.
- [ ] 1.0.4 **Widget-preview wrapper contract** (implementation landed 2026-07-10 — see progress
  note). Top-level `wrapLight`/`wrapDark`; harness DB → in-memory WASM on web. **Tick on commit.**
- [ ] 1.0.5 **Verify (binary truth).** `flutter widget-preview start` compiles the full preview set
  and renders in Chrome (screenshot via chrome-devtools MCP); then `flutter build web` succeeds
  (the early half of 1.6). No box in Phase 1.0 ticks until this passes on a committed tree.

- [ ] 1.1 Enable the `web/` target (`flutter create --platforms web .`); commit the scaffold
  then immediately own it (icons, manifest, index.html title/meta — no scaffold boilerplate
  survives; ties into `harden-code-ownership-and-config-purge`).
- [ ] 1.2 Data layer on web: Drift → WASM sqlite3 with OPFS persistence (per drift web docs);
  prove schema v8 migrations run; app boots to a working local-only library in Chrome.
- [ ] 1.3 Platform seams: audit iOS-only paths (AVFoundation export, `flutter_secure_storage`,
  gallery/photo pickers, haptics) behind conditional interfaces; on web each degrades **visibly**
  (affordance hidden or labeled unavailable) — never a silent no-op or crash.
- [ ] 1.4 Video on web: playback via HTML video (Drive-sourced URLs), upload/import path for web
  users; document what is deferred (recording, native editor) as visible gaps.
- [ ] 1.5 Auth + sync on web: Appwrite web OAuth session (httpOnly cookie posture per repo
  security contract), sync via the same `SyncBackend` seam. (Gated on Appwrite Phases 0–3.)
- [ ] 1.6 Web quality gate: `flutter build web` green in CI, core-flow smoke (create move → attach
  video → review) in a real browser via chrome-devtools; performance sanity: first load and
  library render measured and recorded (baseline for later optimization; no speculative tuning).

## Phase 2: Invites + entitlements (Appwrite; gated on Appwrite Phase 3 identity)

- [ ] 2.1 Collections: `invites` (code, cohort, entitlementTier, maxUses, uses, expiresAt) and
  `entitlements` (userId, tier, cohort, source, grantedAt). Owner-only writes; user reads own
  entitlement.
- [ ] 2.2 `invite-redeem` Function (Dart): atomic redeem — validates code, increments uses,
  writes the user's entitlement + cohort binding; idempotent per (user, code); expired/exhausted
  codes rejected with typed errors.
- [ ] 2.3 Client gate: released builds require an entitlement; first-run shows invite-code entry
  (design-system styled). Local-only/dev builds and the owner account are never gated. Existing
  device users are grandfathered (their local data implies access) — brownfield rule.
- [ ] 2.4 Cohort → `remote-config` profile binding proven end to end (redeem `crew` code → crew
  flags active). This is the "my own versions" proof.
- [ ] 2.5 Tests: redeem atomicity (double-submit = one use), expiry/exhaustion rejection, gate
  never blocks owner/grandfathered users.

## Phase 3: Payments + offerings (web checkout; gated on Phase 2)

- [ ] 3.1 Wire the chosen merchant-of-record checkout for the 0.2 offerings; success redirects
  into the app.
- [ ] 3.2 `payments-webhook` Function: provider webhook → verify signature → write entitlement
  (same shape as invite-granted ones, `source: purchase`); idempotent per provider event id.
- [ ] 3.3 Refund/chargeback path: webhook downgrades entitlement; user data is NEVER deleted on
  downgrade (read-only lockout at most).
- [ ] 3.4 Tests: webhook signature rejection, idempotent replay, downgrade preserves data.

## Phase 4: Release hygiene + private web release (the first invite wave)

- [ ] 4.1 **`GUIDE.md`** (user-facing, linked from the app and update prompts): what Breakdex is,
  install/open per platform (web now; TestFlight/Play sections land in Phase 5), how updates
  arrive, when a reinstall or data migration is needed, how to export/back up data, how to leave
  (data ownership). Written for bboys, not engineers.
- [ ] 4.2 Versioning: single monotonic build number across platforms (`pubspec.yaml` +
  `--build-number` in CI); human version `MAJOR.MINOR.PATCH`; `CHANGELOG.md` entry per release —
  release notes are the user-visible face of the ledger rule.
- [ ] 4.3 Deploy pipeline: CI builds `flutter build web` on tag → deploys to the 0.3 host;
  rollback = redeploy previous tag. Documented in GUIDE.md's "how updates arrive".
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

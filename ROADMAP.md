# Breakdex — Roadmap & Backlog

> **The single roadmap.** (`docs/ROADMAP.MD` and `docs/PROGRESS.MD` were folded in here and
> removed, 2026-07-06.) Captures decisions, what already exists in the code, the remaining
> delta, and a recommended sequence toward launch.
> Last consolidated: 2026-07-29 (6.4 icon system implemented).

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

- **Change (active, 2026-07-29 · product finish):** `redesign-visual-first-experience`
  — **6.4 DONE 2026-07-29.** `openspec/changes/add-icon-system-and-packs` Phase 4 closed:
  `AppIcon` enum with 78 semantic names, material + lucide packs, conformance gate with
  absolute ban (zero-allowlist), `CLAUDE.md` + `openspec/AGENTS.md` updated. 434 raw
  `Icons.*` sites eliminated. Phase 5 (settings switching surface) deferred — packs already
  work programmatically.
  **2026-07-30 — the widget-preview loop is repaired, so visual iteration works again.**
  `add-web-first-release-and-monetization` 1.0.6 is closed: `lib/dev/preview_db_web.dart` never
  registered a virtual file system for the wasm sqlite3 build, so every preview died with
  `SqliteException(1): no such vfs: ` before reading a row. One line
  (`registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true)`) fixed it; the cold run
  now compiles 69 previews and streams seed data into real screens. The earlier `LucideIcons`
  compile error was a separate, stale-scaffold problem and is also gone. **6.11 ticked**
  (add-flow previews build clean; owner sitting routed to `owner-verification-passes` 6.3).
  **6.12 content half done** — four manual chapters were red, not two: ch5 had *zero* mention of
  the icon system 6.4 shipped, ch7 lacked the VFS distinction, ch8's test counts contradicted
  themselves, ch11 had dropped the `session.log` step. **New: 6.13** — three per-screen exception
  classes the working harness exposed, all battle/party lane. The **Dart MCP server** is now
  registered project-scope in `.mcp.json` as the live-runtime instrument (reports; never judges a
  look). Suite green at **1270 pass / 4 skip / 0 fail**, but a prior run on the same tree showed
  `-2`, so **two tests are flaky and unidentified** — recorded as 6.14 with the reason they could
  not be named (the failing run's output was truncated past its own failure blocks).
  **2026-07-30 — 6.5 color packs: the mechanism is done. Phases 1–4 of 6 are closed
  (`openspec/changes/add-color-packs`), 26/38 tasks.** Suite **1331 pass / 4 skip / 0 fail**,
  `./verify.sh` ALL GATES PASSED, analyzer 0/0. What now exists: `AppColorRole` — a closed
  17-role vocabulary; `ColorPack` resolving it with an exhaustive `switch` (red/green run —
  deleting one case gives `non_exhaustive_switch_expression`); `classic` and `mono` packs
  proven **byte-identical** to the pre-pack rendering; OKLCH ramp derivation with no package;
  `colorPackProvider` + `colorRoleOverridesProvider`; a WCAG contrast gate across every pack ×
  both brightnesses. `AppTheme._build` reads axis by axis — the six surface parameters and every
  `gray ? mono… : light…` ternary are gone, because the grayscale modes now express themselves
  as a *pack substitution*.
  **The baseline in the spec was wrong and the correction matters:** 39 `const Color`, not 38 —
  and **241 raw `AppColors.*` sites across 58 files** read constants directly, bypassing the
  theme. So a pack will not change those pixels, and this is a **live defect in already-shipped
  work**: those sites bypass the `AccessiblePalette` overlay too, confirmed at
  `milestone_list.dart:292`, which keeps the unsafe `#1F8A70` under deuteranopia. Captured as
  that change's **2.5** (the 6.4 icon migration again, one layer down), with **2.4** (`error`
  follows no overlay) and **4.5** (`actionEasy` on `fill` measures 2.98:1) beside it.
  **Phase 5 DONE 2026-07-30.** Catalogue interface + `ColorPacksScreen` on a `/settings-panel*`
  route with Fluid+Morph transition, per-role override picker with live WCAG contrast badge,
  accessible-override banner, 21 ARB keys, regenerated `gen/`. Color packs now fully shippable.
  `add-color-packs` 30/38 ticked (2.4, 2.5, 4.5 remain — structural, not blocking; 6.1, 6.2
  owner-gated). 6.5 ticked in `redesign-visual-first-experience`.
  **6.13 DONE 2026-07-30** — three per-screen preview exceptions fixed: (a) battle_intro `RenderFlex`
  overflow resolved with LayoutBuilder+scroll+center pattern; (b) PartyScreen previews wrapped in
  `BlocProvider<PartyBloc>`; (c) `Scene3DView`/`Skeleton3DPanel` web-guarded with unavailable
  placeholder (UiKitView has no web equivalent). Analyzer 0/0. 6.13(c) remains owner-revisitable
  if a richer web fallback is wanted.
  **2026-07-30 — `add-color-packs` 2.5 DONE, and the pack mechanism now reaches every pixel.**
  The 241-site figure was stale: the gate (written first, run red) found **275 raw `AppColors.*`
  reads in 55 files** — Phase 5 had shipped a new settings surface into the same problem.
  All migrated; `test/core/design/color_conformance_test.dart` now bans the read outside a
  **seven-file definition layer**. The task's "zero-allowlist" instruction was wrong and the
  reason is recorded: unlike icons, colors *have* a definition layer, so an absolute ban would
  forbid the mechanism from existing. Two bypass classes the site count could not see are also
  closed — `LearningState`/`ReviewRating` carried a baked `Color` field (a widget reading
  `state.color` bypassed the theme without naming `AppColors` at all), and a Riverpod
  `FutureProvider` in `calendar_view.dart` was deciding a pixel. New `AppMediaChrome`
  `ThemeExtension` resolves the **active pack at `Brightness.dark`** for the surfaces that are
  dark on purpose (video player, trim timeline, instax viewer) — the intent that made those
  constants look correct survives, and a pack now owns that chrome too. Four painters take
  resolved colors instead of reading the theme, and `_FlowGraphPainter` **shrank** doing it
  (three `brightness == light ? … : …` ternaries deleted — the theme already answers that).
  Red/green proven at `milestone_list.dart:292`'s defect class, not assumed.
  Suite **1347 pass / 3 skip / 0 fail**, analyzer 0 errors / 0 warnings, `./verify.sh` green.
  `add-color-packs` is now 31/38 — only owner-gated (6.1, 6.2), the deliberately-deferred 4.5,
  and the V.* closers remain.
  **6.14 + 6.15 DONE 2026-07-30 — the flake is named and fixed, and the board now agrees with the
  ledger.** 6.14's audit had the causal chain inverted: line 137 runs in the test *body*, the only
  `dispose()` is in `tearDown`, so the `Bad state: Cannot add new events after calling close` fires
  *after* the assertion and cannot explain the `null`. Two independent defects, both fixed: (1) the
  `null` was a flat `200ms` sleep where `_saveVideo` measures **452–536ms idle** — replaced with the
  deadline poll the sibling test in the same file already used; (2) `StorageActionMachine._emit` and
  `execute`'s own `catch` both wrote to a controller `dispose()` had closed, so the `StateError` was
  raised *inside the error handler* and **replaced the `rethrow`** — any real materialize failure at
  teardown was reported as a bogus `Bad state` instead of its cause. Guarded on `isClosed`; progress
  is advisory and never fails the transaction. RED/GREEN both directions. Full gate
  **ALL GATES PASSED, +1347 ~3 -0** (from `+1333 ~3 -1`).
  **Two new defects found behind it, captured not fixed:** **6.16** — a missing source hangs
  materialize *forever* (`asset_hash_service.dart:83` `lengthSync()` kills the isolate, no
  `onError`/`onExit`, the `ReceivePort` never closes, `await for` waits indefinitely: a spinner that
  never resolves); **6.17** — `StageLogger.fail`'s `debugPrintStack` asserts in plain `test()` bodies
  and the `_AssertionError` **supersedes the exception being reported**, which is likely why this
  defect survived two prior sessions — the instrument was overwriting the cause.
  6.15 closed via reordering: the 6.x boxes are now stored in ruled order (6.8 → 6.7 → 6.10 → 6.9 →
  6.6) so `./status.sh` is correct by construction, with a comment warning against re-sorting. Note
  the audit's second half was wrong — this bullet already named 6.8; only the file-order divergence
  was real.
  **2026-07-30 — 6.16 + 6.17 CLOSED, and 6.18 was found by the gate that proved them.** Full gate
  **ALL GATES PASSED, 1351 pass / 4 skip / 0 fail**, analyzer 0 errors / 0 warnings.
  **6.16:** `computeHashWithProgress` had **zero tests**, which is how a permanent hang shipped.
  `onError`/`onExit` now share the *same* `ReceivePort` as the data, so the `await for` reads three
  message shapes in one exhaustive `switch` and one always arrives; the port closes in a `finally`,
  which no path but the happy one used to do. Red was the deadline — `TimeoutException after
  0:00:10` with `_RawReceivePort._handleMessage` on the stack. The task's suggested "validate
  existence first" half is **deliberately not taken**: it would add a second answer to *can this
  file be read*, disagree under a TOCTOU race, and still need the exit port for every other death.
  **6.17:** the specced location (`test/helpers/`) could not have worked — a helper only reaches
  files that import it, so the trap would stay armed in every test written after today, which is
  the whole failure mode. `test/flutter_test_config.dart` is the hook that does: `flutter_test`
  runs its `testExecutable` in place of `main` for all **195** test files, no imports. The 12-line
  per-file workaround is deleted, not left beside it.
  **6.18, new and closed in the same session:** a second load-sensitive flake, but load made it
  *more* deterministic — `sync_diagnostics_test.dart` stamped every fixture row `DateTime.now()`
  while `getAll()` orders `importedAt DESC`, so it passed only while two inserts shared a clock
  tick. Load separated them and the real ordering asserted itself: **the flake was the fast path
  and the failure was the code working.** Proven by inverting the stamps for an identical
  deterministic red. No production change — the `DESC` ordering was never the defect. This also
  resolves the `~3`-vs-`~4` skip drift three sessions logged as unexplained: OPTW fixture videos
  absent locally (conditional), a whole `party_screen_test.dart` suite skip, and two known
  `assess_stage_switching` skips. Named with `flutter test --reporter json`, which the compact
  reporter's counts cannot do.
  **Next unticked: 6.8** — honest stats (smallest independent item per §6 disposition table).
  ⚠ **6.8 is a Teacher-lane task, not an Executor one** (that change's §6 disposition table:
  *"Needs a decision about what the readout is for before it can name replacement metrics"*).
  An implementation session cannot open it; it needs a spec first.
  **2026-07-30 — `add-color-packs` 2.5 is CLOSED, all three sub-units (`1bff436`).** The 209
  widget-layer raw `AppColors.*` reads under `lib/features/**` + `lib/shared/**` are **0**, and a
  conformance gate holds it: `color_conformance_test.dart` bans the name across all of `lib/`
  with a 7-entry definition layer, plus a second test that deletes an exemption which stops being
  used. `./verify.sh` **ALL GATES PASSED, exit 0, 1347 pass / 3 skip / 0 fail**, analyzer 0/0.
  This closed a **live shipped accessibility defect**, red-proved on the named target: under
  `AccessiblePalette.deuteranopia` `milestone_list.dart` painted `#1F8A70` while the overlay
  published `#009E73`. Two rulings worth carrying forward — (a) a color migration needs the call
  site's **scope** as input where the icon migration did not, because a text-level rewrite
  compiles only where a `BuildContext` is in reach (~23 sites were not, and the analyzer was the
  oracle); (b) the always-dark surfaces (video player, trim timeline, instax viewer) were not a
  mistake to list as exceptions but an **unnamed role** — shipped as `AppMediaChrome`, which
  resolves the active pack at `Brightness.dark`, so they keep their intent and return their
  pixels to the theme. **Next in that change: 2.6** (`theme_providers.dart`, 10 sites, the 3.4
  "cannot express unset" shape) — 3 of its 4 remaining files were *ruled* rather than deferred.
  **New: 2.7** — two crews worked 2.5 concurrently on one tree and only convergent substitution
  kept it lossless; `## NOW` names the active change, which is no lock on the active task.
  Claim-on-start is the cheap fix and belongs in `FACTORY.md`.
  **Owner decision open, blocking nothing** (`add-color-packs` 6.1): PANTONE® names/numbers
  are licensed IP, so the spec ships in-house curated seasonal collections behind a catalogue
  interface and a licensed dataset drops in later with no mechanism change. **6.2 (design the
  new handpicked family) is deliberately after the ramp** and is where 4.5 gets resolved — by
  the ramp, not by nudging one hex.
  **NOT PROVEN:** that any pack *looks* better. No device, no browser. The gate proves
  completeness, monotonicity, contrast, and precedence — none of which is taste (that change's
  V.3, routed to `owner-verification-passes`).
  6.6–6.10 stay unspecced with their lanes and a recommended order recorded in that change's
  §6 disposition table (6.6 is Scholar-gated).
  No backend dependency — runs parallel to the owner-gated Appwrite and distribution work.

- **Archived 2026-07-29 (implementation-complete, 19/19):** `add-stacked-viewport-layout`
  — **Stacked-viewport layout constitution.** All five tabs are on one frame: `AppLayout`
  tokens, `AppScreen`/`AppSection` as a type rather than a convention, and two CI gates that
  replace review (`frame_conformance_test.dart` for the roster, `type_baseline_test.dart` for
  the scale). Owner ruled the type scale rides a **2pt** baseline — the proposed 30→32 / 26→28
  snap did not happen — and that `web-mirror/` is exempt from the frame. Reason-for-archive
  note: `openspec/changes/archive/2026-07-29-add-stacked-viewport-layout/README.md`; capability
  promoted to `openspec/specs/layout-system/`. The owner sitting (does it read as one viewport
  when switching tabs?) is routed to `owner-verification-passes` §6.1 — nothing here was proven
  on a device or in a browser.

- **Parked 2026-07-29 (was active, owner-directed earlier the same day):** `add-web-first-release-and-monetization`
  — **Ship-today redirect.** Owner's ruling this session: *"no need for testing and wasting
  tokens on devices — I just need if generally the project and its workload is in working
  shape so I can do minor UI tweaks and functionalities and deploy and distribute today for
  testing."* That makes **Flutter Web distribution** the active track and demotes the Android
  device-harness work below it.
  **Proven green 2026-07-29:** `./verify.sh` all gates (ledger, `--strict`, docs ledger, l10n,
  analyzer 0/0, **1225 tests pass / 3 skip / 0 fail**) + `flutter build web --release`.
  **Not proven:** anything on a device, live Appwrite sync (Phase M), payments.
  Distribution entry point is `scripts/distribute.sh web`.
  **Queue reconciled the same session:** 37 → 30 open changes; the Phoenix/BEAM/Gleam
  cluster retired as superseded by the locked Appwrite ruling — see
  `openspec/changes/archive/2026-07-29-ARCHIVE-NOTE.md` and the new CLAUDE.md
  "Supersession rule".

- **Parked 2026-07-29 (was active, owner-directed 2026-07-28):** `android-e2e`
  — Android launch + device-test harness. **6.1 DONE 2026-07-28** — the tooling path is
  ruled in the change's `design.md` (D1–D4): `argent` (`@swmansion/argent`) is an MCP
  agentic toolkit scoped to **iOS-sim / web** smoke, *not* a device farm and not on the
  Android path; **Maestro 2.1.0 is the Android driver**, and **48 flows plus `config.yaml`
  already exist under `.maestro/`**, fixture-seeded through
  `lib/core/services/automation_fixture_service.dart`. Patrol is declared in `pubspec.yaml`
  but has zero tests — it stays the escape hatch for native dialogs / OAuth WebView only.
  **6.2 DONE 2026-07-28** — `scripts/android_smoke.sh` (parse → boot → build → install →
  drive → honest exit code), verified end-to-end on `emulator-5554` (API 35).
  ⚠ **It found that the Android app had never rendered a frame.**
  `DefaultFirebaseOptions.currentPlatform` throws for Android and the throw escaped
  `main()` before `runApp` — blank white screen, no crash dialog, on every Android build
  including the owner's device. Fixed in `8e7f683` (boot degrades to
  `firebase … detail=unconfigured`); the app now renders. Analyzer, 1225 tests, and the web
  build were all green the whole time this was broken — no cheap signal could see it.
  **Next unticked task: 6.3** — the 6/6 smoke failures are now stale selectors, not a dead
  app: the flows encode the pre-redesign 5-tab IA. Mostly a mapping
  (`moves-tab`→`breakdex-tab`, `progress-tab`→`stats-tab`, `drill-tab`→`review-tab`);
  `flow-tab` has no successor. 6.4/6.5 need a real device — owner's session.
  Android SDK, `adb`, and `emulator` are all present; no emulator is currently booted. A
  release APK already builds (53.7 MB, exit 0) but is **debug-signed** — a Play-uploadable
  artifact is still blocked on the owner's `keytool` keystore step (see below).
  **Parallel-allowed track:** Flutter-web UI-state work (view order/precedence, one-page
  layouts, Fluid+Morph motion) — needs the owner to name specific screens; "the web app"
  is too broad to scope.

- **Parked 2026-07-28 (was active, owner-launched 2026-07-27):** `domain-restructure`
  — Reorganize `lib/` by product domain. Additive over invasive, no behavior change.
  **3.1 DONE 2026-07-28** — map at `openspec/changes/domain-restructure/domain-source-map.md`;
  10 domains named (`sets` beats `labs`; `media` and `backup` stay separate; `kernel` = pure
  primitives + platform seams); 4 high-fan-in files quarantined from the batches.
  **3.2.0 DONE 2026-07-28** (owner-approved prerequisite found by 3.1) — `lib/` normalized
  from 1678 relative imports to `package:breakdex/…`: 1721 `dart fix` rewrites across 331
  files, `always_use_package_imports` now enforced. Analyzer 0 errors / 0 warnings before
  and after; the 2 remaining suite failures reproduce at `b0b8f90` with the change stashed
  out, so zero regressions.
  **Next unticked task:** 3.2 Move one low-risk domain slice mechanically.
  ⚠ **Recommendation on the record: park 3.2–3.5.** They move folders, ship no product
  value, and would touch every file while the release queue waits. The prerequisite that
  had standalone value (3.2.0) is done. Suggested reorder: `distribution-web` →
  `multi-user-sync` → `android-e2e`, and return to the folder moves after a release.
  Owner call.

### Session 2026-07-28b — queue triage + diagnostics retention

**Owner directive:** before picking a front, establish what is active, what is in
flight, and what should be archived. Done — and the answer is now derived, not written
down: **`./status.sh --queue`** classifies every open change from ticks, git age, and
`openspec validate --strict`. Run it instead of trusting this paragraph.

What it surfaced on first run (queue went 39 → 37 open):

- **2 archived** — `add-scientific-research-workbench` and
  `add-quiet-playback-and-senior-drill-ui` were fully ticked and landed in `46c604c`,
  still sitting open. Archived with `--skip-specs` (both are tooling / settings-cleanup
  changes with no spec deltas to sync).
- **13 fail `--strict`, one root cause** — they were written to an older proposal
  template (`## Summary` / `## Motivation`) before openspec required `## Why` /
  `## What Changes` plus `specs/` deltas. **Not retrofitted in bulk**; repair belongs to
  whichever of them becomes active next. `verify.sh` only strict-checks the *active*
  change, which is why this rotted unseen — the footer has always named it as NOT PROVEN.
- **3 structurally broken — owner call needed.** `add-capture-and-pro-metadata` and
  `harden-photo-permission-and-export-cleanup` have no `tasks.md` (never planned into
  executable work); `unified-continuity-and-combo-editing` has only a `spec.md`, so
  openspec does not recognise it as a change at all. Keep, re-plan, or drop?
- **5 STALE** (>30d untouched): `add-combo-journey-system`, `add-web-mirror-player`,
  `foundation-data-resilience` (59/64), `redesign-add-tab-with-move-combo-choice`,
  `tighten-combo-journey-and-review-polish` (33/36). Two of those are nearly finished.

**Queue reorder — 2026-07-28.** The owner named **Flutter web** and **Android launch** as
the day's work, which parks `domain-restructure` 3.2–3.5 by directive (folder moves, no
product value; 3.2.0, the prerequisite with standalone value, already landed). The NOW
block therefore moves to `android-e2e`. The *fuller* ordering
(`distribution-web` → `multi-user-sync` → `android-e2e`) remains the previous session's
**recommendation, not yet confirmed** — do not treat it as ruled.

**Diagnostics — you can now hand over a log.** `DiagnosticsLog` retains as well as prints
(bounded ring buffer, captures at `debug` while the console stays at `info`), and
`export()` redacts secrets, JWTs, and email local-parts so a log can leave the device.
System Status → DIAGNOSTIC LOG **was fake** (four hardcoded lines) and now renders the
real buffer with a **Copy** button. `Sync` had *zero* instrumentation — the least-logged
subsystem and the one being debugged — and is now covered at its two chokepoints plus
`hydrateAllFromBackend`, including *which* cutover gate shut when a push is skipped.

**PROVEN:** `./verify.sh` ALL GATES PASSED — 1225 pass / 3 skip / 0 fail, analyzer 0/0.
**NOT PROVEN:** any of this on a device; that the redactor catches a secret shape outside
its pattern list.

**Not started this session** (owner asked, ran out of budget before them): Android launch
+ `android-e2e` 6.1–6.3 (Maestro is installed and is the Android tool — `argent` is
`@swmansion/argent`, ruled for iOS-sim/web only, so 6.1 is still an open decision), and
Flutter-web UI-state work. `multi-user-sync` 5.1–5.5 remain **owner-gated**: all five are
*proof* tasks needing live Appwrite credentials and two devices. Per-user isolation is
already code-complete server-side (`functions/sync-push/lib/main.dart` — trusted
`x-appwrite-user-id`, `Query.equal('userId', …)`, `_ownerOnly(userId)` permissions).

### Session 2026-07-28 — the release gate is now real (read this before distribution work)

**The full gate passes for the first time: `./verify.sh` → ALL GATES PASSED**, 1212 pass /
3 skip / 0 fail in ~64s. It was previously non-terminating, so nothing could be verified
before a release. Three real bugs were behind that, all fixed:

1. **`scripts/distribute.sh` built past a failed gate** (`1b7e34b`). It printed
   `SOME GATES FAILED` and still produced `build/web`: `run_verify` never checked the exit
   status, and the script runs `set -u` without `set -e`. The script's premise — gate, THEN
   build — was not enforced. It now exits with the gate's status.
2. **`lib/dev/preview_harness.dart` could not render any real screen** (`af2a13b`): no
   `localizationsDelegates`, so every `AppLocalizations.of(context)!` call crashed; and no
   Appwrite auth stub, so a *preview* made a network call. The IDE preview tool was broken,
   not just its test.
3. **Android release builds sign with debug keys** (`ec5d28f`). `android/app/build.gradle.kts`
   still has the Flutter template's `signingConfig = signingConfigs.getByName("debug")`, so
   `distribute.sh android-aab` would have exited 0 with a bundle Play rejects. It now refuses,
   with `--allow-debug-signing` as the explicit local-install escape hatch.

**PROVEN this session:**

- full gate green (`./verify.sh` ALL GATES PASSED, 1212/3/0 in ~64s), analyzer 0 errors / 0 warnings
- `scripts/distribute.sh web` produces a real artifact **off a green full gate** —
  `build/web`, 42 MB, `main.dart.js` 5.5 MB, 38s compile
- `scripts/distribute.sh android-apk --allow-debug-signing` produces a real release APK —
  `build/app/outputs/flutter-apk/app-release.apk`, **53.7 MB, 113s, exit 0**. So the Android
  release toolchain works; Android is one keystore away, not structurally blocked.
- the Android signing guard refuses correctly when the keystore is absent

**NOT PROVEN:** any *uploadable* Android artifact (the APK above is debug-signed — Play will
reject it) · any iOS artifact (never attempted; needs Xcode + signing) · device behavior on
any platform · live Appwrite sync · the deployed web app.

**Owner-gated, blocking Android distribution:** generate the upload keystore
(`keytool -genkey -v -keystore ~/breakdex-upload.jks -keyalg RSA -keysize 2048 -validity
10000 -alias upload`), write `android/key.properties` (already gitignored), and point the
release `signingConfig` at it. Until then `android-aab` correctly refuses.

**Known friction, needs an owner call:** the docs-ledger gate diffs `verified..HEAD`, so any
commit touching a watched path leaves the tree red until a follow-up hash-bump commit — and
that red now blocks `distribute.sh`. It cost 3 extra commits today. Diffing against the
working tree instead would let the bump ride in the same commit. That changes a gate, so it
was left alone.

- **Change (archived 2026-07-27):** `engineer-workflow-and-multi-user-foundation`
  — Factory model accepted, old owner-gated proof closed. Umbrella split into child changes: domain-restructure, action-audit-log, multi-user-sync, android-e2e, distribution-web.

- **Change (archived 2026-07-27):** `fix-video-backup-truth-and-unify-account`
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
  **4.0 DONE 2026-07-19 (owner device run + extended forensics).** The dump answered it
  and **refuted both hypotheses**: manifest 99 (72 live / 28 underprotected / 27
  tombstoned); ops completed 118 / failed 264, growing **+22 per cycle** — exactly the 22
  unreachable; on disk without a local copy row **0**. All 22 read
  `owners=0 (0 archived, 0 deleted)`, and the new owner-join positive control read
  **50/72**, so the join works and there is simply no owner to widen the heal toward —
  yet the bytes are not gone: the picker's APP VIDEOS scan lists them and a byte-exact
  match was confirmed for `69e13899`. Ruling **D10**: *hash is identity, path is a hint,
  the sandbox is byte authority*. Remedy is **4.7** (hash-indexed sandbox rescue as the
  third heal lane) then **4.8** (explicit dev-action tombstoning of confirmed-gone
  residue); **4.4 is re-gated on 4.7** — terminal is only reachable after a sandbox miss.
  Forensics landed as a four-way `AssetResolution` (adds `DELETED-OWNER`) plus the
  positive control. **4.3 also DONE 2026-07-18**
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
  **4.7 DONE 2026-07-19** — `SandboxHashIndex` is heal lane 3: one recursive pass over
  `Moves/` + `Combos/` keyed by the hash embedded in canonical filenames, so an asset with
  no owner of any kind still finds its bytes. The parser validates hex and length rather
  than reusing the repo's `split(' - ').last` idiom, which returns the whole basename on
  names with no separator — a junk index key can only ever hand the uploader the wrong
  bytes under the right hash. Diagnostics now measure the rescuable/gone split per asset,
  which is exactly the evidence 4.8 is gated on. Suite 1157 green, 0 regressions.
  **4.7's device evidence (2026-07-19 owner run) read `sandbox rescue: 22 of 22` — all in
  `Moves/.lost+found/` — falsifying 4.8's tombstone premise.** Root cause ruled **D11**:
  the janitor quarantined manifest-known files (two bookkeepers, no shared ledger), and
  tombstoning would soft-delete recoverable videos. 4.8 REWRITTEN restore-not-tombstone;
  tombstone demoted to fallback 4.10.
  **4.8 code DONE 2026-07-19** — `OrphanRestoreService`: full-hash verify (two of the 22
  showed name drift; wrong bytes under the right identity is the one unforgivable
  failure) → re-home to `Moves/Recovered/` updating `localPath` in the same operation
  (1.8 rule) → recreate an owning move (Recovered category, registered on first
  restore). Idempotent; dev-panel action + inline re-dump. 5 unit tests.
  **4.9 DONE 2026-07-19 (loop closure)** — the janitor now consults the manifest
  registry before quarantining: manifest-known files stay put for the engine's heal
  lane 3; only genuinely unknown files quarantine. Red proven by stash. 4 tests —
  first-ever for `StorageJanitor`. Suites 706 green (sync+db+services), analyze clean.
  **4.4 DONE 2026-07-19** — the bytes-nowhere verdict: all three heal lanes exhausted
  (now including a null stored path, previously an unhealable insta-fail) →
  `'terminal'` op status, budget untouched, and `queueUpload` consults it — closing
  D9's re-queue hole (second-cycle red proven). **Ruling (D9 addendum): terminal is
  revocable-automatic** — restore and re-import `clearTerminal` when bytes re-home,
  because a permanent verdict is a silent soft-delete (D11's lesson forward). The
  classifier's `isTerminal` now means the verdict, not an exhausted budget; 4.5's
  "keeps failing" copy under-claims for terminal assets and its "will not retry"
  upgrade folds into 4.10. Suites 710 green (sync+db+services) + 15 settings widgets,
  analyze 0 errors.
  **4.8 device run DONE 2026-07-19 (owner) — 18 restored, 4 refused, 0 byte-less.**
  Not the predicted 22/22, and the shortfall is the full-hash gate earning its cost:
  four `.lost+found` files hold bytes that are not the hash their name claims, two of
  them under *exactly* matching names. Name agreement is not evidence — trusting the
  filename token would have adopted four videos under wrong identities, silently.
  A refusal now names what the bytes actually are (duplicate of a live asset /
  tombstoned / another orphan / unknown), each verdict carrying its own remedy, so the
  residue is triageable from the device log with no further instrumentation. Red proven
  by stash; sync+db+services **711 green / 0 failures**, analyze 0 errors.
  **Next (owner, highest value): re-sign-in to Google on the phone.** The 18 recovered
  videos exist only on that device — `2× Bad state: GDriveProvider not authenticated`
  in the same dump means the upload lane cannot protect them. This also unblocks
  checking whether the 4 missing identities still exist in Drive (`gdrive×verified: 50`).
  **Restore re-run 2026-07-19 (owner, new build): the 4 refusals are all intact
  `unknown to manifest`** — each file's bytes hash to exactly what its filename
  claims; the "wrong bytes under a matching name" reading is dead. They are real
  videos the ledger never knew; remedy = ordinary picker import (APP VIDEOS lists
  them), no code. Owner signed in to Google the same day, so the upload lane can
  now protect the 18.
  **4.10 DONE 2026-07-19 as re-premised — second half only** (the tombstone half's
  target set was empty and stayed unbuilt, per the premise note in tasks.md):
  `SyncOperationsDao.purgeResolvedFailed()` deletes `failed` ops superseded by a
  verified copy on the same provider (the 264-row archaeology); live-retry rows and
  terminal verdicts stay, pinned by test. Dev-panel "Clear stale failed operations"
  with inline re-dump. The terminal copy upgrade folded in from 4.5: "keeps
  failing" → "Won't retry" / "{count} can't be backed up" — honest now that 4.4's
  verdict survives sweeps; the guard test reserves the phrase for terminal rows.
  Red by stash (4 failures against pre-fix lib); sync+db+services+settings **730
  green / 0 failures**, analyze 0 errors, l10n gate green.
  **Everything left in this change is owner-gated (surfaced 2026-07-27 session):**
  1.7/4.6 device proofs — next owner look = Sync Status after a sweep: tap "Clear stale
  failed operations", expect the failed count to collapse and the 18 to drain to backed
  up. Phase 3 waits on **3.1** — design.md O1/O2 are still open questions, and 3.2
  (adding `drive.file` to the live Appwrite Google provider) IS the consequence O1 asks
  the owner to accept; its curl proof also needs a fresh Google OAuth session only the
  owner can grant. The earlier "3.2 agent-runnable" note named the *mechanism*
  (console-cookie recipe), not a lifted gate — an agent executes 3.2 once O1 is ruled.
  **Carried finding FILED 2026-07-27 (verdict in tasks.md, code-verified):** the 76×
  "negative content length" generator is dead — engine heal lanes make a missing file
  terminal pre-provider (`asset_sync_engine.dart:499-519`) and `GDriveProvider.upload`
  guards `notFound` honestly (1.8c); the rows are pre-1.8 archaeology, purged by 4.10's
  dev action as assets verify. The `videoFileSize`-fallback half is display-side,
  already filed under `humanize-video-surfaces-and-gate-release` 2.3. Baseline
  re-proven at HEAD 2026-07-27: analyze 0 errors, sync+db+services 715 green / 0 fail.
  **New sibling change (2026-07-19, strict-valid): `humanize-video-surfaces-and-gate-release`**
  — Phase 1 picker collapse (In Breakdex / Import; sequenced after 4.7), Phase 2 human
  subtitles (independent, startable now), Phase 3 the release gate as a falsifiable spec.
  **Phase 3** stays owner-gated on design O1/O2.
  **2.1 DONE 2026-07-19** — the category move row subtitled `originalVideoName` (a camera
  filename, often a bare UUID); it now shows the active sort's own date via the shared
  `LibraryDateLabel`. The ruling that fell out: **the caption names the source
  `effectiveDate` resolved to, never the sort that was asked for** — the fallback chains
  make an unfilmed move sort under "Filmed" by its `createdAt`, so labeling it "Filmed"
  would swap a useless subtitle for a false one. `LibraryDateSource` +
  `effectiveDateSource` mirror the chains on both `Move` and `LibraryRow`, with a property
  test pinning source-to-date agreement. Suites +267 vs baseline +257, identical 7 reds
  (2 party + 5 card-count, both documented flake classes) — 0 regressions; analyze 0
  errors; l10n gate green.
  **2.2 DONE 2026-07-19 — owner corrected the scope mid-task, and the correction was
  the point.** As specced it was a confirm, and the confirm passes (the labeled Video
  Info panel already carries `originalVideoName` + file size). But 2.1's sweep
  undercounted: the detail screen had **two** renderings, and the second was a
  monospace caption under the move's name showing the filename, falling back to
  `ID: <hash8>` — 2.1's UUID-subtitle defect one screen deeper. It now shows the added
  date through the shared `LibraryDateLabel`, owner-selectable via a new
  `MoveDetailCaption` preference (Date / Filename / ID / None, default Date) in
  Settings → Library. **Ruling (D4 addendum): an identifier is reachable only by
  explicitly selecting it, never by fallback** — `Filename` on a move with no filename
  resolves to the *date*, since being handed a hash when you asked for a name is the
  defect itself; a property test walks every mode to pin it.
  **Recorded because it nearly shipped:** the first proposal was to delete the caption
  as a duplicate of the panel row. It is not — the panel is gated on `videoPath != null`
  while the caption was gated on identity, so a **cloud-only** move (bytes not local,
  hash present — what the backup effort produces) would have been left with no
  identifying text at all. Deleting it would have been a silent information loss of
  the kind D11 warns about. The residual asymmetry (provenance placement keyed on byte
  locality rather than identity) is filed under 2.3 for an owner ruling.
  Verify: 12 new tests (9 pure resolver + 3 widget, no ProviderScope/Drift so the flake
  class cannot apply); affected suites 187/187; full suite **1193 green / 11 skipped /
  9 red with the red set byte-identical to a stashed baseline** (`diff` empty) →
  **0 regressions measured**; analyze 0 errors; `check_l10n.sh` green; web build green.
  **Next in Phase 2: 2.3** (codify design D4 in the `openspec/AGENTS.md` review
  checklist, plus the carried cloud-only-provenance finding).

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
  **4.1 DONE 2026-07-18** — the inline per-category count loop moved out to
  `libraryCategoryActivities` (`lib/core/models/library_category_activity.dart`): one pass
  over the same move list, a `max` alongside the count, no new query and no schema change
  (design D5). The recency date is `createdAt`, not `updatedAt` — the spec says "most
  recently added to", and editing an old move is not adding to the category. Empty
  categories are **seeded** from the category-name set rather than skipped, so 4.2's
  "sorts last, never hidden" is a sort rule over present data instead of a null-hole at
  the call site. The screen is wired to it but still renders only the count; disclosure is
  4.2. Binary truth: 4 unit tests, three mutations each proven red (last-seen instead of
  max, no empty seeding, unknown category not routed to uncategorized). `flutter analyze`
  0 errors, suite **1122 green / 9 pre-existing reds / 0 regressions**, `check_l10n.sh`
  green.
  **4.2 DONE 2026-07-18** — `categoryNamesByRecency` (same file) re-orders the stored
  category list most-recently-added-to first, and `_CategoryTile` now takes the whole
  `LibraryCategoryActivity` and renders 3.1's `LibraryDateLabel` under the name, so the
  tile discloses the date the grid was sorted on. Ties **and** the empty tail fall back to
  the stored (creation) order by an explicit index tiebreak — `List.sort` is not stable in
  Dart, so every empty category compares equal and could otherwise swap places on any
  rebuild. Empty tiles read **"Nothing here yet"**, deliberately not naming the entity:
  that noun is user-configurable, so it cannot be baked into a translated string. Binary
  truth: 5 unit + 3 widget tests, **six** mutations each proven red (no tiebreak −2,
  empties first −2, oldest-first −1, stored order rendered −3, empties hidden −1, no tile
  date line −1); the two stability tests use 40 categories on purpose, since below 32
  elements Dart's sort is stable by accident. `flutter analyze` 0 errors, suite **1130
  green / 9 pre-existing reds / 0 regressions**, `check_l10n.sh` green.
  **Phase 5 COMPLETE 2026-07-18 — this change is DONE and archive-ready.**
  **O1 ruled by the owner: the date line stands alone.** No file size, no original
  filename; backup state is the one addition and it lands as a visual, not text. So `5.1`
  records the ruling in design.md D4 and `5.2` closes as a no-op under it.
  **`5.3` was NOT still blocked** — its stated blocker (that change's Phase 4 landing
  `copyCount` truth) cleared when 4.2/4.3 ticked, so the honest indicator landed here.
  Reading the code corrected the task twice: the icon is not a tile-wide backup
  indicator but the no-thumbnail placeholder only, so the claim under repair is
  *"restorable from cloud"*; and the honest predicate is **not** `copyCount >= 2`, since
  `copyCount` counts the local copy — an asset can meet the two-copy minimum with zero
  cloud copies. New `AssetCopiesDao.watchRestorableHashes()` (verified copy on a
  non-`local` provider, one stream for the whole grid) behind
  `restorableAssetHashesProvider` replaces `contentHash != null`. Red proven on the cell
  (pre-fix, an asset with no cloud copy renders the download icon) plus two DAO
  mutations (−2 each). Suite **1134 green / 9 pre-existing reds / 0 regressions**,
  analyze 0 errors.
  **Filed, not fixed** (found while testing 4.2, predates it): `MoveCategoryScreen`'s
  AppBar `leading` (chevron + "Back") overflows its fixed 56px toolbar slot, so the Back
  affordance is clipped on-device. Belongs to whichever change owns library chrome.

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
4b. **`enforce-face-law-conformance`** — ⭐ NEW (2026-07-30 owner ruling: launch-consistency
   pass): Face Law doctrine (essentialist chrome rules as checkable claims), layout
   conformance gate (26 raw-Scaffold feature files → 0, shrink-only allowlist), one-frame
   `AppScreen` migration in owner-review-gated batches, platform-native adaptation by
   defaults with visible degradation, valoric factory parity (Face Law + professional-tool
   bars, sittings on `status.sh`). Sequenced directly after the active redesign change —
   no backend dependency; release-blocking for consistent launch.
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
10. Nearly-done finishing passes — **resolved 2026-07-29, this list is now nearly empty.**
    `foundation-data-resilience` (59/64), `add-web-mirror-player` (19/26), and
    `redesign-add-tab-with-move-combo-choice` (19/27) all archived as
    **implementation-complete**: every remaining task was owner device/console proof, now
    collected in `owner-verification-passes`. `add-historical-photos-bootstrap` archived
    complete (its last two tasks were BEAM speculation, void under the Appwrite ruling).
    Still open here: `tighten-combo-journey-and-review-polish` (33/36 — 3 small tasks) and
    `repo-organization-and-readme-refresh` (12/15).
11. **`state-machine-crud`** — kept open as the tracker for genuinely unshipped residual work
    (TrashMachine, MoveListMachine, AppMachine, notes/log overlays); the `Machine<S,E>`
    framework + move-detail vertical already shipped (see its `tasks.md` Residual header).
12. Everything else parked (labs, research workbench, photo archive recovery, etc.).
    **`provenance/beam ingestion` is no longer on this list — it was archived 2026-07-29** as
    superseded by the locked Appwrite ruling, along with the rest of the Phoenix/BEAM/Gleam
    cluster. `add-self-healing-video-reliability-runtime` deliberately survived it: same 89-day
    cluster, but on-device product work with no BEAM dependency.

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

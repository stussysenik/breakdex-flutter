# Tasks — Total Code Ownership & Config Purge

> One commit per directory sweep; each commit message states what was purged and why the rest
> stays. Build + test evidence in every sweep (zero behavior change is the gate, not a hope).
> Skip any directory currently under active migration; sweep it after its migration lands.

## Phase 1: Inventory + root configs (no code)

- [ ] 1.1 Dependency audit: `dart pub deps` + import grep per `pubspec.yaml` entry; remove unused
  packages; for each survivor add/verify a one-line reason if non-obvious. Same for
  `web-mirror/package.json` (`npx depcheck` or import grep).
- [ ] 1.2 `analysis_options.yaml`: every enabled/disabled rule is deliberate (repo already has the
  Phase H lint posture — reconcile, don't duplicate); delete commented-out scaffold rules.
- [ ] 1.3 Root dotfiles + `.gitignore` + any CI config: purge entries referencing tools/paths that
  no longer exist; each surviving section maps to a real workflow.
- [ ] 1.4 Gate: `flutter analyze` clean, `flutter test` green, `web-mirror` build + tests green.

## Phase 2: Platform directories

- [ ] 2.1 `ios/`: purge scaffold artifacts and unused build settings; verify against the
  dual-Info.plist gotcha (debug uses Info-DebugProfile.plist) before touching any plist; every
  surviving key (permissions strings, URL schemes, GIDClientID) traceable to a feature.
- [ ] 2.2 `android/`: same treatment (gradle files, manifest permissions each justified by a
  feature or removed). If Android bring-up (release change 5.3) has not landed, sweep only what
  exists and note the deferral.
- [ ] 2.3 `web/` (once created by the release change): no scaffold boilerplate survives —
  manifest, icons, index.html all product-real.
- [ ] 2.4 Gate: device/simulator build via flowdeck green; `flutter build apk` if Android is up.

## Phase 3: Source + tests

- [ ] 3.1 `lib/`: delete unreferenced files (prove with import graph / `dart analyze` unused
  checks), dead code paths behind flags that no longer exist, commented-out blocks. Sweep in
  dependency order (leaf features first, `core/` last).
- [ ] 3.2 `test/`: delete tests of deleted code; no skipped/zombie tests remain without a tracked
  reason.
- [ ] 3.3 Assets: unreferenced assets out of `pubspec.yaml` and the tree.
- [ ] 3.4 Gate: full `flutter test` + app smoke on simulator (open library, play video, review).

## Phase 4: Docs + specs hygiene

- [ ] 4.1 `docs/`: fold-or-delete anything contradicting shipped reality (one-roadmap precedent);
  surviving docs get a purpose line at top.
- [ ] 4.2 `openspec/`: archive-or-reconcile stale changes per the ledger rule (owner sign-off per
  archive, mirroring the 2026-07-06 audit).
- [ ] 4.3 Update `CLAUDE.md` / agent docs where this pass invalidated them.

## Validation

- [ ] V.1 `openspec validate harden-code-ownership-and-config-purge --strict --no-interactive`
- [ ] V.2 Every sweep commit's message names its purges; `git log` shows pure deletions (no
  history rewrites).
- [ ] V.3 Final: all builds (iOS, web, Android-if-up) + full test suites green; diff review
  confirms zero behavior-bearing lines changed.

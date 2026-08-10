# Proposal: E2E harness, datasets, and tooling

> **Language: Dart (Flutter) + shell.** Depends on: `automation-fixture-service`,
> `appwrite`, `gdrive`, `enforce-face-law-conformance`. Implementation in a fresh
> student session — never this one.

## Why

Breakdex has **unit depth and E2E absence.** The suite proves models, DAOs, state
machines, and design-token conformance at scale (1000+ tests), but nothing proves a
real user can launch the app, add a move from a video, review it across devices, and
trust their data survives. The gaps are exactly the ones `android-e2e` (D5) paid to
learn: the Android app had *never rendered a frame* while every unit test was green;
the flow suite had version-drifted; selectors were stale from the redesign. Cheap
signals passed while the product was dead on the surface.

Three things are missing, and they compound:

1. **No multi-surface harness.** Web is the #1 product surface (loss-function ranked:
   "Flutter Web = the released consumer app") but has *zero* E2E. iOS is simulator-only
   and manual. Android has 46 Maestro flows that predate the redesign and a smoke
   script (`scripts/android_smoke.sh`) that correctly exits 1. There is no single
   command that proves the product works on *any* surface a user actually touches.

2. **No realistic datasets or media.** The `automation-fixture-service` seeds review /
   stress / party rows — good bones — but the only fixture media are three ~32KB clips
   that are near-identical byte-for-byte. A video-handling suite can't claim to prove
   import, playback, trim, and export on "video" that is a 32KB placeholder. And the
   datasets aren't countable: a flow asserts a move is *somewhere* on screen, never that
   "exactly 7 due moves render" — so a silently-dropped row passes every check.

3. **No test tooling, no permission matrix, no honest rollout.** Nothing lists the
   fixtures, generates media, compares a run to a baseline, or records which device a
   result came from. OS permissions (Photos, Camera, Microphone, Notifications) are
   granted ad hoc per simulator, so a CI run that needs a permission silently fails the
   first time. And the only rollout posture is "run everything" — there is no gradual
   ladder (web smoke → device smoke → full matrix) with honest NOT PROVEN lines, so a
   green run implies more than it tested.

This change adds the harness, the datasets, the media, the tooling, and a phased
rollout — the "full E2E suite simulating real use, rolled out gradually, diagnostic
*and* revealing" the user asked for. It extends `automation-fixture-service` (the
foundation), it does not replace it. It absorbs the surviving, stale legs of
`android-e2e` (6.3–6.5: flow validation, device matrix, device gate) into a
multi-surface posture where web leads.

## What Changes

- **A multi-surface E2E ladder** ranked by the loss function: **web first** (the
  product), then iOS simulator, then Android emulator, then the owner's physical
  device. One entry point (`scripts/e2e.sh`) runs a named tier on a named surface and
  exits non-zero on the first failure, printing what it did and did not prove.
- **A web E2E seam** — the first ever for the #1 surface. A `WebDriver` abstraction
  with a Playwright implementation driving the released `flutter build web` bundle,
  so the same GIVEN/WHEN/THEN flows run on desktop and mobile-chromium (iPad).
- **Countable, deterministic datasets.** Extend `automation-fixture-service` with
  named, seeded dataset profiles (`solo`, `arsenal`, `combo-lab`, `sync-storm`,
  `empty`) each declaring exact counts (moves, combos, decks, FSRS cards, reviews,
  due-now) so flows assert on *numbers*, not presence. Every profile is seed-stable
  (seeded RNG, fixed timestamps relative to a pinned "now") so a run is reproducible
  and a regression is bisectable.
- **Fixture video library.** A `scripts/seed_media.sh` that uses `ffmpeg` to generate
  a deterministic family of small clips — varied duration, resolution, orientation,
  codec (h264/h265), with/without audio, with/without motion — from a pinned seed, so
  video-handling flows prove real decode/trim/export paths. The existing 3 clips stay
  as the "smoke" tier; the generated family is the "matrix" tier.
- **Test-management dev tools.** `scripts/e2e_*`: list fixtures, generate media, run a
  tier, diff screenshots against a committed baseline, record a device-matrix row, and
  print the cumulative NOT PROVEN ledger. A `test_fixtures/README.md` cataloguing every
  dataset and clip with its hash.
- **A permission matrix.** A committed `test_fixtures/permissions.md` naming, per
  surface and per flow-group, which OS permissions are needed and how they are granted
  (simctl, Maestro `assertPermissions`, Patrol `grantPermission`, CI entitlement). A
  run pre-checks the matrix so a missing permission fails fast with a named fix instead
  of a silent selector miss 30s in.
- **Gradual rollout with honest gates.** Phase 0 parse/lint (device-free) → Phase 1 web
  smoke → Phase 2 device smoke (iOS sim + Android emulator) → Phase 3 full matrix →
  Phase 4 owner physical device. Each phase is a tier in `scripts/e2e.sh`; a phase gates
  the next; every phase prints its NOT PROVEN lines verbatim.

## Dependencies

- **`automation-fixture-service`** — the fixture seeding this change extends. Its
  review/stress/party profiles are retained; new profiles compose on the same seam
  (`breakdexFixture` launch arg + `LaunchArgumentReader`).
- **`appwrite` + `gdrive`** — sync E2E legs need a reachable backend and a Drive scope.
  The *local* legs (the complete deliverable) run against the in-memory DB + fixture
  media; the *cloud* legs (multi-device sync over real Appwrite) are behind the
  owner-gated user gate and are NOT PROVEN in CI.
- **`enforce-face-law-conformance`** — flows assert on Face-Law-stable selectors
  (semantic labels, `AppIcon` ids), never on raw text or pack-resolved `IconData`.
- **`android-e2e`** — this change absorbs that change's surviving legs (6.3 flow
  validation, 6.4 device matrix, 6.5 device gate). `android-e2e` archives as
  shipped-half; its Android smoke script (`scripts/android_smoke.sh`) is retained as a
  referenced artifact, not duplicated.
- **USER GATE (blocking, open):** physical-device runs, live Appwrite/GDrive, payments
  webview, and real OAuth are the owner's. Loopback + simulator + emulator + fixture
  media is the complete deliverable.

## Non-goals

- **No replacement of the unit suite.** This is additive E2E; the 1000+ unit tests stay
  the regression floor.
- **No Maestro rewrite.** The 46 existing flows are re-validated against the current
  surface (a mapping task, per `android-e2e` 6.3) where they still apply; net-new flows
  for the harness are authored against the Face-Law selector contract.
- **No hosted device farm.** The matrix is local simulators/emulators + the owner's
  device. No farm account, no farm bill.
- **No payments/OAuth live wiring** in the automated suite — those are behind the user
  gate; the harness exercises their *local* seams (fixture auth, fixture Drive pointer)
  only.
- **No new product features.** This change proves features; it does not add them. (The
  "combo page cleanup" and "make features countable / hard to lose data" the user named
  are captured as their own changes — this change only *tests* them.)

## Success criteria

- A student session implements the change from the spec alone, zero clarifying
  questions, in ≤4 burst days.
- `scripts/e2e.sh web smoke` runs on desktop + mobile-chromium against the released
  web build and exits 0; a broken home screen fails it on web *before* any device boots.
- Every dataset profile's documented counts match what the in-memory DB holds after
  seeding (a flow that drops a row fails the count assertion, not a presence check).
- `scripts/seed_media.sh` regenerates the fixture clip family deterministically
  (byte-identical hashes across runs on the same seed) and the clips cover at least
  duration / resolution / orientation / codec / audio / motion axes.
- The permission matrix exists and the run pre-check fails fast (named fix) on a missing
  permission instead of a silent selector timeout.
- Each phase gates the next and prints its NOT PROVEN lines verbatim; the Phase 4
  (physical device) and cloud-sync legs are explicitly NOT PROVEN in CI.

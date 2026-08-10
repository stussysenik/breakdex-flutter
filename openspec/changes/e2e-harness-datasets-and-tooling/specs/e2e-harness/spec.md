# Spec: E2E harness, datasets, and tooling

> **Language: Dart (Flutter) + shell.** Depends on: `automation-fixture-service`,
> `appwrite`, `gdrive`, `enforce-face-law-conformance`, `android-e2e`.
> Implementation in a fresh student session — never this one.

This spec defines the multi-surface E2E ladder, the countable datasets, the fixture
media family, the test tooling, the permission matrix, and the phased rollout. It
extends `automation-fixture-service` (the seeding foundation); it does not replace it.
Where this spec is silent on store, sync, or wire semantics, the `appwrite` and
`ship`/`sync` specs are normative. Where it is silent on selectors, the Face-Law
conformance spec (`enforce-face-law-conformance`) is normative: every flow selects by
semantic label or `AppIcon` id, never by raw text or pack-resolved `IconData`.

Module layout (additive):
- `lib/core/services/automation_fixture_service.dart` — *extended* with named dataset
  profiles and a media-seed hook.
- `integration_test/` — new directory; Patrol-driven native + web flows.
- `scripts/e2e.sh` — the single entry point (tier × surface).
- `scripts/seed_media.sh` — ffmpeg fixture-clip generator.
- `scripts/e2e_*` — tooling (list, diff, matrix, permissions pre-check).
- `test_fixtures/` — extended catalog + `permissions.md` + generated media.

## ADDED Requirements

### Requirement: A single multi-surface E2E entry point

The repo SHALL provide one script, `scripts/e2e.sh`, that runs a named tier on a named
surface and exits non-zero on the first failure. The surfaces SHALL be ranked by the
loss function: `web` (the #1 product surface) first, then `ios` (simulator), then
`android` (emulator), then `device` (owner physical). The tiers SHALL be `smoke`,
`matrix`, `cloud`, `owner` — each a superset of the prior. The script SHALL print,
before running, which tier/surface it is starting and the NOT PROVEN lines for that
combination; it SHALL print, after running, exactly which scenarios passed and which
failed, with the failing assertion and surface.

#### Scenario: Web smoke is the default and the fastest feedback
- **GIVEN** a clean checkout with the web build already produced
- **WHEN** `scripts/e2e.sh` is run with no arguments (defaults to `web smoke`)
- **THEN** it runs the smoke tier on desktop chromium and mobile-chromium, prints the
  web-smoke NOT PROVEN lines, and exits 0 only if every smoke scenario passes on both
  viewports

#### Scenario: A failing surface fails fast with the named assertion
- **GIVEN** the home screen renders zero due-move cards
- **WHEN** `scripts/e2e.sh web smoke` runs
- **THEN** it exits non-zero printing the scenario name, the surface, and the
  assertion that failed ("expected 7 due-now cards, found 0") rather than a generic
  timeout

#### Scenario: Each tier is a superset and a gate
- **GIVEN** `web smoke` is green
- **WHEN** `scripts/e2e.sh web matrix` runs
- **THEN** it runs every smoke scenario plus the matrix scenarios; if smoke is not
  green, the matrix tier refuses to run and prints "gate: web smoke not green"

### Requirement: Web E2E covers the released product on desktop and iPad

The repo SHALL provide a `WebDriver` abstraction with a Playwright implementation that
drives the released `flutter build web` bundle served on loopback. The same flow
definitions SHALL run on a desktop viewport and a mobile-chromium (iPad) viewport
without divergence — the flow selects by Face-Law-stable selector; only the viewport
dimension changes. Web flows SHALL cover, at smoke: launch, home renders seeded data,
add-move sheet opens, a review session completes, and a combo is created — the core
"real use" loop the user named.

#### Scenario: The same flow runs on desktop and iPad
- **GIVEN** the "complete a review session" flow
- **WHEN** it runs under `scripts/e2e.sh web smoke` on desktop then mobile-chromium
- **THEN** both runs exercise identical steps and assertions; only the viewport
  dimension differs, and both exit 0

#### Scenario: Web proves the released bundle, not a debug build
- **GIVEN** a change that breaks only the release web build
- **WHEN** `scripts/e2e.sh web smoke` runs
- **THEN** it drives the `flutter build web --release` output and the failure is
  caught on web — the surface the user actually ships

### Requirement: Datasets are countable, deterministic, and seed-stable

`automation_fixture_service` SHALL expose named dataset profiles, each declaring exact
counts for every entity kind: moves, combos, decks, FSRS cards, reviews, and
due-now (cards whose `due` is before the pinned "now"). The profiles SHALL include at
least `empty` (zero of everything), `solo` (one move, one card, nothing due),
`arsenal` (moves across all Face-Law categories, cards at varied FSRS states, a
handful due now), `combo-lab` (combos referencing moves, combo cards), and
`sync-storm` (the existing stress profile's shape: 100 moves, 30 combos, 130 cards,
500 reviews). Every profile SHALL be reproducible from a pinned seed and a pinned
"now" (timestamps expressed as `now - offset`, never `DateTime.now()` absolute), so two
seeds of the same profile yield byte-identical DB state. A flow SHALL assert on the
*documented counts*, not on presence — "exactly N due-now cards render" — so a
silently-dropped row fails the assertion.

#### Scenario: A profile's documented counts match the seeded DB
- **GIVEN** the `arsenal` profile documents "24 moves, 6 combos, 3 decks, 30 FSRS
  cards, 12 reviews, 7 due-now"
- **WHEN** it is seeded into a fresh in-memory DB
- **THEN** a count query for each entity kind returns exactly the documented number,
  and the due-now query (cards with `due < now`) returns exactly 7

#### Scenario: Seed stability across two runs
- **GIVEN** the `combo-lab` profile seeded twice with the same seed
- **WHEN** the resulting DB states are compared (export-JSON canonical form)
- **THEN** they are byte-identical

#### Scenario: A dropped row fails the count assertion
- **GIVEN** a regression that silently drops one move on insert
- **WHEN** a flow asserts the `arsenal` move count
- **THEN** it fails with "expected 24 moves, found 23" — the count, not a presence
  check, is what catches the data loss

### Requirement: Fixture media is a deterministic, varied, hashed family

The repo SHALL provide `scripts/seed_media.sh` that uses `ffmpeg` to generate a family
of small fixture clips from a pinned seed, covering at least these axes: duration
(short/medium/long), resolution (360p/720p/1080p), orientation (portrait/landscape),
codec (h264/h265), audio (with/without), and motion (static/low/high). Each clip's
filename SHALL encode its parameters; the script SHALL print each clip's byte size and
sha256. Re-running the script with the same seed SHALL produce byte-identical clips
(deterministic output). The existing three clips (`fixtures-*-beat.mp4`) SHALL be
retained as the `smoke` media tier; the generated family SHALL be the `matrix` tier.
A `test_fixtures/README.md` SHALL catalogue every clip and dataset with its hash and
the seed that produced it.

#### Scenario: The media family spans the required axes
- **GIVEN** `scripts/seed_media.sh` has run
- **WHEN** the generated clips are inspected
- **THEN** the set includes at least one clip at each of the documented duration,
  resolution, orientation, codec, audio, and motion values

#### Scenario: Media generation is deterministic
- **GIVEN** `scripts/seed_media.sh` runs twice with seed `42`
- **WHEN** the sha256 of each clip is compared across runs
- **THEN** every clip is byte-identical; the README's hashes match

#### Scenario: Smoke tier stays lightweight
- **GIVEN** a CI run that needs only the smoke tier
- **WHEN** `scripts/e2e.sh web smoke` seeds media
- **THEN** it uses only the three committed `fixtures-*-beat.mp4` clips and does not
  invoke `ffmpeg`, so the smoke tier has no generator dependency

### Requirement: Test-management dev tools exist and are scriptable

The repo SHALL provide, under `scripts/`, the tooling to manage the suite without
manual steps: `e2e_list` (enumerate dataset profiles, media, and flow groups with
their NOT PROVEN status), `e2e_diff` (compare captured screenshots against a
committed baseline and emit an exit code + an HTML diff), `e2e_matrix` (append a
device-matrix row — device, OS, surface, tier, result, duration — to
`test_fixtures/device_matrix.jsonl`), and `e2e_check_permissions` (verify every
permission the requested tier needs is granted, per the permission matrix, and fail
fast with a named fix if not). All tools SHALL be runnable from CI with no
interactive prompt.

#### Scenario: A missing permission fails fast with a named fix
- **GIVEN** the Photos permission is not granted on the target simulator
- **WHEN** `scripts/e2e.sh ios smoke` runs (which needs Photos for the import flow)
- **THEN** `e2e_check_permissions` exits non-zero *before* any flow runs, printing
  "Photos not granted: run `xcrun simctl privacy <udid> grant photos <bundle>`" —
  not a 30s selector timeout

#### Scenario: The device matrix accumulates provenance
- **GIVEN** `scripts/e2e.sh android smoke` passes on `emulator-5554` (API 35)
- **WHEN** `e2e_matrix` records the run
- **THEN** `test_fixtures/device_matrix.jsonl` gains one row naming the device, OS,
  surface, tier, pass/fail, and duration, so a later session can read the matrix
  instead of re-deriving it

### Requirement: The permission matrix is committed and surfaced-first

The repo SHALL commit `test_fixtures/permissions.md` naming, per surface and per
flow-group, which OS permissions are required and the exact command or API to grant
each (simctl privacy grant, Maestro `assertPermissions`, Patrol `grantPermission`,
CI entitlement). The matrix SHALL be the authority the `e2e_check_permissions` tool
reads. A flow-group that needs no permission SHALL say so explicitly ("none") rather
than leaving the cell blank — absence of evidence is not evidence of absence.

#### Scenario: Every flow-group names its permissions
- **GIVEN** the `video-import` flow-group
- **WHEN** `test_fixtures/permissions.md` is read
- **THEN** it lists Photos (required, grant command) and Microphone (none) explicitly

### Requirement: Rollout is gradual, gated, and honest about what it did not prove

The rollout SHALL be four phases, each a tier in `scripts/e2e.sh`, each gating the
next: **Phase 0** parse/lint (device-free: every flow file parses, every dataset's
counts validate, media hashes match — the cheapest gate, runs in CI); **Phase 1**
web smoke (desktop + mobile-chromium); **Phase 2** device smoke (iOS sim + Android
emulator); **Phase 3** full matrix (all surfaces, all datasets, matrix media); **Phase
4** owner physical device. Each phase SHALL print, verbatim, the `NOT PROVEN:` lines
for its scope. At least these SHALL be NOT PROVEN in CI: Phase 4 (physical device —
owner only), the `cloud` tier (live Appwrite/GDrive — behind the user gate), real
OAuth/payments webview (behind the user gate), and any flow that needs a network the
CI runner cannot assume.

#### Scenario: Phase 0 gates everything and runs with no device
- **GIVEN** a malformed Maestro flow and a dataset whose counts are wrong
- **WHEN** `scripts/e2e.sh` (Phase 0) runs in CI
- **THEN** it exits non-zero naming the unparseable flow and the miscounted dataset,
  and it does so without booting a simulator or a browser

#### Scenario: A phase cannot be skipped
- **GIVEN** Phase 1 (web smoke) is red
- **WHEN** `scripts/e2e.sh ios smoke` (Phase 2) is invoked
- **THEN** it refuses and prints "gate: web smoke not green — fix Phase 1 before
  Phase 2"

#### Scenario: NOT PROVEN lines print verbatim
- **GIVEN** `scripts/e2e.sh web smoke` runs green
- **WHEN** it finishes
- **THEN** it prints, verbatim, at least: "NOT PROVEN: physical device, live
  Appwrite/GDrive sync, real OAuth, payments webview, network-dependent flows" — so a
  green run never implies it proved what it did not

### Requirement: Flows select by the Face-Law selector contract

Every E2E flow SHALL select elements by semantic label or `AppIcon` id (the
Face-Law-stable contract), never by visible text, never by pack-resolved `IconData`,
never by a hardcoded pixel coordinate. The `test/helpers/icon_finders.dart` pattern
(`find.byWidgetPredicate((w) => w is AppIconView && w.icon == icon)`) SHALL be the
canonical icon selector; text SHALL be asserted only where Face-Law designates a
text surface (settings, input). This is what makes a flow survive a pack swap or a
copy change without a spurious red.

#### Scenario: A pack swap does not red the suite
- **GIVEN** the icon pack is changed (material ↔ lucide)
- **WHEN** the smoke tier runs
- **THEN** every flow still resolves its selectors and exits 0 — flows select the
  semantic `AppIcon`, not the resolved `IconData`

### Requirement: Gates print what they did not prove

`scripts/e2e.sh` SHALL be a gate in the root `verify.sh` suite (wired as
`scripts/verify_e2e.sh`, invoked by `verify.sh`). It SHALL run Phase 0 on every
invocation and the tier named by `E2E_TIER` (default `smoke`) on `E2E_SURFACE` (default
`web`). It SHALL print explicit `NOT PROVEN:` lines for every leg it did *not* run
(this invocation), and it SHALL exit non-zero if any status code, count assertion,
media hash, parse check, or permission pre-check fails. A green run is a claim about
exactly the listed layers, nothing more.

#### Scenario: verify.sh runs the E2E gate
- **GIVEN** a clean checkout
- **WHEN** `./verify.sh` runs
- **THEN** it invokes `scripts/verify_e2e.sh`, which runs Phase 0 + `web smoke`,
  prints the NOT PROVEN lines, and contributes its pass/fail to the cumulative result

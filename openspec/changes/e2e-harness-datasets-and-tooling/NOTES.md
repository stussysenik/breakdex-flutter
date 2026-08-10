# NOTES: E2E harness, datasets, and tooling

## N1 — what "figured out" means here, and what it does not

The framing question was: *can we run a full E2E suite simulating real use and roll it
out gradually?* Answer: **the single-surface, unit-level case is** (1000+ tests, green);
**multi-surface E2E is not, and this change makes it figured out on loopback + local
simulators/emulators.** Specifically:

- **Surfaces.** Nothing today proves the product on web (the #1 surface), iOS, or a
  physical device. This change gives `scripts/e2e.sh` a ranked web→ios→android→device
  ladder with web first.
- **Datasets & media.** The existing fixture service seeds rows but not countable,
  seed-stable profiles, and the only media are three ~32KB near-identical clips. This
  change makes datasets countable + deterministic and adds a ffmpeg-generated media
  family.
- **Tooling + honesty.** No tooling exists to list, diff, matrix-record, or
  permission-precheck, and no rollout ladder gates phase-on-phase with honest NOT
  PROVEN lines. This change adds both.

What stays **NOT PROVEN** (and is honest to name): physical-device runs (Phase 4 —
owner only), live Appwrite/GDrive sync (`cloud` tier — behind the user gate), real
OAuth/payments webview (behind the user gate), network-dependent flows on a locked-down
CI runner, and video export fidelity on a real GPU. Local multi-surface is the
complete deliverable.

## N2 — why web leads the ladder (loss-function portability, not convenience)

The loss function ranks **portability** first: "one codebase reaches web, iOS, Android;
a solution that works on one surface and degrades *invisibly* on another loses."
Web is ranked the #1 product surface ("Flutter Web = the released consumer app"). A
harness that starts on Android (as `android-e2e` did) inverts the ranking: it proves the
least-shipped surface first and leaves the product surface unproven. This change leads
with web so the fastest, cheapest feedback guards the surface the user actually ships,
and a broken home screen fails on web *before* any device boots. The Playwright `WebDriver`
seam means the same GIVEN/WHEN/THEN runs on desktop and iPad — only the viewport changes.

## N3 — countable datasets are the regression guard for "don't lose data"

The user named it: features should be "countable" and it should be "easy for the user
to not lose data." Presence checks ("a move renders somewhere") pass while a dropped
row silently ships. Countable profiles turn "did it render?" into "does the due-now
count equal the documented 7?" — a regression that drops, duplicates, or mis-dues a row
fails the assertion by number. Seed stability (seeded RNG + `now - offset` timestamps)
makes a failure reproducible and bisectable: re-seed with the same seed, get the same
state, watch the count mismatch. This is the mechanical enforcement of "don't lose data."

## N4 — relation to `android-e2e` (absorption, not duplication)

`android-e2e` is a narrow Android slice. Its shipped half (6.1 argent resolved, 6.2
`scripts/android_smoke.sh`) stays as-is and is *referenced*, not duplicated. Its
surviving legs (6.3 flow re-validation, 6.4 device matrix, 6.5 device gate) are
**absorbed** into this change's multi-surface posture — that's why task 5 re-validates
the 46 flows against the Face-Law surface and task 6 records the matrix. Per the
supersession rule, `android-e2e` archives as shipped-half with a note naming this
change as the absorber, in the same commit that lands task 7. Its D5 findings (the app
had never rendered; flows had version-drilled; selectors were stale) are the *why* of
this change and are preserved here, not re-derived.

## N5 — why ffmpeg-generated media, not downloaded clips

Fixture media must be (a) deterministic (re-running yields byte-identical bytes, so a
test that passes on clip X passes on the *same* clip X everywhere), (b) varied (a
32KB clip cannot exercise a trim path, a 1080p decode, an orientation change, or an
audio track), and (c) license-clean (generated, not scraped). `ffmpeg` is the boring,
available tool (8.1.1 confirmed on this machine). Generating from a pinned seed with
params encoded in the filename gives all three. The three committed clips stay as the
smoke tier so `ffmpeg` is *not* a dependency of the fast path — CI smoke runs without
a generator.

## N6 — the permission matrix is a pre-check, not a retry

`android-e2e` D5 learned a 30s selector timeout is the costly failure mode: a flow
waits for an element that never appears because a permission dialog blocked it. The
fix is not a longer timeout — it's a *pre-check* that runs before any flow, reads the
committed permission matrix, and fails fast with the exact grant command. This turns a
30s mystery into a 200ms named fix. The matrix is committed (not generated) so it is
reviewable and a missing row is itself a spec gap.

## N7 — pre-foreseen bottlenecks (so the next session does not re-derive them)

1. **Patrol needs a real `integration_test/` harness + a `nativeAutomator`.** The
   dependency is declared but no test exists; the first Patrol test is the hardest.
   Start with the Maestro-revalidation (task 5) and add Patrol only for the named
   un-drivable flows — do not author Patrol speculatively.
2. **Playwright drives the *released* web bundle.** A debug web build is faster to
   iterate but proves the wrong thing; the harness must build `flutter build web
   --release` first (41s compile, measured). The `webServer` config must serve that
   bundle, not a `flutter run` dev server.
3. **`flutter test integration_test` vs `patrol test` vs Maestro vs Playwright are
   four runners.** `scripts/e2e.sh` is the single entry point that dispatches to the
   right runner per surface — never ask the user to remember which runner runs where.
4. **ffmpeg must be present on the CI runner.** The smoke tier avoids it (committed
   clips), but the matrix tier needs it; `e2e_check_permissions` should treat a missing
   `ffmpeg` for the matrix tier like a missing permission — fail fast, named fix
   (`brew install ffmpeg` / apt equivalent).
5. **Seed stability demands no wall-clock in fixtures.** Any `DateTime.now()` absolute
   in a seeded profile breaks reproducibility. All timestamps MUST be `now - offset`
   relative to a single pinned `now` the profile receives as an argument. Grep for
   `DateTime.now()` in `automation_fixture_service.dart` as part of task 1.
6. **Maestro parses the *whole* `.maestro/` dir before filtering by tag.** One stale
   flow in an unrelated tier blocks the smoke run (learned in `android-e2e` D5). The
   parse gate (Phase 0) must run device-free before any device boot, and disabling a
   flow must use `.yaml.disabled` (parked, named) not silent deletion.

## N8 — the combo-page cleanup and "countable features" are *tested* here, not built

The user named two product asks: "the combo page is still a little bit messy" and
"make it easy for the user to not lose data / features should be countable." This
change is spec-only and tests features; it does not add them. But it *enables* them:
the `combo-lab` dataset profile and the combo-create web flow are the regression guard
a future combo-page cleanup implements against, and the countable-counts requirement is
the mechanical enforcement of "don't lose data." The actual combo-page cleanup and any
new feature should be captured as their own changes; this change gives them a harness
to prove themselves in. Do not expand this change to build them — that is scope growth
wearing an E2E costume.

## N9 — what "full E2E simulating real use" means, concretely

It means one command — `scripts/e2e.sh` — that, at the smoke tier, proves a real
person can: launch the app on the surface they actually use, see their seeded data
rendered (counted, not guessed), add a move from a video, complete a review session,
and create a combo — and trust that a dropped row, a stale selector, or a missing
permission fails the run *by name* before a human ever watches a screen. That is the
deliverable. Everything else (matrix media, full matrix, physical device, cloud) is a
later phase behind the user gate — valuable, honest about what it is not, and built to
be extended rather than rebuilt.

## Next unit

**Task 1 — dataset profiles.** The closed profile functions and their documented
counts. Pure, seed-stable, the foundation every flow asserts against. Read the spec
requirement "Datasets are countable, deterministic, and seed-stable" and its three
scenarios before writing; the `now` argument is what makes seed stability testable
without pinning the clock. Start by reading the existing `automation_fixture_service.dart`
stress fixture — its shape (`_stressMoves`, `_stressCombos`, …) is the model the new
profiles compose from, and its `DateTime.now()` calls are the first thing to replace
with `now - offset`.

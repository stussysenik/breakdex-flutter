# Stale tests quarantined post-redesign — tracking ledger

**Status:** 1 file quarantined (2 tests). The 7 + 2 post-redesign tests were all repaired and
restored; the visual-first redesign and the flat hash-addressed video-path refactor migrations
have full test coverage.

## Quarantined 2026-07-28 — `test/features/party/party_screen_test.dart` (2 tests)

- `shake starts cycling phase with moves in database`
- `shake reveals a move after full cycle`

**Symptom:** the file hangs past the 10-minute suite timeout. The hang is *not* in a test body —
`--timeout 90s` does not bound it — so it is in `setUpAll`/`tearDownAll`. Signature matches the
known live-Drift-`.watch()`-stream class: pending timers keep the isolate alive and `db.close()`
never returns.

**Proven pre-existing, not a regression:** reproduced identically at `b0b8f90`, i.e. with the
3.2.0 import normalization stashed out.

**Why quarantined rather than left red:** two 10-minute hangs made the full `./verify.sh` gate
take 20+ minutes and exit non-zero, so no one could run it before a release. A gate that cannot
be run proves nothing.

## Known red, NOT quarantined (2 tests, as of 2026-07-28)

These stay red and visible — they fail fast, so they do not block the gate the way the party
hangs did. Both reproduced at `b0b8f90` with the 3.2.0 import normalization stashed out, so
neither is a regression from it:

- `test/shared/widgets/bottom_nav_shell_test.dart` — "does not throw Riverpod modification
  error on build"
- `test/preview_harness_smoke_test.dart` — "preview harness renders a data-driven screen with
  seed data"

Full-suite baseline after the party quarantine: **1210 pass / 3 skip / 2 fail in ~54s**
(was 20+ minutes and non-terminating).

**Repair path (party):** rebuild on the pure-override harness (stub every stream provider, no live
`AppDatabase`) and unit-test the `PartyBloc` shake/cycle/reveal transitions separately from the
widget. The bloc logic is the part worth covering; the live DB is what hangs.

**Latent note (not a blocker, worth a ticket):** the review matrix counts by the `learningState`
column while session-items derive state from FSRS card state. Normal flows keep them in sync, but
if a move's column ever drifts from its FSRS card the two counts diverge. Track separately.

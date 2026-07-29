# add-stacked-viewport-layout

Archived 2026-07-29 as **implementation-complete**: 19/19 tasks, `./verify.sh` all gates
(1248 pass / 3 skip / 0 fail), `openspec --strict` green, capability promoted to
`openspec/specs/layout-system/`.

## Why it was worth doing

The app had tokens for every design *value* and no rule for **placement**. Five tabs used
three different header mechanisms plus two hand-rolled headers, and `lib/` had no maximum
content width at all — a defect on Flutter Web, the ranked-#1 surface. The drift was not
self-correcting: the owner had asked for consistent placement in a prior session and the
very next screen change introduced a fourth layout, because there was nothing to conform
to and no mechanism to conform with.

## What shipped

- `AppLayout` — band geometry, clamps, breakpoints, vertical rhythm, and the 2pt type
  baseline as named constants instead of per-file literals.
- `AppScreen` / `AppScreen.slivers` / `AppSection` — the frame as a **type**. Screens no
  longer build a `Scaffold`, `AppBar`, or `SliverAppBar`, so they cannot conform less than
  the frame. The FAB slot lives here too, carrying the nav-band inset five screens had each
  hand-rolled.
- All five tabs migrated: `add` (reference), `breakdex`, `stats`, `lab`, `flow`.
- Two CI gates that replace review: `test/design/frame_conformance_test.dart` (the roster)
  and `test/design/type_baseline_test.dart` (the scale).

## Rulings recorded here so they are not re-litigated

- **Type rides a 2pt baseline** (owner, 2026-07-29: "do multiples of 2"). The proposed snap
  of `titleMedium` 30→32 and `titleSmall` 26→28 did **not** happen; those steps were
  conforming to a rule nobody had written down. No screen's metrics moved.
- **`web-mirror/` is exempt from `AppLayout`.** It is the owner-only tool, not a product
  surface; value tokens still aim to mirror, the frame does not.
- **Pushed detail routes are deliberately not on the roster.** A back affordance and no nav
  band is a different placement problem; framing them is a separate change, not an oversight.

## What was NOT proven

Nothing was verified on a device or in a browser. The owner sitting — does the frame read as
one viewport when switching tabs, and does the clamp centre the column on a wide monitor —
is routed to `owner-verification-passes` §6.1.

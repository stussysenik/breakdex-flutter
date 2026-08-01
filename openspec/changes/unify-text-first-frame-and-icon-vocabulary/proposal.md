# Unify the Text-First Frame and the Icon Vocabulary

## Why

Owner asks, captured 2026-08-01 in one session (screenshots `SCR-20260801-mubx/muir/mujj/murf/muyo/mwee/mxjs`).
The through-line is one sentence in the owner's words: **"that's what I meant about the folding
rules being imprinted on top of each other"** — every screen should be the same frame with
different filling, so the app builds *expectation*, *functional parity*, and *absolute choice*.
A user who learns one screen has learned all of them.

The repo already decided this. `AppLayout` (2026-07-29) is a written layout constitution, and
`AppScreen` exists to enforce it. What it does not have is reach:

- **`AppScreen` binds 5 screens; 28 others build their own `Scaffold`/`AppBar`.** The frame
  conformance test (`test/design/frame_conformance_test.dart`) guards only the five that opted
  in, so the constitution is true where it is tested and fiction everywhere else. This is the
  drift `AppLayout`'s own doc comment calls a review violation.
- **Band 3 had no atom.** `AppLayout.rowHeight = 56` was declared and consumed by nothing. Each
  screen invented its own row — Add used a filled card, Settings uses grouped cards, Drill uses
  bare rows — so three screens presented the same kind of choice at three different weights.
  Parity cannot be asserted in prose; it needs a type.
- **Sheets are positioned against the raw viewport.** `SCR-20260801-mxjs` shows the "Plan a
  combo" sheet clipped by band 4 and running off-screen. Owner: *"unreliable reliance on the
  viewport … you need to be always calculating your own coordinates. Apple Native would have
  done this better."* The nav band is drawn over content (`extendBody: true`), so anything that
  assumes the viewport bottom is the safe bottom is wrong by `navBandHeight + padding.bottom`.
- **The icon vocabulary was platform-dependent and semantically stale.** Nav showed a grid for
  the catalogue (describing the *layout*, which stops being true when the layout changes) and a
  layers glyph for practice. Owner wants a **book** for Breakdex and a **dojo** for Review, and
  **Cupertino glyphs everywhere** so Android and web render the same vocabulary as iOS.
- **The default category set was 4 names in no stated order.** Owner supplied the canonical 8
  and their order; order is meaning, not alphabetics.
- **"Uncategorized" advertised an empty bucket** on a clean library.

## What Changes

- **`AppRow`** (`lib/shared/widgets/app_row.dart`) — the atom of band 3. One tappable line:
  label, optional value, optional leading, optional trailing control, `AppLayout.rowHeight`
  floor. Deliberately flat: no fill, no card, no elevation. A filled container makes a row read
  as a *thing* rather than a *choice*, and once one screen has cards and another has lines the
  parity is gone. Grouping is expressed by `AppSection` above it, never by decorating rows.
- **`CupertinoPack`** (`lib/core/design/icons.dart`) — a third exhaustive pack, and the new
  **default**. Flutter bundles `CupertinoIcons` as a font asset, so the glyphs are identical on
  Android and web rather than deferring to a host set. `IconPackId.fromKey` now falls to
  `cupertino` for unknown/absent keys.
- **Two semantic names**: `AppIcon.library` (the catalogue — a book) and `AppIcon.dojo` (where
  practice happens — the training floor, not the act of studying). Nav rewired to both.
- **Default categories** expanded to the owner's 8 in the owner's order.
- **Uncategorized** renders only when it holds something; its route stays reachable.
- **Deferred, specced here, not built**: the 28-screen migration, viewport-independent sheet
  positioning, the pre-seeded dev gallery, and the adjustable grid basis. See `tasks.md`.

## Impact

Additive. `AppRow` is new; the icon default changes what glyphs render but not what any name
means; the category list only grows and only affects clients that have not yet persisted one.
No data shape, no migration, no sync surface touched.

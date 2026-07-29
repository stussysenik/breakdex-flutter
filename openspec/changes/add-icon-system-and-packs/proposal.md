# Icon System and Swappable Packs

## Why

The owner's ask (captured 2026-07-28 as `redesign-visual-first-experience` 6.4): current
icons read generic; they should be handpicked, human, Notion-quality, and the set should be
swappable from the design system with packs selectable in Settings.

"Swappable" is not currently possible, and the reason is structural. The app has no icon
vocabulary at all — it has 434 direct references to Material glyph names:

| Surface | Raw `Icons.*` call sites | Files |
| --- | --- | --- |
| `lib/features` | 362 | 79 |
| `lib/shared` | 68 | 12 |
| `lib/core` | 4 | 1 |
| **Total** | **434** | **92** |

Every one of those names a *glyph*, not a *meaning*. There is nothing to point a second pack
at. A pack swap under the current shape means 434 hand edits, which is why it has never been
done and why nothing keeps the choices coherent in the meantime.

The incoherence is measurable, and it is the actual cause of "reads generic":

- **228 distinct glyphs** are referenced. For an app with five tabs, that is not a curated
  set — it is the absence of one.
- **148 of those 228 are used exactly once.** The tail is longer than the vocabulary. Each
  singleton is a per-screen decision made with no reference to the other 91 files.
- **51 are pure style-variant duplicates.** Collapsing `_rounded` / `_outlined` / `_sharp`
  suffixes leaves 177 base names, so the app renders `close` and `close_rounded`, `add` and
  `add_rounded`, `check_circle` and `check_circle_outline`, `chevron_right` and
  `chevron_right_rounded` in different places for the same meaning. That is stroke weight and
  terminal shape changing between two screens for no reason a user could name.

This is the same failure the stacked-viewport constitution fixed for placement: a values
system with no rule for one axis, so each screen re-invents that axis independently, and
review does not catch it because there is nothing to conform to. The answer here is the same
shape — make the vocabulary a *type*, not a convention, so the compiler enforces what review
has not.

## What Changes

- **`AppIcon`** (`lib/core/design/icons.dart`) becomes the app's icon vocabulary: a closed
  enum of curated *semantic* names (`AppIcon.add`, `AppIcon.back`, `AppIcon.move`), targeting
  **≤ 80 names** down from 228 glyphs. Screens name meanings; they no longer name glyphs.
- **`IconPack`** resolves an `AppIcon` to an `IconData` through an **exhaustive `switch` with
  no `default`**. Dart's exhaustiveness check therefore makes an incomplete pack a *compile
  error*: a pack cannot ship missing an icon, and adding a vocabulary entry cannot silently
  leave a pack behind. Completeness is proven by the compiler, not asserted in review.
- **Two packs ship.** `material` is the default and preserves today's glyph for each semantic
  name, so the swap is value-preserving except where two variants deliberately collapse to
  one name (enumerated in a ledger). `lucide` (`lucide_icons_flutter`, MIT) is the second —
  the hand-drawn, even-stroke family that the "human, Notion-quality" ask points at.
- **The pack is a `ThemeExtension`**, built in `theme.dart` from an `iconPackProvider` that
  persists to `SharedPreferences` exactly as `fontFamilyProvider` and `accentColorProvider`
  already do. Switching packs re-themes the whole app with no per-widget wiring.
- **A Settings section** surfaces pack selection with a live preview of the vocabulary,
  riding the `settingsSectionPage` route type that 6.3 landed.
- **A conformance gate** — `test/core/design/icon_conformance_test.dart`, modelled on
  `frame_conformance_test.dart` — fails on any raw `Icons.` in migrated directories, against
  a ledger that shrinks to empty. Once empty, the gate is absolute.
- **`docs/design/TOKENS.md` gains an Iconography section**: the vocabulary, the pack roster,
  the collapse ledger. **`CLAUDE.md` gains an icon row** to the doctrine table, putting raw
  `Icons.` on the same footing as raw `Duration`/`Curve` literals.

## Capabilities

### New

- `icon-system`: the contract for how the app names icons, how a pack resolves them, what a
  pack must guarantee, and what conformance means at review time.

## Footprint estimate

| Surface | Current | Target |
| --- | --- | --- |
| `lib/core/design/icons.dart` | absent | 1 file, ~340 LOC (enum ~80, two pack switches, `ThemeExtension`) |
| Distinct icon identifiers referenced by product code | 228 glyph names | ≤ 80 semantic names |
| Raw `Icons.*` in `lib/features` + `lib/shared` | 430 sites / 91 files | 0 |
| Raw `Icons.*` in `lib/core` | 4 sites / 1 file | 0 |
| Icon packs available | 1 (implicit) | 2 (`material`, `lucide`) |
| New runtime dependencies | — | 1 (`lucide_icons_flutter`, MIT) |
| Icon tests | 0 | 3 (conformance sweep, pack parity, Settings switch) |
| New ARB keys | — | ~6 |
| Migrated files per task | — | ≤ 12, one directory per commit |

Per-file migration is mechanical (`Icons.x` → `AppIcon.y`); the review cost sits in the
curation table, not the sweep.

## Non-goals

- **Not a commissioned icon set.** The owner said the target quality is worth paying for.
  Buying or drawing a bespoke family is a purchasing decision, not a code change; this change
  builds the socket that a purchased set plugs into as a third pack. Shipping a paid set is
  not blocked by it and not attempted here.
- **Not a third pack.** Phosphor's six weights (thin→fill) are attractive and land naturally
  next to 6.5's light→bold color weights and 6.6's typography axis — but a third pack triples
  the curation table before either of the first two has been seen on a device. Two packs
  prove swappability; the third is a mapping exercise once the vocabulary has settled.
- **Not color or typography.** 6.5 (Pantone color packs) and 6.6 (typography control) are
  separate Teacher passes. This change does not touch `AppColors` or `AppTypography`.
- **Not icon animation.** `AppMotion` owns motion; an animated-icon family
  (`not_static_icons`, `flutter_lucide_animated`) is a later question and would compose over
  this vocabulary rather than replace it.
- **Not `web-mirror/`.** The React dev surface is exempt, as it is from the layout frame.

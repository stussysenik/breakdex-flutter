# Design

## The rule the owner is actually stating

"Folding rules imprinted on top of each other" is a claim about **invariance under content
change**. Bands 1, 2 and 4 are fixed; band 3 varies. The failure mode is not that a screen
looks different — it is that a screen *is built differently*, so it drifts the next time
either screen changes. Prose lost to the very next screen change once already
(`feedback_design_rules_need_mechanisms`, 2026-07-29). So each rule below ships as a **type or
a test**, never as a paragraph.

| Rule | Mechanism | Status |
|---|---|---|
| Bands 1/2/4 identical | `AppScreen` | exists, 5 of 33 screens |
| Section rhythm | `AppSection` | exists |
| Row is a line, not a card | `AppRow` | **new, this change** |
| Icon names are platform-independent | `CupertinoPack` default + exhaustive `switch` | **new, this change** |
| No screen builds its own chrome | `frame_conformance_test.dart` | exists, allowlist grows per migration |
| Overlays respect band 4 | `AppSheet` | **deferred — task 3** |
| Grid basis is adjustable | `AppLayout` → runtime-overridable | **deferred — task 5** |

## Why the row is flat

The owner's reference screens (Settings, Drill) print an uppercase section label and then a
list. The Add screen printed two filled cards and no label, and that alone made it read as a
different kind of page. Two candidate fixes:

1. Give every screen cards. Rejected: a card is a container, and containers imply the thing
   inside is separable — true for a deck, false for "Move" as a choice of what to create.
2. Give every screen lines, and let `AppSection` do the grouping. **Chosen.** One decoration
   decision, made once, in the place that already owns vertical rhythm.

## Why Cupertino is the default rather than an iOS branch

A per-platform pack would reintroduce exactly the drift this change removes: the same semantic
name rendering as two different glyphs depending on where you opened the app, so a screenshot
from one device would not describe the other. `CupertinoIcons` ships as a bundled font, so
choosing it as the single default costs nothing on Android and buys one vocabulary everywhere.

Three names have no exact Cupertino glyph (`videoOff`, `dojo`, `move`). Each resolves to the
nearest honest analogue with the collapse noted inline — a wrong-but-close glyph beats a
missing one, and a recorded collapse beats a hidden one.

## Why the viewport bug is a coordinates bug, not a padding bug

`AppScreen` already insets its own scroll view and FAB by `navBandHeight + padding.bottom`.
Anything that does **not** route through `AppScreen` — `showModalBottomSheet`, `showDialog`,
the combo-plan sheet — measures against the raw viewport and lands under band 4. Adding
padding at each call site is the version that rots; the fix is one `AppSheet` helper that owns
the computation, mirroring how `AppScreen` owns it for screens.

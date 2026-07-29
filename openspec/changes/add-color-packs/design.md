# Design — Color Packs

## D1. A pack produces both halves of the theme

Color in this app already lives in two places, and a pack that owns only one of them is not a
pack:

- **Surfaces** come from `ColorScheme` (`bg`, `card`, `fill`, `text`, `secondary`,
  `separator`, driven today by the `AppColors.light*`/`dark*` constants).
- **Product signals** come from `AppSemanticTheme` — the three learning states, the four
  review ratings, `ink`, and `isMonoOutline`.

So `ColorPack` is defined as `(Brightness) → (ColorScheme, AppSemanticTheme)`. It **extends
`AppSemanticTheme` rather than adding a second extension beside it**: a parallel extension
would leave two sources for "what color is the mastery state", which is the exact class of
drift this change exists to remove.

Resolution is a `switch` over the closed role vocabulary with no `default`, so a pack missing
a role fails `flutter analyze` rather than rendering a fallback — identical to D1 of
`add-icon-system-and-packs`, and for identical reasons.

## D2. Seeds and a derived ramp, not 38 hexes

The ask is "light→bold weights, fluid and organic rather than hard statements." A pack
declared as 38 independent hexes cannot be fluid: nothing constrains its members to belong to
each other, which is precisely why the current palette reads as minimal-but-not-sophisticated.

A pack therefore declares a **small seed set** and derives its weight ramp. Derivation is in
**OKLCH**, not HSL:

- Equal lightness steps in HSL are not equal *perceived* steps — a yellow and a blue at the
  same HSL lightness differ enormously in apparent brightness, which is what makes hand-tuned
  palettes necessary and generated ones look cheap.
- OKLCH is perceptually uniform, so one ramp definition produces steps that read as evenly
  spaced across every hue in the pack. That uniformity *is* the "organic" quality being asked
  for; it is not decoration.
- It also makes contrast predictable: the ramp step that clears 4.5:1 against a surface is
  the same step for every hue, so the accessibility check in D3 is a property of the ramp
  rather than a per-color accident.

Conversion is sRGB ↔ OKLab ↔ OKLCH — about 40 lines of arithmetic. **No package is added**;
a dependency for two matrix multiplies and a cube root fails the essentialist bar, and the
math is stable and testable in isolation.

`AppColors` is not deleted. It becomes the seed data for the `classic` pack, so today's
palette is expressible in the new vocabulary — the proof that the vocabulary is adequate.

## D3. Three axes, and the accessibility overlay always wins

`pack`, `brightness`, and `AccessiblePalette` are orthogonal, and their precedence is fixed:

```
pack → brightness → AccessiblePalette overlay   (overlay is last, and wins)
```

`AccessiblePalette` (`standard` · `deuteranopia` · `monochrome`) and
`accessible_palette_test.dart` are already shipped and gated. Without an explicit precedence
rule, a color-pack feature is a silent regression of that work: a user on `deuteranopia`
picks an attractive pack and quietly loses the Okabe–Ito guarantee that its whole purpose is
to provide. Ordering the overlay last makes that structurally impossible.

Concretely: on `deuteranopia` the pack still supplies surfaces and accent, and the overlay
replaces the seven signal colors. On `monochrome` the overlay collapses signals to ink and
takes the grayscale surface ramp, so pack selection has no visible effect — correct, and
worth stating in the UI rather than leaving the user to discover that their choice did
nothing.

The existing non-destructive property extends unchanged: selecting an accessible palette
never erases the stored pack or its per-role overrides; they return exactly when the user
sets the palette back to `standard`.

## D4. Pantone — what is actually being asked, and what can be shipped

The ask names Pantone specifically: adjust any color, pick by season, choose from the full
database including every past Color of the Year.

Two of those three are pure mechanism and ship here without qualification: per-role
adjustment (D5) and a catalogue organised into named, seasonal collections with a
year-indexed lineage.

The third is not a mechanism. **PANTONE® is a registered trademark, and the Matching System's
color names, numbers, and their sRGB translations are licensed intellectual property** —
Pantone licenses it commercially and has withdrawn free access from major design tools.
Bundling the database into a paid app is a licensing and legal decision, not a code change.

The design does not resolve that; it makes it a decision the owner can take late:

- **Path A — license.** The catalogue is a data source behind an interface. A licensed
  Pantone dataset drops in as one more source with no change to the pack mechanism.
- **Path B (default, unblocks the work) — in-house curated collections.** Seasonal
  collections and a year-indexed "color of the year" lineage are shipped as our own curated
  palettes. Individual sRGB values that happen to coincide with published colors are not the
  exposure; the trademarked *names, numbers, and the wordmark as a product feature* are. So
  Path B ships the shape of the ask without the wordmark.

Path B is the specified default so that the work is not blocked on a purchase. Path A is one
owner-gated task. **Whichever path is taken, the pack mechanism is unchanged** — which is the
point of separating them.

## D5. Adjustment, contrast, and who decides

"Adjust any color" and the accessible-palette gate pull in opposite directions. Three options
were considered:

1. **Accept any adjustment silently.** Rejected — it lets a user render their own app
   unreadable with no signal, and it quietly invalidates the shipped contrast gate.
2. **Block adjustments that fail contrast.** Rejected — it overrides an explicit owner ask
   with a machine's judgement, and WCAG thresholds are a floor for legibility, not a
   universal aesthetic rule.
3. **Accept, but show the failure at the moment it is made.** Chosen. The picker displays the
   live contrast ratio and its pass/fail against the role's threshold as the color changes.
   The user is informed, and the decision stays theirs.

The distinction that makes option 3 safe: **shipped packs must pass; user overrides need only
be shown.** A pack we ship failing contrast is our defect and is gated in CI. A user's own
override failing is their informed choice on their own device.

## D6. What is not decided here

- **The palettes themselves.** This change ships the mechanism plus `classic` and `mono` —
  both re-expressions of shipped data. The *new* handpicked family the owner wants is a
  design pass, and designing it before the ramp exists means hand-tuning hexes that the ramp
  would have generated.
- **Whether `tokens.css` mirrors the packs.** The standing tokens ruling defers codegen until
  a third consumer; `web-mirror/` conformance stays a review item.
- **Ramp step count.** Falls out of the first real pack. The mechanism is indifferent; the
  test asserts monotonic lightness and stable hue, not a specific count.

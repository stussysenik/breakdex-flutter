# Add Design-System Showcase Page — Design

## Product Contract

The design system is specified in `docs/design/TOKENS.md` but not *legible at a glance*.
This page makes it legible: one surface that composites every token category into a dense,
grid-based layout a person can read in one sitting and sign off for general rollout.

The page is a **live conformance proof**, not a gallery of screenshots. Every sample
renders from the real token constants, so a token value drifting from its preview is
immediately visible.

## Layout Doctrine — Least Eye-Travel

The dominant design constraint is **minimum eye-travel distance**: the distance between
a token's label, its value, and its live preview must be as small as possible so the eye
never drifts across whitespace to connect them. This drives every layout decision:

1. **Inline triples.** Each token renders as `[name | value | preview]` on one row —
   label, code value, and live swatch/card adjacent, not in separate sections.
2. **Dense grid over stacked list.** Tokens of a category tile in a `Wrap`/`GridView`
   keyed to the 8pt block grid, not a vertical list of hero samples. More tokens per
   viewport = less scroll, shorter saccades.
3. **Neighboring categories.** Related regions (color↔shadow, spacing↔radius,
   typography↔depth) sit adjacent so cross-referencing doesn't traverse the page.
4. **One scroll axis.** A single `Column` in `AppScreen` (column form). No tabs, no
   nested scrollers, no carousels — Face Law's one-scroll rule, because interfaces here
   are *read*.
5. **Fixed reading clamp.** Content respects `maxContentWidth` (720) for the reading
   regions and `maxWideWidth` (1080) for the dense color grid.

## Page Composition (top → bottom)

A fixed **variant rail** (band-like, sticky) lets the reader flip brightness ×
accessibility palette without losing scroll position. Below it, regions in eye-travel
order:

| Order | Region | What it composites | Eye-travel logic |
| --- | --- | --- | --- |
| 1 | Color | All 17 `AppColorRole`s × 3 palettes × both brightnesses as inline `[role \| hex \| swatch]` tiles; learning states + review actions as pill triples | Largest region → gets the most viewport; grid keeps saccades short |
| 2 | Typography | Full `AppTypography` scale + 5 font families as `[style \| size/weight \| sample]` rows | Reading-ink lives here, next to color (they share surfaces) |
| 3 | Spacing + Radius | `AppSpacing` + `AppRadius` as adjacent `[name \| value \| visualized-gap/shape]` rows | Spacing and radius both size elements → neighbors |
| 4 | Depth + Shadows | `AppDepth` levels + `AppShadows` as `[level \| params \| raised-card]` triples | Depth and shadows both lift surfaces → neighbors |
| 5 | Layout | The four-band frame diagram + `AppLayout` constants as a labeled diagram + `[token \| value \| callout]` table | The frame is the container for everything above → placed after its contents |
| 6 | Motion | Fluid + Morph families, all durations + curves as `[token \| value \| animated-sample]` rows with a replay affordance | Motion is temporal, separate from static regions |

## Live Token Render

Every sample resolves from the runtime constant, never a hardcoded duplicate:

- Color swatches → `AppColorRole` resolved through the active pack + brightness + overlay.
- Type samples → `AppTypography.*` text styles.
- Spacing/radius → `AppSpacing.*` / `AppRadius.*` visualized as gaps and shapes.
- Depth/shadows → `AppDepth.*` + `AppShadows.*` on raised cards.
- Motion → `AppMotion.*` curves/durations driving a tiny animated sample with replay.

A sample whose rendered value no longer matches its row is a visible conformance failure.

## Three-Version Rollout Matrix

The variant rail toggles the axes the rollout signs off:

- **Brightness:** light / dark (existing `Brightness` axis).
- **Accessibility palette:** standard / deuteranopia / monochrome (existing
  `AccessiblePalette`, the overlay that wins).

The page renders the full color region under the selected combination so the owner can
verify every palette × brightness in place. All three palettes are sign-off-able without
leaving the page — that is what "ready for general rollout" is answered against.

## Conformance

- The page is an `AppScreen` (Face Law rule 1) — column form, with `AppScreen.slivers`
  only if the color grid needs laziness (it does not at current token counts).
- No raw literals: every dimension resolves from `AppLayout`/`AppSpacing`, every color
  from the role system, every motion from `AppMotion`. A raw value here would defeat the
  page's purpose (it would be showcasing itself incorrectly).
- One primary action per content band (Face Law rule 2): the variant rail is the one
  control; regions are read-only.

## Acceptance Criteria

- Every TOKENS.md category is represented by live-rendered samples.
- The variant rail flips brightness × palette and re-renders the color region in place.
- No raw color/spacing/radius/duration/curve literal appears in the feature.
- The page is reachable on web, one scroll axis, readable in a single sitting.

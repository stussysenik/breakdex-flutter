# Add Design-System Showcase Page

> **Language: Dart (Flutter Web, the #1 product surface).** Depends on:
> `enforce-face-law-conformance` (Face Law + AppScreen), `add-color-packs`,
> `add-icon-system-and-packs`. Implementation in a fresh student session — never this
> one.

## Why

The design system is now fully specified in `docs/design/TOKENS.md` — color (17 roles,
3 accessibility palettes, swappable packs, OKLCH weight derivation), spacing (8pt grid),
layout (the four-band stacked viewport), radius, motion (Fluid + Morph families),
typography (Inter scale + 5 alternates), depth (z-index + 5 levels), and shadows. But
the rules live in a Markdown reference, not in a surface a person can *read at a glance*
and confirm "all three versions are ready for general rollout."

A single showcase page that composites every token category into one layout closes that
gap. Its job is to make the whole design system legible in one sitting — a reference
the owner uses to sign off on a release and a live spec the implementation must match.

The layout is optimized for **least eye-travel distance**: every token's name, value, and
live preview are adjacent on a dense grid, so the eye never drifts across whitespace to
connect a label to what it describes. Related categories sit in neighboring regions; the
page reads as one composition, not a tour of nine separate demos. This is a *reading*
interface (Face Law's one-scroll rule): dense, scannable, one axis.

## What Changes

- **One showcase `AppScreen`.** A single scrollable surface that composites every
  TOKENS.md category — color, spacing, layout, radius, motion, typography, depth,
  shadows — into a dense, grid-based reference layout.
- **Live, not screenshots.** Every swatch, sample, and sample-card renders from the real
  token constants (`AppColors`, `AppSpacing`, `AppLayout`, `AppRadius`, `AppMotion`,
  `AppTypography`, `AppDepth`, `AppShadows`), so the page is a live conformance proof —
  a token value drifts from its rendered preview the moment someone edits the constant.
- **Three-version rollout matrix.** The page demonstrates the design system across its
  variant axes (brightness × accessibility palette) so the whole surface is signed off
  in one view, not three.
- **Web-first.** Ships to Flutter Web (the released consumer app); mobile surfaces read
  the same tokens but this *reference* layout is a web reading surface.

## Capabilities

1. `composite-showcase-layout` — one page, all token categories, dense grid, one scroll
   axis, least eye-travel.
2. `live-token-render` — every sample renders from real token constants (live
   conformance proof, not static screenshots).
3. `rollout-variant-matrix` — demonstrates brightness × accessibility-palette variants
   so the whole system is sign-off-able in one view.

## Footprint estimate

| Surface | Current → Target | Notes |
| --- | --- | --- |
| `lib/features/design_showcase/` | new feature, ~320 LOC | one `AppScreen` + region widgets |
| `lib/features/design_showcase/data/` | +token sample model, ~60 LOC | which tokens to render where |
| `test/` | +showcase render + variant tests, ~100 LOC | mounts under every variant |

Net: ~480 LOC, +2–3 files. No new tokens; it *reads* existing ones.

## Non-goals

- **No new design tokens.** This page renders the existing system; it does not extend
  TOKENS.md.
- **No interactive token editor.** Editing roles/packs lives in Settings; the showcase
  is read-only reference.
- **Not a replacement for TOKENS.md.** The Markdown stays the single source; the
  showcase is a live view of it.
- **No mobile-specific showcase surface.** Mobile reads the same tokens; this dense
  reference layout is a web reading surface only.

# Color Packs

## Why

The owner's ask (captured 2026-07-28 as `redesign-visual-first-experience` 6.5): the palette
is "minimal but not sophisticated"; wanted are better colors designed from **light→bold
weights**, "fluid and organic rather than hard statements" — Linear's philosophy, simple
handpicked colors. Packs should be **Pantone-only**: adjust any color, pick by season, and
choose from the full database including every past Color of the Year.
`docs/design/TOKENS.md` stays the single source.

Today, color in this app is 38 `const Color` literals in a 58-line `AppColors` plus exactly
four user-adjustable values (`accentColorProvider`, three learning-state colors), each
persisted independently. There is no notion of a *set*. The consequences are specific:

- **Surfaces are unreachable.** `lightBg`/`lightCard`/`lightFill`/`lightText`/`lightSecondary`
  /`lightSeparator` and their dark twins are compile-time constants. The parts of the screen
  that carry most of the pixels cannot be changed at all, so "better colors" is currently
  impossible to express.
- **The four adjustable values move independently.** A user can set an accent that has no
  relationship to the three state colors, because nothing relates them. That is the opposite
  of a handpicked set, and it is why the result reads as *minimal* (few colors) without
  reading as *sophisticated* (colors that belong together).
- **There is no weight axis.** Every token is one fixed lightness. "Light→bold weights" has
  nowhere to live: a pack that wants a soft tint and an emphatic statement of the same hue
  must hard-code two unrelated hexes.
- **The existing accessible-palette work would be silently defeated** by any free-form color
  feature. `AccessiblePalette` (`standard` / `deuteranopia` / `monochrome`) and
  `accessible_palette_test.dart` are already shipped and gated; a pack system that ignores
  them is a regression dressed as a feature.

The mechanism this needs is the one `add-icon-system-and-packs` establishes for icons: a
closed **role** vocabulary, packs that resolve it **exhaustively**, resolution through a
`ThemeExtension`, persisted preference, conformance gated by a test. This change applies that
same shape to color, and reuses the existing `AppSemanticTheme` extension rather than growing
a parallel one beside it.

## What Changes

- **`ColorPack`** (`lib/core/design/color_packs.dart`) becomes a function of brightness to a
  complete theme half: a `ColorScheme` for surfaces and an `AppSemanticTheme` for product
  signals. A pack resolves **every** role through a `switch` with no `default`, so an
  incomplete pack is a compile error rather than a rendered fallback (same guarantee as D1 of
  the icon change).
- **A pack is defined by seeds and a generated ramp, not by 38 hexes.** Each pack declares a
  small seed set and derives its **light→bold weight ramp** perceptually (OKLCH), which is
  what makes a pack read as one family rather than as a list of statements. `AppColors`
  becomes the `classic` pack's seed data rather than the app's only palette.
- **The three axes are made orthogonal and ordered**: `pack` chooses the family, `brightness`
  chooses light/dark, `AccessiblePalette` overlays a11y — and **the overlay always wins**.
  Selecting a beautiful pack can never defeat deuteranopia safety or monochrome mode.
- **Existing sets become packs.** `classic` (today's colors, byte-identical) and `mono`
  (today's `monoLight*`/`monoDark*` ramp) ship as packs on day one, so the abstraction is
  proven against shipped data before any new palette is designed.
- **Seasonal collections and a Color-of-the-Year lineage** are the pack *catalogue* shape the
  ask describes. Which data source backs that catalogue is an **owner-gated licensing
  decision** — see Non-goals and `design.md` D4. The mechanism does not depend on the answer.
- **Per-role adjustment survives, with contrast surfaced.** "Adjust any color" stays true;
  an adjustment that drops a text/background pair below its WCAG threshold is **shown as
  failing at the moment it is made**, not silently accepted and not silently blocked.
- **`docs/design/TOKENS.md` gains a Color Packs section** — the role vocabulary, the pack
  roster, the ramp derivation, and the axis-precedence rule.

## Capabilities

### New

- `color-system`: the contract for how color roles are named, how a pack resolves them, how
  the weight ramp is derived, how packs compose with the accessibility axis, and what
  conformance means at review time.

## Footprint estimate

| Surface | Current | Target |
| --- | --- | --- |
| `lib/core/design/colors.dart` | 58 LOC, 38 `const Color` | seed data for `classic` + `mono`, ~70 LOC |
| `lib/core/design/color_packs.dart` | absent | ~260 LOC (roles, `ColorPack`, ramp derivation, two packs) |
| User-adjustable color values | 4 (accent + 3 states) | full role vocabulary, per-pack overrides |
| Packs available | 0 (implicit single palette) | 2 shipped (`classic`, `mono`) + catalogue socket |
| Theme extensions | `AppSemanticTheme` | `AppSemanticTheme` (extended, not duplicated) |
| Color tests | 1 (`accessible_palette_test.dart`) | 4 (+ pack completeness, ramp monotonicity, axis precedence) |
| New runtime dependencies | — | 0 — OKLCH conversion is ~40 LOC, not a package |
| New ARB keys | — | ~8 |

## Non-goals

- **Not shipping a licensed Pantone database.** PANTONE® is a registered trademark and the
  Matching System's names, numbers, and sRGB translations are licensed IP; "the full database
  including every past Color of the Year" is a purchasing and legal decision, not an
  implementation detail. This change builds the catalogue socket and ships an in-house
  curated set through it. The licensing path is a single owner-gated task (`design.md` D4),
  and nothing here is blocked while it is open.
- **Not a repo-wide recolor.** `classic` is byte-identical to today. No screen changes
  appearance until a pack is selected.
- **Not iconography or typography.** 6.4 ships the icon vocabulary this change deliberately
  mirrors; 6.6 owns type. Neither is touched here.
- **Not remote-config-driven cohort palettes.** If invite cohorts later carry a default pack,
  that rides `add-web-first-release-and-monetization` Phase 1R, governed by the standing rule
  that a stored user preference is never overridden by a new default.
- **Not `web-mirror/`.** `tokens.css` conformance stays a review-checklist item; no codegen
  until a third consumer exists, per the standing tokens ruling.

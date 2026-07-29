# Stacked-Viewport Layout Constitution

## Why

The app has tokens for *values* — color, spacing, radius, motion, type, depth — and no rule
for **placement**. `docs/design/TOKENS.md` never had a Layout section. So every screen
composes its own frame, and the frames disagree:

| Screen | Header mechanism | Effective header height | Title style |
| --- | --- | --- | --- |
| `breakdex` | `Scaffold` + `AppBar` | 56 | theme `titleLarge` |
| `add` | `SliverAppBar.large` | 152 expanded | theme `titleLarge` |
| `stats` | `SliverAppBar` floating+snap | 56, collapsing | **overridden** to Menlo w900, uppercase |
| `lab` | none — hand-rolled header in a `CustomScrollView` | ad-hoc | ad-hoc |
| `flow` | none — hand-rolled header | ad-hoc | ad-hoc |

The horizontal gutter (`AppSpacing.screenEdge`) is the one invariant that *is* honored
everywhere. Vertically there is nothing: the content's first pixel lands at a different `y`
on every tab, and the title font changes between two of them. Switching tabs therefore reads
as arriving at a differently-built page rather than as the same viewport changing contents.

This is not cosmetic drift, and it is not self-correcting. It compounds: the owner asked for
consistent placement in a prior session, and the very next screen change (the Add tab's
choice cards) introduced a *new* fourth layout, because there was no rule to conform to and
no mechanism to conform with. Each screen is re-invented independently because independence
is the current default.

There is also no maximum content width anywhere in `lib/`. Flutter Web is the ranked-#1
product surface; an unclamped reading column on a wide monitor is a defect on the primary
platform.

## What Changes

- **A stacked-viewport model** replaces per-screen frames. Four bands; bands 1, 2 and 4
  (safe area · 72pt header · 56pt nav) are identical on every screen and never move. Only
  the content band varies. Content's first pixel is always at safe-area top + 80.
- **`AppLayout`** (`lib/core/design/layout.dart`) makes band geometry, the reading-width
  clamp, breakpoints, and vertical rhythm nameable constants instead of per-file literals.
- **`AppScreen` / `AppSection`** (`lib/shared/widgets/app_screen.dart`) make the frame a
  type rather than a convention. A screen cannot accidentally conform *less* than the frame,
  because it no longer builds the frame.
- **`docs/design/TOKENS.md` gains a Layout & Grid section** — the single source now covers
  placement, with a per-screen migration ledger.
- **CLAUDE.md gains a Layout doctrine row**, putting layout conformance on the same footing
  as the existing motion doctrine: raw layout literals are review violations exactly as raw
  `Duration`/`Curve` literals are.
- **The one-scroll rule** is written down: one scroll axis per screen, no nested scrollers,
  no content-hiding carousels or in-screen tabs.
- **Screens migrate as they are touched.** `add` is migrated here as the reference
  implementation; `breakdex`, `stats`, `lab`, `flow` carry ledger rows.

## Capabilities

### New

- `layout-system`: the contract for how every screen is framed, spaced, and clamped, and
  what conformance means at review time.

## Non-goals

- **Not an invasive sweep.** Four screens keep their current frames until a task touches
  them. A repo-wide relayout would touch every screen while the release queue waits, and
  would put unreviewed visual change on every surface at once.
- **Not a visual redesign.** Band geometry and rhythm only. Color, motion, iconography, and
  information architecture are unchanged; `redesign-visual-first-experience` owns those.
- **Not codegen.** Per the existing tokens ruling, CSS custom properties stay planned until
  a third consumer exists. `web-mirror/` is not retrofitted here.

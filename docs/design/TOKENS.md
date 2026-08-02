# Breakdex Design Tokens

> **Manual:** Indexed by the [Breakdex Engineering Manual](../manual/index.mdx) →
> [Design System](../manual/05-design-system.mdx). The manual links here and adds standards
> around these tokens; it never duplicates them. This file stays the single source.

> Single source of truth for design tokens. Dart constants in `lib/core/design/*.dart`
> are the canonical runtime values. CSS custom properties are planned for `web-mirror/`.

---

## Color Palette

| Token | Value | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|-------------|----------|
| `lightBg` | `#F8FAFC` | `AppColors.lightBg` | `--color-light-bg` (planned) | Theme light scaffold background |
| `lightCard` | `#FFFFFF` | `AppColors.lightCard` | `--color-light-card` (planned) | Surface, card backgrounds |
| `lightFill` | `#F1F5F9` | `AppColors.lightFill` | `--color-light-fill` (planned) | Input fills, container-highlight |
| `lightText` | `#0B0D12` | `AppColors.lightText` | `--color-light-text` (planned) | Primary text |
| `lightSecondary` | `#5A6272` | `AppColors.lightSecondary` | `--color-light-secondary` (planned) | Secondary text, hints |
| `lightSeparator` | `#D9E0EA` | `AppColors.lightSeparator` | `--color-light-separator` (planned) | Dividers, borders |
| `darkBg` | `#090B10` | `AppColors.darkBg` | `--color-dark-bg` (planned) | Theme dark scaffold background |
| `darkCard` | `#11141B` | `AppColors.darkCard` | `--color-dark-card` (planned) | Surface, card backgrounds |
| `darkFill` | `#1A1F29` | `AppColors.darkFill` | `--color-dark-fill` (planned) | Input fills, container-highlight |
| `darkText` | `#F7FAFF` | `AppColors.darkText` | `--color-dark-text` (planned) | Primary text |
| `darkSecondary` | `#A7B1C2` | `AppColors.darkSecondary` | `--color-dark-secondary` (planned) | Secondary text, hints |
| `darkSeparator` | `#283041` | `AppColors.darkSeparator` | `--color-dark-separator` (planned) | Dividers, borders |
| `accent` | `#1F5EFF` | `AppColors.accent` | `--color-accent` (planned) | Interactive elements, CTAs |
| `monoLightBg` | `#F7F7F7` | `AppColors.monoLightBg` | `--color-mono-light-bg` (planned) | Mono mode light background |
| `monoLightCard` | `#FFFFFF` | `AppColors.monoLightCard` | `--color-mono-light-card` (planned) | Mono mode light surface |
| `monoLightFill` | `#F0F0F0` | `AppColors.monoLightFill` | `--color-mono-light-fill` (planned) | Mono mode light fill |
| `monoLightText` | `#111111` | `AppColors.monoLightText` | `--color-mono-light-text` (planned) | Mono mode light text |
| `monoLightSecondary` | `#5F5F5F` | `AppColors.monoLightSecondary` | `--color-mono-light-secondary` (planned) | Mono mode light secondary |
| `monoLightSeparator` | `#111111` | `AppColors.monoLightSeparator` | `--color-mono-light-separator` (planned) | Mono mode light separator |
| `monoDarkBg` | `#090909` | `AppColors.monoDarkBg` | `--color-mono-dark-bg` (planned) | Mono mode dark background |
| `monoDarkCard` | `#111111` | `AppColors.monoDarkCard` | `--color-mono-dark-card` (planned) | Mono mode dark surface |
| `monoDarkFill` | `#181818` | `AppColors.monoDarkFill` | `--color-mono-dark-fill` (planned) | Mono mode dark fill |
| `monoDarkText` | `#F4F4F4` | `AppColors.monoDarkText` | `--color-mono-dark-text` (planned) | Mono mode dark text |
| `monoDarkSecondary` | `#B3B3B3` | `AppColors.monoDarkSecondary` | `--color-mono-dark-secondary` (planned) | Mono mode dark secondary |
| `monoDarkSeparator` | `#F4F4F4` | `AppColors.monoDarkSeparator` | `--color-mono-dark-separator` (planned) | Mono mode dark separator |

### Learning State Colors

| Token | Value | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|-------------|----------|
| `stateNew` | `#E45D7A` | `AppColors.stateNew` | `--color-state-new` (planned) | New learning state pill |
| `stateLearning` | `#2F6BFF` | `AppColors.stateLearning` | `--color-state-learning` (planned) | Learning state pill |
| `stateMastery` | `#1F8A70` | `AppColors.stateMastery` | `--color-state-mastery` (planned) | Mastery state pill |

### Review Action Colors

| Token | Value | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|-------------|----------|
| `actionAgain` | `#C23B2A` | `AppColors.actionAgain` | `--color-action-again` (planned) | Again rating button |
| `actionHard` | `#B7791F` | `AppColors.actionHard` | `--color-action-hard` (planned) | Hard rating button |
| `actionGood` | `#1F7A4F` | `AppColors.actionGood` | `--color-action-good` (planned) | Good rating button |
| `actionEasy` | `#0D9F9A` | `AppColors.actionEasy` | `--color-action-easy` (planned) | Easy rating button |

### Accessible Palettes

An orthogonal axis over theme/brightness/viewing-mode, selected by
`AccessiblePalette` (`standard` · `deuteranopia` · `monochrome`). Selection is
non-destructive — the user's accent/state/rating colors stay in prefs and return
exactly when the palette is set back to `standard`.

**Deuteranopia-safe ramp** — the Okabe–Ito palette, whose members stay mutually
distinguishable under red-green color-vision deficiency. Applied to the
app-controlled semantic signals (learning states + review ratings) only;
surfaces and accent are left untouched.

| Token | Value | Dart Constant | Consumers |
|-------|-------|---------------|----------|
| `deuterStateNew` | `#E69F00` | `AppColors.deuterStateNew` | New state (deuteranopia) |
| `deuterStateLearning` | `#0072B2` | `AppColors.deuterStateLearning` | Learning state (deuteranopia) |
| `deuterStateMastery` | `#009E73` | `AppColors.deuterStateMastery` | Mastery state (deuteranopia) |
| `deuterActionAgain` | `#D55E00` | `AppColors.deuterActionAgain` | Again rating (deuteranopia) |
| `deuterActionHard` | `#E69F00` | `AppColors.deuterActionHard` | Hard rating (deuteranopia) |
| `deuterActionGood` | `#009E73` | `AppColors.deuterActionGood` | Good rating (deuteranopia) |
| `deuterActionEasy` | `#0072B2` | `AppColors.deuterActionEasy` | Easy rating (deuteranopia) |

**Monochrome (non-stimulating)** — reuses the existing grayscale surface ramp
(`monoLight*` / `monoDark*`) for surfaces and collapses the semantic ramp + accent
to ink (`AppSemanticTheme.ink`). Distinct from the `monoOutline` "marker" render
style: surfaces stay **filled** (`isMonoOutline: false`), only color is removed.
Meaning survives via the icon/shape/label pairing on every color-carried signal
(rating icons + state/rating labels).

Color is never carried alone in any palette: rating buttons pair color with a
distinct icon **and** label (WCAG 1.4.1), state pills pair color with a label,
and category chips always render alongside the category name.

### Color Packs

A **pack** is the swappable answer to "what color is each role". The 39 constants
above are one pack's worth of data, not the vocabulary: `lightBg`, `darkBg`,
`monoLightBg`, and `monoDarkBg` are four *values* of a single role, resolved by
brightness and by the accessibility overlay.

**The role vocabulary is closed** — `AppColorRole` in `lib/core/design/color_roles.dart`,
17 roles. A pack resolves every one via an exhaustive `switch` with no `default`,
so a pack missing a role fails `flutter analyze` instead of rendering a fallback.
Each role carries an `AppColorRoleKind` naming which axis owns it.

| Role | Kind | Renders |
|------|------|---------|
| `background` | surface | `scaffoldBackgroundColor` |
| `card` | surface | `ColorScheme.surface`, cards, sheets, nav bar |
| `fill` | surface | `surfaceContainerHighest`, input fills |
| `separator` | surface | `ColorScheme.outline`, dividers, borders |
| `text` | ink | `onSurface`, primary reading ink |
| `secondaryText` | ink | `ColorScheme.secondary`, captions, hints |
| `accent` | ink | `ColorScheme.primary` — the one colored mark |
| `onAccent` | ink | `onPrimary`; not always white (grayscale modes tone the accent to ink) |
| `error` | signal | `ColorScheme.error` |
| `onError` | ink | `ColorScheme.onError` |
| `stateNew` · `stateLearning` · `stateMastery` | signal | `AppSemanticTheme` learning states |
| `actionAgain` · `actionHard` · `actionGood` · `actionEasy` | signal | `AppSemanticTheme` review ratings |

**Weights are derived, not listed.** A pack declares a small seed set; the weight
ramp comes from `rampFromSeed` in `lib/core/design/oklch.dart`. Derivation is in
OKLCH rather than HSL because equal HSL lightness is not equal *perceived*
lightness — yellow and blue at HSL `L 0.5` differ by more than 0.3 of the visible
lightness range, while at OKLCH `L 0.6` they differ by less than 0.01
(`oklch_test.dart`). One consequence is load-bearing: step *n* of any two hues is
the same weight, so a contrast threshold is a property of the ramp rather than a
per-color accident. Out-of-gamut steps **spend chroma, never hue** — channel
clipping rotates hue, which is the one thing a ramp promises to hold.

**Axis precedence — the overlay is applied last and wins:**

```
pack → brightness → AccessiblePalette overlay
```

Without that order a pack selection would silently defeat the shipped
`AccessiblePalette` guarantee: a user on `deuteranopia` picking an attractive
pack would quietly lose the Okabe–Ito ramp the palette exists to provide.
Concretely — on `deuteranopia` the pack still supplies surfaces and accent and
the overlay replaces the signal roles; on `monochrome` the overlay collapses
signals to ink and takes the grayscale surface ramp, so pack selection has no
visible effect. That last case is **stated in the interface**, not left for the
user to discover that their selection did nothing.

Selecting an overlay stays non-destructive: the stored pack and every per-role
override return unchanged when the palette goes back to `standard`.

**Shipped packs must pass contrast; user overrides need only be shown.** A pack
we ship failing a contrast threshold is our defect and is gated in CI across
every pack × both brightnesses. A per-role override failing is the user's
informed choice on their own device — the picker shows the live ratio and its
pass/fail as the color changes, accepts the value, and never blocks it.

**The vocabulary now reaches every pixel — enforced, not asserted.** Both gaps
this section used to list are closed: `ColorScheme.error` follows the overlay
(2.4), and the raw call sites are migrated (2.5). Reading an `AppColors`
constant outside the **definition layer** is now a test failure —
`test/core/design/color_conformance_test.dart`, the color twin of the icon ban.
Unlike icons the ban is not zero-allowlist, because colors *have* a definition
layer: a pack seeds its roles from constants and a preference provider falls
back to one. The allowlist admits files that **define what a role resolves to**
(`colors.dart`, `color_packs.dart`, `theme.dart`, `theme_providers.dart`, the
two default snapshots, and the category *picker palette*, whose values are
persisted user data rather than rendered theme). A widget never qualifies.

**Media chrome is a role read at the other brightness.** Video surfaces are dark
on purpose regardless of app brightness, which is why `AppColors.darkBg` read as
correct there for so long. `AppMediaChrome` (a `ThemeExtension`) resolves the
*active pack at `Brightness.dark`*, so the intent survives and the pixels return
to the theme: a pack owns its own dark side, and media chrome follows the pack
without ever following the app's light mode.

---

## Spacing

8pt base grid with 4pt half-step. All values in logical pixels.

| Token | Value | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|-------------|----------|
| `xxs` | 4 | `AppSpacing.xxs` | `--space-xxs` (planned) | Minimal gaps, icon padding |
| `xs` | 8 | `AppSpacing.xs` | `--space-xs` (planned) | Base unit, tight spacing |
| `sm` | 12 | `AppSpacing.sm` | `--space-sm` (planned) | Dense UI, small card padding |
| `md` | 16 | `AppSpacing.md` | `--space-md` (planned) | Content padding, card margins |
| `lg` | 24 | `AppSpacing.lg` | `--space-lg` (planned) | Section spacing |
| `xl` | 32 | `AppSpacing.xl` | `--space-xl` (planned) | Group spacing |
| `xxl` | 48 | `AppSpacing.xxl` | `--space-xxl` (planned) | Large section gaps |
| `xxxl` | 64 | `AppSpacing.xxxl` | `--space-xxxl` (planned) | Screen-level spacing |
| `screenEdge` | 24 | `AppSpacing.screenEdge` | `--space-screen-edge` (planned) | Screen horizontal padding |

---

## Layout & Grid

> **The stacked-viewport model.** Every screen is the *same frame* with different
> filling. You are never designing "a screen" — you are choosing what goes in the
> content band of the one viewport this app has. Switching views swaps the filling;
> the frame does not move. Dart source: `lib/core/design/layout.dart` (`AppLayout`).
> Enforcement: `AppScreen` (`lib/shared/widgets/app_screen.dart`).

### The four bands

```
┌──────────────────────────┐
│ safe area (system)       │  band 1 — system owned
├──────────────────────────┤
│ HEADER          [actions]│  band 2 — 72pt, title on a fixed baseline
├──────────────────────────┤
│                          │
│  content (scrolls)       │  band 3 — the ONLY band that varies
│                          │
├──────────────────────────┤
│ ◇  ◇  ◇  ◇               │  band 4 — 56pt, shell owned
└──────────────────────────┘
```

Bands 1, 2 and 4 are **identical on every screen and never move.** The content
band's first pixel therefore lands at the same `y` — safe-area top + 80 — on every
screen in the app, with no exceptions.

| Token | Value | Dart Constant | Rule |
|-------|-------|---------------|------|
| `headerHeight` | 72 | `AppLayout.headerHeight` | `titleLarge` line box (36) centred in 18/18. Fixed — no collapsing, floating, or `.large` headers. |
| `backSlot` | 48 | `AppLayout.backSlot` | Square slot for the back affordance, at the head of the title row on a screen that can pop. Clears the touch floor *and* lands on `blockGrid`; 16 + 4 + 48 = 68 still fits inside the unchanged `headerHeight`, so band 2 never grows to hold it. |
| `contentTopGap` | 8 | `AppLayout.contentTopGap` | Gap between header band and first content pixel. |
| `navBandHeight` | 56 | `AppLayout.navBandHeight` | Bottom nav. Rendered *over* content (`extendBody: true`). |
| `scrollBottomInset` | 72 | `AppLayout.scrollBottomInset` | Scroll padding so the last item clears the translucent nav band. |
| `gutter` | 24 | `AppLayout.gutter` | Left/right content edge. Mirrors `AppSpacing.screenEdge`. |
| `maxContentWidth` | 720 | `AppLayout.maxContentWidth` | Reading column clamp; centres above this. |
| `maxWideWidth` | 1080 | `AppLayout.maxWideWidth` | Dense grids/boards only — never reading content. |
| `dialogMaxWidth` | 480 | `AppLayout.dialogMaxWidth` | Box a dialog lays out in (`showAppDialog`); Material's 40pt gutter sits inside it, so the painted card is ≤400. |
| `breakpointCompact` | 600 | `AppLayout.breakpointCompact` | Below: single column. |
| `breakpointExpanded` | 1024 | `AppLayout.breakpointExpanded` | At/above: side-by-side regions allowed. |

### Vertical rhythm

| Token | Value | Dart Constant | Rule |
|-------|-------|---------------|------|
| `baseline` | 4 | `AppLayout.baseline` | Every vertical measurement is a multiple of this. |
| `typeBaseline` | 2 | `AppLayout.typeBaseline` | Line heights ride this finer grid — half of `baseline`. |
| `blockGrid` | 8 | `AppLayout.blockGrid` | Every *block* height (card, row, section) is a multiple of this. |
| `sectionGap` | 32 | `AppLayout.sectionGap` | Between two sections of a screen. |
| `itemGap` | 12 | `AppLayout.itemGap` | Between siblings inside one section. |
| `cardPadding` | 16 | `AppLayout.cardPadding` | Inside a card or panel. |
| `rowHeight` | 56 | `AppLayout.rowHeight` | Minimum tappable row; also the a11y touch-target floor. |

Sections are composed with `AppSection`, not with ad-hoc `SizedBox`es — hand-spaced
blocks are how screens drift apart again one commit at a time.

### The one-scroll rule

Interfaces here are **read**. A screen's primary content should be reachable in one
continuous scroll:

- **One scroll axis per screen.** No nested independently-scrolling regions.
- **No horizontal carousels that hide content.** If it matters, it is in the column.
- **No tabs-within-a-screen** to hide a second page of content. Use a section.
- A screen needing more than ~2 viewport heights of primary content is a signal to
  split the *information architecture*, not to add another scroller.

### Conformance

A screen that builds its own `Scaffold`, `AppBar`, or `SliverAppBar` has opted out of
the constitution and is a **review violation**. Screens use `AppScreen` (column form,
the default), `AppScreen.slivers` (grids and lazy lists), or `AppScreen.fill` (a
content band that scrolls itself, or one the overlays must layer over). **A back
affordance is never passed as a flag** — the frame reads it from the route, so a
screen can neither invent one nor omit one; a screen may only *name* it, via
`backIdentifier`, for the automation flows. A raw pixel value in a
layout position that a token expresses is likewise a violation, on the same footing as
a raw `Duration` in motion or a raw `BorderRadius.circular(N)`.

**The migration is complete and the ledger is a test.** It began as five tabs on
2026-07-29 and closed on 2026-08-01: `frame_conformance_test.dart` now holds **four
tables that partition every chrome-building file under `lib/`** — `_onFrame` (29 screens,
asserted chrome-free), `_frameless` (11 surfaces with no bands at all, each carrying its
reason, and never an `AppBar`), `_awaitingRuling` (empty, kept as the place the next
ruling is owed), and `_framework` (the two files allowed to build bands: `app_screen`
and `bottom_nav_shell`). A closure test walks the tree and fails on any chrome-building
file in **no** table, which is what makes it a denylist rather than an allowlist: a new
bespoke `Scaffold` fails on the commit that adds it, and a file arriving from a parallel
session fails on the merge — both have happened, which is the argument for the shape.

A screen joins a table in the same commit that changes how it builds, and it is never in
two and never in none. Prose could describe the rule; only the test can hold it, and
review is what let five headers diverge in the first place. This is Face Law rule 1
(`CLAUDE.md` → Canonical stack), and it is the reason the reviewer's checklist does not
re-ask it.

Two frame concerns were discovered during the migrations and belong to `AppScreen`, not
to any screen: the FAB slot (`AppScreen.floatingActionButton`, which also supplies the
nav-band inset the shell's `extendBody: true` requires) and the choice of column vs
sliver form. A screen that needs a third thing from the frame extends the frame — it
does not build around it.

Detail and modal routes were once off the roster as "a different placement problem — a
back affordance, no nav band". Both halves of that premise turned out to be false and the
exemption is **withdrawn** (2026-08-01, §4.2/§4.3). Detail routes are pushed *inside* the
shell branch, so band 4 was never absent; the only missing fact was a way back, and the
frame now reads that from the route (`Navigator.canPop`) instead of taking it as a flag.
Settings routes are pushed on the *root* navigator, where band 4 genuinely is absent —
and the frame reads that from `NavBandScope`, an inherited widget the shell wraps its
branch in, so a sibling route is told the truth rather than consulting a path allowlist.
`move_detail`, `combo_detail`, `lab_detail`, `move_category` and nine settings screens are
all on the frame. `video_editor` is off it for a different reason entirely — it is a
transaction, not an address — and that is `_frameless`, not an exemption.

`web-mirror/` is **exempt** (ruled 2026-07-29). It is the owner-only privileged tool, not
a product surface; the stacked viewport exists so that switching tabs in the shipped app
reads as one viewport, which is not a claim about a desktop utility with no tab bar. The
standing tokens ruling defers CSS until a third consumer, and mirroring `AppLayout` there
would have manufactured that third consumer for no user-visible gain. If the dev surface
ever ships to anyone, it inherits the frame.

### Type rides a 2pt baseline

**Owner's ruling, 2026-07-29: line heights are multiples of 2, not 4.**

This was previously filed as "known non-conformance" — `titleMedium` (30) and
`titleSmall` (26) are not multiples of the 4pt baseline, and the open question was
whether to snap them to 32 and 28. The answer is that they were never wrong: a
productive ramp needs a heading step between 26 and 32, and a 4pt baseline cannot
express one. Type gets the finer grid; *blocks* still land on `blockGrid` (8).

So the scale is unchanged and no screen's metrics move. What changed is that the rule
is now written and enforced: `AppLayout.typeBaseline` names it, and
`test/design/type_baseline_test.dart` fails if any step of `AppTypography` resolves to
an odd line box. A rule with no failing gate is a preference.

| Style | Font size | Line box | ÷2 |
|-------|-----------|----------|-----|
| `titleLarge` | 32 | 36 | ✅ |
| `titleMedium` | 24 | 30 | ✅ |
| `titleSmall` | 20 | 26 | ✅ |
| `bodyLarge` | 18 | 24 | ✅ |
| `bodyMedium` | 16 | 24 | ✅ |
| `bodySmall` | 14 | 20 | ✅ |
| `caption` · `sectionHeader` · `labelLarge` | 12 | 16 | ✅ |
| `labelSmall` | 10 | 12 | ✅ |

---

## Radius

| Token | Value | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|-------------|----------|
| `xxs` | 4 | `AppRadius.xxs` | `--radius-xxs` (planned) | Sharp small elements |
| `xs` | 8 | `AppRadius.xs` | `--radius-xs` (planned) | Cards, inputs |
| `sm` | 12 | `AppRadius.sm` | `--radius-sm` (planned) | Elevated surfaces |
| `md` | 16 | `AppRadius.md` | `--radius-md` (planned) | Standard card radius |
| `lg` | 24 | `AppRadius.lg` | `--radius-lg` (planned) | Bottom sheets, modals |
| `xl` | 32 | `AppRadius.xl` | `--radius-xl` (planned) | Hero elements |
| `pill` | 500 | `AppRadius.pill` | `--radius-pill` (planned) | Fully rounded (pills, FABs) |

A raw `BorderRadius.circular(N)` whose `N` equals a token value is a review violation —
resolve it from the named token (the fully-round idiom `circular(999)` → `AppRadius.pill`).
Off-scale bespoke radii that no token expresses are the exception; snapping them to the grid
is a design decision, not a mechanical conformance swap.

---

## Motion

### Families — the doctrine

Every product animation belongs to **exactly two families**, both composed from the
tokens below. Raw `Curve`/`Duration` literals driving visible motion on a product
surface are review violations.

| Family | Curve | Durations | What it does | Reserved for |
|--------|-------|-----------|--------------|--------------|
| **Fluid** (default) | `fluid` (= `productive`) for flow; `entrance` for appearances | `fast01`–`moderate02` | opacity + translation | everything by default |
| **Morph** | `morph` (= `springGentle`) | `moderate02` | size/shape/position continuity | state changes of one persistent element |

**Delight budget** — overshoot curves (`expressive`, `springBouncy`) require a
justified call-site comment. **Ambient** durations (`shimmerLoop`, `loaderLoop`,
`celebrate`) sit outside the two transition families (loops / one-shot celebrations).
The signature two-dot loader (`AppLoader`) is the canonical Fluid-family loading motif:
two dots translate in opposite phase on the `fluid` curve and cross at center.

### Durations

| Token | Value (ms) | Dart Constant | CSS Property | Consumers |
|-------|------------|---------------|-------------|----------|
| `fast01` | 70 | `AppMotion.fast01` | `--dur-fast-01` (planned) | Micro-interactions, state changes |
| `fast02` | 110 | `AppMotion.fast02` | `--dur-fast-02` (planned) | Subtle transitions |
| `moderate01` | 150 | `AppMotion.moderate01` | `--dur-moderate-01` (planned) | Button feedback |
| `moderate02` | 240 | `AppMotion.moderate02` | `--dur-moderate-02` (planned) | Panel expand/collapse, Morph |
| `slow01` | 400 | `AppMotion.slow01` | `--dur-slow-01` (planned) | Page transitions, entrance |
| `shimmerLoop` | 1200 | `AppMotion.shimmerLoop` | `--dur-shimmer` (planned) | Ambient: skeleton/shimmer loops |
| `loaderLoop` | 800 | `AppMotion.loaderLoop` | `--dur-loader` (planned) | Ambient: signature two-dot loader half-sweep |
| `celebrate` | 1500 | `AppMotion.celebrate` | `--dur-celebrate` (planned) | Ambient: one-shot celebration overlay |

### Curves

| Token | Value | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|-------------|----------|
| `fluid` | `easeInOutCubic` (alias of `productive`) | `AppMotion.fluid` | `--ease-fluid` (planned) | **Fluid** default — flow transitions |
| `morph` | `springGentle` (alias) | `AppMotion.morph` | `--ease-morph` (planned) | **Morph** — layout/shape continuity |
| `productive` | `easeInOutCubic` | `AppMotion.productive` | `--ease-productive` (planned) | Flow transitions (page changes, panels) |
| `expressive` | `easeOutBack` | `AppMotion.expressive` | `--ease-expressive` (planned) | Delight budget (checkmarks, FAB) |
| `entrance` | `easeOut` | `AppMotion.entrance` | `--ease-entrance` (planned) | Fluid appearance (fade-ins, slide-ups) |
| `springGentle` | mass:1, stiffness:200, damping:15 | `AppMotion.springGentle` | `--spring-gentle` (planned) | Layout transitions (panels, reorder) |
| `springBouncy` | mass:1, stiffness:150, damping:10 | `AppMotion.springBouncy` | `--spring-bouncy` (planned) | Delight budget (FAB entrance, card flip) |

---

## Typography

### Type Scale (Inter, default family)

| Token | Size | Weight | Line Height | Dart Constant | CSS Property | Consumers |
|-------|------|--------|-------------|---------------|-------------|----------|
| `titleLarge` | 32 | Bold (700) | 36/32 | `AppTypography.titleLarge` | `--fs-title-large` (planned) | Screen titles |
| `titleMedium` | 24 | SemiBold (600) | 30/24 | `AppTypography.titleMedium` | `--fs-title-medium` (planned) | Section headings |
| `titleSmall` | 20 | SemiBold (600) | 26/20 | `AppTypography.titleSmall` | `--fs-title-small` (planned) | Card titles |
| `bodyLarge` | 18 | Regular (400) | 24/18 | `AppTypography.bodyLarge` | `--fs-body-large` (planned) | Rich content |
| `bodyMedium` | 16 | Regular (400) | 24/16 | `AppTypography.bodyMedium` | `--fs-body-medium` (planned) | Standard body text |
| `bodySmall` | 14 | Regular (400) | 20/14 | `AppTypography.bodySmall` | `--fs-body-small` (planned) | Secondary content |
| `caption` | 12 | Medium (500) | 16/12 | `AppTypography.caption` | `--fs-caption` (planned) | Labels, timestamps |
| `sectionHeader` | 12 | Bold (700), 1.2 letter-spacing | 16/12 | `AppTypography.sectionHeader` | `--fs-section-header` (planned) | Section headers |
| `labelLarge` | 12 | Bold (700), 1.2 letter-spacing | 16/12 | `AppTypography.labelLarge` | `--fs-label-large` (planned) | Button labels, badges |
| `labelSmall` | 10 | Medium (500) | 1.2 | `AppTypography.labelSmall` | `--fs-label-small` (planned) | Small metadata |

### Font Families

| Token | Dart Constant | CSS Property | Consumers |
|-------|---------------|-------------|----------|
| Inter | `AppFontFamily.inter` | `--font-inter` (planned) | Default UI |
| Outfit | `AppFontFamily.outfit` | `--font-outfit` (planned) | Alternate sans-serif |
| Poppins | `AppFontFamily.poppins` | `--font-poppins` (planned) | Rounded alternate |
| Space Mono | `AppFontFamily.spaceMono` | `--font-space-mono` (planned) | Code, retro numerals |
| JetBrains Mono | `AppFontFamily.jetBrainsMono` | `--font-jetbrains-mono` (planned) | Code |
| System | `AppFontFamily.system` | `--font-system` (planned) | Platform default |

---

## Depth

### Z-Index Layers

| Token | Value | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|-------------|----------|
| `zBackground` | -1 | `AppDepth.zBackground` | `--z-background` (planned) | Heatmaps, decorative textures |
| `zContent` | 0 | `AppDepth.zContent` | `--z-content` (planned) | Cards, rows, panels |
| `zRaised` | 1 | `AppDepth.zRaised` | `--z-raised` (planned) | FABs, toggle pills |
| `zOverlay` | 2 | `AppDepth.zOverlay` | `--z-overlay` (planned) | Bottom sheets, dialogs |
| `zTop` | 3 | `AppDepth.zTop` | `--z-top` (planned) | Toasts, system alerts |

### Depth Levels

| Token | Scale | Shadow Opacity | Shadow Offset | Shadow Blur | Blur Sigma | Parallax | Dart Constant | CSS Property | Consumers |
|-------|-------|---------------|---------------|-------------|-----------|----------|---------------|-------------|----------|
| `sunken` | 0.98 | 0.0 | (0,0) | 0 | 0 | 0.0 | `AppDepth.sunken` | `--depth-sunken` (planned) | Depressed elements |
| `flat` | 1.0 | 0.06 | (0,2) | 8 | 0 | 0.0 | `AppDepth.flat` | `--depth-flat` (planned) | Default content |
| `elevated` | 1.0 | 0.12 | (0,4) | 16 | 0 | 0.5 | `AppDepth.elevated` | `--depth-elevated` (planned) | Raised cards, menus |
| `floating` | 1.005 | 0.18 | (0,8) | 28 | 0 | 1.0 | `AppDepth.floating` | `--depth-floating` (planned) | Floating panels |
| `overlay` | 1.01 | 0.24 | (0,16) | 40 | 20 | 1.5 | `AppDepth.overlay` | `--depth-overlay` (planned) | Modals, sheets |

---

## Shadows

| Token | Blur | Offset | Spread | Dart Constant | CSS Property | Consumers |
|-------|------|--------|--------|---------------|-------------|----------|
| `soft` | 12 | (0,4) | — | `AppShadows.soft(brightness)` | `--shadow-soft` (planned) | Default card shadow |
| `raised` | 22 | (0,10) | — | `AppShadows.raised(brightness)` | `--shadow-raised` (planned) | Elevated surfaces |
| `focus` | 34 | (0,16) | — | `AppShadows.focus(brightness)` | `--shadow-focus` (planned) | Focused/highlighted |
| `layered` | 20 + 16 | (0,0) + (0,6) | 1 + 0 | `AppShadows.layered(brightness)` | `--shadow-layered` (planned) | Hero cards, bottom nav |

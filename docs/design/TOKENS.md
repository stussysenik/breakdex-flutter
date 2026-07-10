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

# Tasks — Color Packs

**Phase dependencies.** Phase 1 (OKLCH + ramp) and Phase 2 (role vocabulary) are
**independent** and may fan out. Phase 3 consumes both. Phase 4 consumes Phase 3. Phase 5
(catalogue + Settings) consumes Phase 4. Phase 6 is owner-gated and blocks nothing.

Source of truth for the ask: `redesign-visual-first-experience` task 6.5. Tick 6.5 there in
whichever commit closes Phase 5 (cross-change ledger rule).

**Sequencing note.** This change deliberately mirrors `add-icon-system-and-packs` (closed
vocabulary → exhaustive pack → `ThemeExtension` → persisted preference → conformance test).
Landing the icon change first is recommended so the pattern is established once and reviewed
once, but there is no code dependency between them and they may run in parallel.

## Phase 1: Perceptual ramp

- [x] 1.1 sRGB ↔ OKLab ↔ OKLCH conversion in `lib/core/design/oklch.dart` (~40 LOC, no
  package — D2). Round-trip is lossless within tolerance.
  <br/>**DONE 2026-07-30.** Ottosson's matrices, no package. Round trip holds within half an
  8-bit code point for all 11 shipped seeds and a 52-point hue sweep; the sRGB primaries and
  white match the published `oklch()` values within 1e-4. Two shapes the arithmetic needed
  that the spec did not name: a **signed** cube root (a round trip drives the LMS terms
  negative, where `pow` returns NaN) and hue pinned to 0 below chroma 1e-6 (`atan2` of
  numerically-zero chroma is noise, which would hue-jitter a gray seed's ramp).
- [x] 1.2 Ramp derivation: seed + weight step → color, monotonic in lightness, hue preserved
  within a stated tolerance.
  <br/>**DONE 2026-07-30.** `rampFromSeed` distributes lightness linearly 0.97 → 0.22; the
  seed contributes hue and chroma only, so step *n* of any two ramps is the same weight
  (measured spread < 0.01 L across five hues). Out-of-gamut steps **spend chroma, never hue**
  — bisection to the largest in-gamut chroma at fixed (L, h), because channel clipping
  rotates hue. Stated tolerance: hue holds within **2°** across every step, and the fit moves
  L and h by float noise only (1e-6 / 1e-4).
  <br/>**Defect found and fixed in the same pass:** the gamut test used half an 8-bit step as
  its tolerance but applied it in *linear* RGB. The transfer function's slope near black is
  12.92, so a linear overshoot of 0.002 became six encoded code points and the clamp moved
  hue by **3.5°** — breaking the one guarantee the fit exists to provide. The bound is now
  float noise (1e-9), so the clamp is unreachable rather than merely small. The test
  tolerances were tightened to match; the loose ones passed the broken code.
- [x] 1.3 `test/core/design/oklch_test.dart` — round-trip fidelity, known-value conversions
  against published OKLab reference values, ramp monotonicity, hue stability across steps.
  <br/>**DONE 2026-07-30.** 16 tests, all green: conversion (5), gamut fitting (2), ramp
  (5), HSL comparison (3, task 1.4). Chroma taper proven not to touch an achromatic seed, so
  the same call yields the grayscale ramp the `mono` pack needs.
- [x] 1.4 Red-prove 1.2 against an HSL ramp: assert that two hues at the same step differ
  perceptibly in lightness under HSL and do not under OKLCH. This is the claim D2 rests on;
  it should be a test, not a paragraph.
  <br/>**DONE 2026-07-30 — measured.** Yellow (60°) and blue (240°) at HSL lightness 0.5
  differ by **>0.3** perceived lightness — about a third of the visible range at the same
  nominal "lightness". The same two hues at OKLCH L 0.6 differ by **<0.01**. At ramp scale
  across nine steps: worst HSL spread **>0.15**, worst OKLCH spread **<0.01**. D2 is now a
  test, not a paragraph.

## Phase 2: Role vocabulary

- [x] 2.1 Enumerate every color role the app renders today — surfaces from `ColorScheme`,
  signals from `AppSemanticTheme`, accent. Baseline (2026-07-29): **38 `const Color` in a
  58-line `colors.dart`**; re-derive rather than trust it.
  <br/>**DONE 2026-07-30 — re-derived, and the baseline was wrong.** It is **39** `const
  Color` in 58 lines, not 38. The 39 collapse to **17 roles**, because most are the same role
  under a different mode: `lightBg` / `darkBg` / `monoLightBg` / `monoDarkBg` are four values
  of `background`, resolved by brightness and overlay rather than by four names.
  <br/>**The material finding — 241 raw sites in 58 files.** `AppColors.*` is read directly
  from `lib/features/**` at **241 call sites across 58 files**, bypassing the theme entirely:
  `accent` ×72, `actionAgain` ×46, `stateMastery` ×37, `actionGood` ×20, `actionHard` ×15,
  `stateLearning` ×14, then a tail. This is the 6.4 icon problem again (434 raw `Icons.*`),
  and it means a pack resolving only `ColorScheme` + `AppSemanticTheme` **will not change
  those pixels**. Recorded as 2.5 rather than fixed here — it is a migration, not this task.
  <br/>**It is also a live defect in already-shipped work.** These sites bypass the
  `AccessiblePalette` overlay too, so the deuteranopia guarantee is already broken where they
  render. Confirmed, not inferred: `lib/features/lab/widgets/milestone_list.dart:292,297,306`
  paints `AppColors.stateMastery` (`#1F8A70`) into a live decoration; under
  `AccessiblePalette.deuteranopia` `AppSemanticTheme` swaps mastery to `#009E73` and that
  widget keeps the unsafe green.
- [x] 2.2 Close the vocabulary as an enum. Every role is a thing a screen means, not a hex.
  <br/>**DONE 2026-07-30.** `AppColorRole` in `lib/core/design/color_roles.dart` — 17 roles,
  each carrying an `AppColorRoleKind` (`surface` · `ink` · `signal`) that names **which axis
  owns it**, so D3's selective override is checkable rather than conventional: a test can
  assert no `signal` survives the deuteranopia overlay and every `surface` does.
  `test/core/design/color_roles_test.dart` (4 tests) pins the count and asserts the
  signal/surface sets **by name** — reclassifying a signal as ink would silently exempt it
  from the overlay, which is the exact regression D3 exists to prevent.
  <br/>**One role the spec did not name: `error`.** `ColorScheme` requires it, and D1 makes
  the pack responsible for the whole `ColorScheme`, so it must be a role. It is classified
  `signal` because it is meaning carried by color — which makes the overlay-owned set **8,
  not the 7 D3 states**. Consequence, and a pre-existing gap: `ColorScheme.error` is
  hardwired to the `actionAgain` value in every mode, so it does **not** follow the
  deuteranopia overlay today even though the "again" rating does. Recorded as 2.4; not
  changed here, because 3.2 requires `classic` to be byte-identical to current rendering and
  this is an overlay-axis behavior change, not a pack one.
- [x] 2.3 Land 2.2 into `docs/design/TOKENS.md` as a **Color Packs** section, including the
  axis-precedence rule from D3. Binary truth: `scripts/docs_ledger_check` green.
  <br/>**DONE 2026-07-30.** New `### Color Packs` section under Accessible Palettes: the
  17-role table with kinds and what each renders, derived-weights rule with the measured
  OKLCH-vs-HSL numbers, the `pack → brightness → overlay` precedence with why the order is
  load-bearing, the non-destructive property, and the shipped-packs-pass /
  overrides-are-shown split from D5. It also states plainly that two roles are not yet
  honored at every pixel (2.4, 2.5) — the vocabulary is the target, not yet the whole of what
  renders. Chapters 05 and 08 re-read and re-stamped; `docs_ledger_check` green.

- [ ] 2.4 **`ColorScheme.error` does not follow the accessibility overlay.** Found by 2.2. It
  is hardwired to the `actionAgain` value in every mode, so on `deuteranopia` the "again"
  rating becomes Okabe–Ito vermillion while `error` stays the unsafe `#C23B2A`. Decide
  whether `error` tracks `actionAgain` per-pack (and therefore follows the overlay) or is an
  independently seeded role, then make the overlay own it. Blocks nothing in Phases 3–5; the
  pack mechanism is indifferent to which way it resolves.
- [ ] 2.5 **241 raw `AppColors.*` sites in 58 files bypass the theme.** Found by 2.1. Until
  they read roles through `Theme.of(context)`, a pack selection will not change those pixels
  and the `AccessiblePalette` overlay does not reach them either (confirmed at
  `milestone_list.dart:292`). Same shape as the 434-site `Icons.*` migration in
  `add-icon-system-and-packs`, so the same instrument applies: migrate the call sites, then
  add a conformance test banning raw `AppColors.*` outside `colors.dart` with a
  **zero-allowlist** ban. Sized as its own phase-worth of work — do not fold it into a Phase
  3 task. Sequencing note: cheapest after Phase 3 lands, since the migration target
  (`AppColorRole` via the theme) must exist before 241 sites can point at it.

## Phase 3: The pack mechanism

- [x] 3.1 `lib/core/design/color_packs.dart` — `ColorPack` as `(Brightness) → (ColorScheme,
  AppSemanticTheme)`, resolving every role via a `switch` with **no `default`**. Confirm the
  exhaustiveness guarantee by deleting one case, observing `flutter analyze` fail, restoring
  it; record that red/green in the commit message.
  <br/>**DONE 2026-07-30 — red/green run, not assumed.** Deleting
  `AppColorRole.actionEasy` from `_ClassicColorPack.resolve` produced
  `non_exhaustive_switch_expression` at `color_packs.dart:73`; restoring it returned
  `No issues found`. A pack is `Color resolve(role, brightness)` rather than a direct
  `(ColorScheme, AppSemanticTheme)` factory — the same information, but it keeps the pack
  ignorant of Material's slot names, so a pack cannot accidentally own overlay behavior.
  `ResolvedColors` is the seam: pack + overrides in, role-addressed colors out, and
  `AppTheme` maps roles onto `ColorScheme` after the overlay has had its say.
- [x] 3.2 `classic` pack from today's `AppColors` seeds. **Byte-identical** to current
  rendering — the spec requires no screen changes appearance. Prove it with a golden or a
  role-by-role equality test against the pre-change constants, not by inspection.
  <br/>**DONE 2026-07-30.** `color_packs_test.dart` holds the 17 light + 17 dark expected
  values as literal maps, **hand-written rather than derived from the pack** — a test that
  reads the switch it checks proves only self-consistency. Asserted at three levels: role →
  constant, the built `ColorScheme` slot by slot, and the `AppSemanticTheme` ramp. The
  grayscale modes are covered too, since `monoOutline` / `monochrome` previously ran a
  hand-rolled `gray ?` branch and now run the `mono` pack.
  <br/>**One byte-identity carve-out, pinned rather than fixed:** grayscale modes still leak
  one red through `ColorScheme.error` (2.4). The test asserts the leak *on purpose* and names
  2.4 as the task that will turn it red — so the gap cannot be lost, and closing it cannot be
  mistaken for a regression.
- [x] 3.3 `mono` pack from the existing `monoLight*`/`monoDark*` ramp.
  <br/>**DONE 2026-07-30.** Surfaces from the shipped ramp; accent, `error`, and all seven
  signals collapse to ink; `onAccent`/`onError` are the background, never a hardcoded white
  (which vanishes on a near-white fill in dark mode — the bug the shipped grayscale branch had
  already fixed). Selecting it as a *pack* leaves `isMonoOutline` false, so surfaces stay
  filled: a pack is not a viewing mode.
- [x] 3.4 `colorPackProvider` in `lib/core/providers/theme_providers.dart` beside
  `fontFamilyProvider`; persists `color_pack` + per-role overrides; `fromKey` tolerates
  unknown values (spec: never brick on a removed pack).
  <br/>**DONE 2026-07-30.** `colorPackProvider` persists `color_pack`; `ColorPackId.fromKey`
  falls back to `classic` on null, empty, unknown, and wrong-case input.
  <br/>**Finding that shaped the override half: per-role overrides already existed, three
  times.** `accentColorProvider`, `learningStateColorsProvider`, and `ratingColorsProvider`
  already persist 8 of the 17 roles under three different key schemes. A fresh
  `color_role_override_*` store would have been a second source for the same eight facts. So
  `colorRoleOverridesProvider` **reads the same keys those three write** — zero migration, and
  a user who set an accent before packs existed keeps it. Writes invalidate in both directions,
  because the stored value cannot diverge but an in-memory cache can.
  <br/>**The defect that made the map necessary:** those three providers bake the `AppColors`
  fallback into their own state, so they cannot express "unset" — every read returns a color.
  Feeding them into a theme would override whichever pack is selected with the classic values
  on every build, and selecting `mono` would leave the state pills pink. The overrides map
  omits unset roles instead, and `AppTheme`'s convenience parameters are nullable for the same
  reason. Asserted by "omitting a parameter means *use the pack*, not *use classic*".
- [x] 3.5 Wire the pack into `AppTheme.build` **before** the `AccessiblePalette` overlay, so
  the overlay is applied last (D3).
  <br/>**DONE 2026-07-30.** `_build` now reads axis by axis: pack + overrides → `ResolvedColors`
  → overlay → `ColorScheme`. The overlay expresses itself as a **pack substitution** (grayscale
  ⇒ the `mono` pack) rather than as a second set of `gray ?` branches, which is why the old
  six surface parameters collapsed to none. Precedence is asserted four ways: neither a pack
  nor a per-role override can defeat the deuteranopia guarantee; the pack still supplies
  surfaces under deuteranopia; pack selection is invisible under monochrome; and returning to
  `standard` restores both pack and overrides unchanged.
  <br/>Grayscale drops the override map — a guarantee the user asked for outranks a preference
  they expressed earlier, and nothing is erased.

- [x] 3.6 **Fold the rating colors into the theme, closing a live second source.** Not
  specced; found while wiring 3.5. `ratingColorsProvider` never reached `AppSemanticTheme` —
  `rating_button_row.dart` read it directly and branched on `accessiblePaletteProvider` to
  decide which source won, putting a second copy of the precedence rule in a widget. Any other
  consumer of `colorForRating` (e.g. `settings_screen.dart:1289`) rendered the default while
  the buttons showed the user's choice. Ratings are now per-role overrides like every other
  signal, and the widget is one unconditional `AppSemanticTheme.of(context)` read — the palette
  branch and the local `_colorForRating` helper are both deleted. Byte-identical for the
  buttons in every mode.
  <br/>Also moved `RatingColors` to `lib/core/models/rating_colors.dart`, beside its sibling
  `LearningStateColors`: it lived in a `part of providers.dart`, which the design layer cannot
  import.

## Phase 4: Guarantees

- [x] 4.1 Extend `test/core/design/accessible_palette_test.dart` to run its existing contrast
  assertions across **every pack × both brightnesses**. A shipped pack failing contrast fails
  CI.
  <br/>**DONE 2026-07-30 — with a corrected premise.** The task says "its existing contrast
  assertions"; **there were none.** That file asserted role *identity* (deuteranopia swaps the
  ramp, monochrome inks it) and the icon+label double-encoding, but never a ratio. So 4.1 was
  writing the gate, not extending one. `lib/core/design/contrast.dart` holds WCAG 2.1 relative
  luminance — kept **separate from `oklch.dart` on purpose**: OKLab lightness is perceptual and
  WCAG luminance is photometric, they disagree, and deriving one from the other returns
  plausible wrong numbers. Phase 5.3's live readout uses the same function.
  <br/>Gated across every pack × both brightnesses: text and secondary text on all three
  surfaces, `onAccent` on `accent`, `onError` on `error` at **4.5:1** (SC 1.4.3); every signal
  on `card` and `background` at **3:1** (SC 1.4.11 — 3:1 rather than 4.5:1 because no signal
  carries meaning alone, which is asserted separately in the same file). Overlay-doesn't-lower-
  contrast is asserted for all three palettes. Measured worst cases: text 15.78:1, secondary
  5.60:1, `onAccent` 5.12:1, signals 3.12:1.
  <br/>**Two measured facts recorded rather than gated**, both in the shipped palette:
  `separator` on `background` is **1.27:1** in classic light — a deliberate aesthetic
  (`~/CLAUDE.md`: prefer surface value over hairlines) and WCAG-exempt as decoration, so
  gating it would fail the design doctrine, not the palette. And `actionEasy` on `fill` is
  **2.98:1** in classic light, short of 3:1 by 0.02 — pinned by an assertion that names 4.5 as
  the task, because no shipped surface paints a raw signal on `fill` (rating pills composite at
  alpha 0.10, a different number) and moving a shipped hex is a design call, not a test's.
- [x] 4.2 Axis-precedence test: for each accessible palette, assert pack selection cannot
  alter the colors that palette guarantees; and that returning to `standard` restores the
  pack and every per-role override unchanged.
  <br/>**DONE 2026-07-30** (landed with 3.5, `color_packs_test.dart`). Five assertions:
  the overlay replaces signals the pack supplied; no pack can defeat the deuteranopia
  guarantee; no per-role override can either; the pack still supplies surfaces under
  deuteranopia; and monochrome makes pack selection invisible. Non-destructiveness is asserted
  end to end — pack `mono` + an accent override, through `monochrome`, back to `standard`,
  byte-equal to before.
- [x] 4.3 Pack-completeness test: every pack resolves every role in both brightnesses.
  <br/>**DONE 2026-07-30** (landed with 3.1). Two forms: `resolve` returns normally for every
  pack × brightness × role, and `ResolvedColors` is total by construction because it is built
  from `AppColorRole.values` rather than accumulated by callers. The compile-time guarantee is
  the real gate; this is the runtime backstop.
- [x] 4.4 Persistence test: unset → `classic`; unknown key → `classic` without throwing; a
  stored preference is not overridden by a default change or a newly added pack.
  <br/>**DONE 2026-07-30.** 11 tests in `theme_providers_test.dart`: unset → `classic`,
  unknown key → `classic`, selection survives a restart (fresh container over the same prefs),
  unset roles **absent** from the override map, override round-trips a restart, `clear` returns
  a role to the pack and removes the key, every role's key is unique, and `fromKey` matches by
  key rather than ordinal so inserting an enum value cannot move an existing selection.
  <br/>Two tests cover the shared-key seam specifically: a pre-pack install carrying
  `accent_color` / `learning_state_color_mastery` / `rating_color_easy` is **adopted, not
  orphaned**, and a write through either reader is visible to the other.

- [ ] 4.5 **`actionEasy` on `fill` is 2.98:1 in classic light.** Measured by 4.1. Teal
  `#0D9F9A` on `#F1F5F9`, short of the 3:1 graphical-object threshold by 0.02. Not gated: no
  shipped surface paints a raw signal on `fill`, and changing a shipped hex is owner-visible.
  Resolve it in 6.2 (the new handpicked family) rather than by nudging one value — the derived
  ramp is what makes "the step that clears 3:1" a property of the ramp instead of a per-color
  accident, so a hand-nudge here re-creates the problem the ramp exists to remove.

## Phase 5: Catalogue and Settings

- [x] 5.1 Catalogue behind an interface (D4): named collections, browsable by season and by
  year. Ship the in-house curated set (Path B) as the default source.
  <br/>**DONE 2026-07-30.** `ColorCollection` + `ColorCatalogue` abstract class +
  `InHouseCatalogue` default in `lib/core/design/color_catalogue.dart`. The two proven packs
  (`classic`, `mono`) are organised into display groups. Multiple sources can coexist behind
  the interface — a licensed dataset drops in with no mechanism change.
- [x] 5.2 Color-pack Settings section on a `/settings-panel*` route, built with
  `settingsSectionPage` so it inherits the 6.3 Fluid + Morph transition. Live preview showing
  the same representative surfaces and signals per pack.
  <br/>**DONE 2026-07-30.** `ColorPacksScreen` at
  `lib/features/settings/widgets/color_packs_section.dart`, routed at
  `/settings-panel/color-packs` in `app_router.dart`. Linked from the Settings `Colors` panel
  via `context.push`. Preview swatches rendered from the current pack's `ResolvedColors`.
- [x] 5.3 Per-role override picker showing the **live contrast ratio and pass/fail as the
  color changes** (D5). Accepted when failing; never silently accepted, never blocked.
  <br/>**DONE 2026-07-30.** `_OverrideTile` with `_ContrastBadge` in `color_packs_section.dart`.
  Opens `showColorEditorDialog` for the chosen role. WCAG ratio computed via `contrastRatio()`
  against the appropriate background (surface/ink/signal by kind). Badge shows Pass/Fail at
  the appropriate threshold (3.0 for signals, 4.5 otherwise).
- [x] 5.4 State in the interface when an accessible palette is overriding the pack, rather
  than letting the selection appear to do nothing (spec scenario).
  <br/>**DONE 2026-07-30.** `_AccessibleOverrideBanner` at the top of `ColorPacksScreen` when
  `accessiblePaletteProvider != standard`. Banner explains that signal colors are overridden
  by the accessibility guarantee.
- [x] 5.5 ARB keys for pack names, collection names, and contrast copy in `lib/l10n/`;
  regenerate and commit `lib/l10n/gen/`. Binary truth: `scripts/check_l10n.sh` green.
  <br/>**DONE 2026-07-30.** 21 keys added to `app_en.arb` (`setColorPacksRouteTitle` through
  `setColorPacksResetOverrides`). `flutter gen-l10n` regenerated. L10n gate ✅.

## Phase 6: Owner-gated (blocks nothing)

- [ ] 6.1 **Pantone licensing decision** (D4). Path A: license the dataset — it drops in as
  one more catalogue source with no mechanism change. Path B (shipped default): in-house
  curated collections without the trademarked names, numbers, or wordmark. Route to
  `owner-verification-passes` if it is not answered while this change is active; do not let
  it hold Phases 1–5.
- [ ] 6.2 Design the *new* handpicked family the ask actually wants (D6). Deliberately after
  Phase 1 — designing it before the ramp exists means hand-tuning hexes the ramp would have
  generated.

## Verification

- [ ] V.1 `./verify.sh` green — ledger, `openspec --strict`, docs ledger, l10n, analyzer 0/0,
  full suite.
- [ ] V.2 `flutter build web --release` green.
- [ ] V.3 **NOT PROVEN by the above, state it plainly:** whether any pack *looks* better on a
  device or in a browser, and whether the derived ramps read as "fluid and organic" rather
  than merely uniform. That is the owner's judgement and the whole point of the ask. The
  tests prove completeness, monotonicity, contrast, and precedence — none of which is taste.
  Route the sitting to `owner-verification-passes`.

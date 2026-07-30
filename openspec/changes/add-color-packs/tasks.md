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

- [ ] 2.1 Enumerate every color role the app renders today — surfaces from `ColorScheme`,
  signals from `AppSemanticTheme`, accent. Baseline (2026-07-29): **38 `const Color` in a
  58-line `colors.dart`**; re-derive rather than trust it.
- [ ] 2.2 Close the vocabulary as an enum. Every role is a thing a screen means, not a hex.
- [ ] 2.3 Land 2.2 into `docs/design/TOKENS.md` as a **Color Packs** section, including the
  axis-precedence rule from D3. Binary truth: `scripts/docs_ledger_check` green.

## Phase 3: The pack mechanism

- [ ] 3.1 `lib/core/design/color_packs.dart` — `ColorPack` as `(Brightness) → (ColorScheme,
  AppSemanticTheme)`, resolving every role via a `switch` with **no `default`**. Confirm the
  exhaustiveness guarantee by deleting one case, observing `flutter analyze` fail, restoring
  it; record that red/green in the commit message.
- [ ] 3.2 `classic` pack from today's `AppColors` seeds. **Byte-identical** to current
  rendering — the spec requires no screen changes appearance. Prove it with a golden or a
  role-by-role equality test against the pre-change constants, not by inspection.
- [ ] 3.3 `mono` pack from the existing `monoLight*`/`monoDark*` ramp.
- [ ] 3.4 `colorPackProvider` in `lib/core/providers/theme_providers.dart` beside
  `fontFamilyProvider`; persists `color_pack` + per-role overrides; `fromKey` tolerates
  unknown values (spec: never brick on a removed pack).
- [ ] 3.5 Wire the pack into `AppTheme.build` **before** the `AccessiblePalette` overlay, so
  the overlay is applied last (D3).

## Phase 4: Guarantees

- [ ] 4.1 Extend `test/core/design/accessible_palette_test.dart` to run its existing contrast
  assertions across **every pack × both brightnesses**. A shipped pack failing contrast fails
  CI.
- [ ] 4.2 Axis-precedence test: for each accessible palette, assert pack selection cannot
  alter the colors that palette guarantees; and that returning to `standard` restores the
  pack and every per-role override unchanged.
- [ ] 4.3 Pack-completeness test: every pack resolves every role in both brightnesses.
- [ ] 4.4 Persistence test: unset → `classic`; unknown key → `classic` without throwing; a
  stored preference is not overridden by a default change or a newly added pack.

## Phase 5: Catalogue and Settings

- [ ] 5.1 Catalogue behind an interface (D4): named collections, browsable by season and by
  year. Ship the in-house curated set (Path B) as the default source.
- [ ] 5.2 Color-pack Settings section on a `/settings-panel*` route, built with
  `settingsSectionPage` so it inherits the 6.3 Fluid + Morph transition. Live preview showing
  the same representative surfaces and signals per pack.
- [ ] 5.3 Per-role override picker showing the **live contrast ratio and pass/fail as the
  color changes** (D5). Accepted when failing; never silently accepted, never blocked.
- [ ] 5.4 State in the interface when an accessible palette is overriding the pack, rather
  than letting the selection appear to do nothing (spec scenario).
- [ ] 5.5 ARB keys for pack names, collection names, and contrast copy in `lib/l10n/`;
  regenerate and commit `lib/l10n/gen/`. Binary truth: `scripts/check_l10n.sh` green.

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

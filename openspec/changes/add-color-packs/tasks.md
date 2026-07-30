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

- [x] 2.4 **`ColorScheme.error` does not follow the accessibility overlay.** Found by 2.2. It
  was hardwired to the `actionAgain` value in every mode, so on `deuteranopia` the "again"
  rating became Okabe–Ito vermillion while `error` stayed the unsafe `#C23B2A`, and
  `monochrome` kept one red while claiming no color survives.
  <br/>**Ruled: neither branch of the either/or — `error` stays an independently seeded
  role, *and* the overlay owns it.** The two options in this task were a false choice.
  Making `error` track `actionAgain` per-pack would buy overlay-following by deleting a
  distinction the vocabulary was written to make (2.1's whole point), while leaving it
  pack-seeded and overlay-free is the defect. A pack seeds it under `standard`; an overlay
  publishes one safe value for a failed condition and wins, exactly as it does for the other
  seven signals. Nothing in the vocabulary changed — `error` was already
  `AppColorRoleKind.signal`, which is what made the leak visible at all.
  <br/>RED/GREEN: the assertion `accessible_palette_test.dart` gained fails on the pre-fix
  build with vermillion expected and `#C23B2A` actual. The retired counter-assertion is the
  proof from the other side — `color_packs_test.dart` carried a test that *pinned the leak*
  ("this assertion is what will go red when it lands"), and it did; it now asserts the
  byte-identity that survives, which is `standard` only.
  <br/>**`onError` could not ride along and is the non-obvious half.** Once the overlay
  renames the color, the pack's paired ink is stale, and white — the reflex answer, and what
  the hardwire shipped — measures **3.9:1 on Okabe–Ito vermillion in light mode**, under
  4.5:1. `AppTheme._legibleInkOn` re-picks between the reading ink and the background by
  measured `contrastRatio`; the reading ink wins there at 5.4:1. Gated for every palette ×
  both brightnesses, so a future overlay value cannot reintroduce an unreadable pair.
  <br/>Second-order win: the grayscale `copyWith` block in `AppTheme._build` that existed
  *only* to preserve the leak is deleted. The mono pack already resolved `error` to ink and
  `onError` to the background, so the correct grayscale result now falls out of the pack
  substitution instead of being re-stated as an exception to it.
  <br/>**AUDIT (agent C, 2026-07-30, commits `0200b2c..ee52790`).**
  **PROVEN:** the ruling holds where it is asserted. `overlayOwnsSignals` is
  `isMonoOutline || palette != standard`, and the `semanticTheme` switch matches on
  `(true, _)` first, so `monoOutline` outranks the palette — the same ink ramp the
  `monochrome` assertions already cover, which is why the coverage gap below is a
  regression-guard gap and not a live defect. Ledger rule satisfied: `0200b2c` carries code,
  tests, and the `tasks.md` tick in one commit. `errorContainer`/`onErrorContainer` are not
  passed to the `ColorScheme` constructor and fall back to `error`/`onError`, so
  `robust_video_editor_view.dart:137-138` inherits the fix rather than keeping a stale red —
  unstated in the task, true by Flutter's getters, and worth naming because it is the only
  consumer that reads the container slots.
  <br/>**NOT PROVEN — `viewingMode: ViewingMode.monoOutline` × `error`/`onError` has no
  assertion.** Both new tests vary only `AccessiblePalette`; `color_packs_test.dart:178` is
  the sole `monoOutline` build in the suite and it asserts surfaces, not signals. The path is
  reachable from the UI (marker-outline mode with the standard palette) and is where the
  deleted `copyWith` used to force `error: actionAgain` / `onError: Colors.white`. Reinstating
  that hardwire under `monoOutline` alone would pass the full gate today. One `expect` inside
  the existing loop closes it.
  <br/>**NOT PROVEN — an unrelated dependency downgrade rode this commit.** `0200b2c` also
  changed `pubspec.lock`: `matcher` 0.12.19 → **0.12.18** and `test_api` 0.7.10 → **0.7.9**.
  Nothing in a theme fix asks for that; it is a resolver side effect nobody recorded, and it
  changes what CI installs against the pinned Flutter 3.41.3. Not a failure — the gate is
  green on it — but it is an unexplained change to shipped state, which is exactly what the
  ledger rule exists to prevent. A: either justify the pin or restore it in its own commit.
  <br/>**NOT PROVEN (unchanged, owner-gated):** how any of this looks — the gate measures
  contrast ratios, not taste; `flutter build web --release`; device behavior; live sync.
- [x] **C's audit finding on 2.5 — RESOLVED 2026-07-30 by A, by completion rather than revert.**
  C measured a mid-sweep tree and recommended reverting; A re-measured the finished tree and
  ruled against that. On `1bff436`: `flutter analyze` **0 errors / 0 warnings** (7 pre-existing
  infos), `./verify.sh` **ALL GATES PASSED, exit 0, 1347 pass / 3 skip / 0 fail** (+13 from
  1334). Every one of the 57 errors C counted was an unplumbed no-`context` site, and plumbing
  them is the work — not damage to undo. **The finding was still correct and load-bearing:** it
  named the root cause (one bad-rewrite class, not four error classes) and it named the reason
  a color migration is unlike an icon migration, which is now recorded in 2.5a. It is filed here
  rather than deleted so the ruling survives, per the archive-with-a-reason rule.
  <br/>**Process finding, and the real one: two crews worked this task concurrently on one tree,
  and only convergent substitution kept it lossless.** A dispatched B on 2.5a while another
  session was already mid-sweep; B detected it from file mtimes, hit exactly one direct
  collision (`cloud_sync_section.dart`, a `_statusLabel` signature race), and reverted its own
  edit in favor of the other. Nothing was lost, but nothing prevented loss either — `## NOW`
  names one active *change*, and that is not a lock on one active *task*. Captured as **2.7**.
  <br/>Below is C's finding as filed, unedited:
  <br/>~~BLOCKING — an in-flight mechanical sweep of this task does not compile~~ (found by
  agent C, 2026-07-30, working tree at `ee52790` + 53 uncommitted files). `./verify.sh --quick`
  is **RED at the analyzer: 57 errors, 34 warnings**, where the same gate was green on the
  clean tree twenty minutes earlier. The whole population is this sweep, in four classes:
  **30 `const_eval_method_invocation`** · **23 `undefined_identifier`** ·
  **4 `implicit_this_reference_in_initializer`** · **34 `unused_import`**.
  <br/>**One root cause, not four.** The sweep rewrote `AppColors.X` to
  `AppSemanticTheme.of(context).X` textually, wherever the text appeared — including where no
  `BuildContext` is in scope and where the expression must stay `const`.
  `combo_detail/widgets/status_tag.dart:18` is the clean specimen: `statusStyle(String status)`
  is a **top-level function with no `context` parameter**, so all three rewritten arms reference
  an identifier that does not exist. The `const` failures are the same edit landing inside
  `const` constructors and initializers, where a method call is illegal by definition. The
  unused imports are `colors.dart` left behind after its last reference was rewritten away.
  <br/>**This is precisely what 2.6 was split out to prevent.** That task already ruled that
  sites with no `BuildContext` in reach are a different problem needing a different fix — a
  text-level sweep cannot honor that split, because the thing it must not touch is invisible at
  the text level. The migration needs the call site's *scope* as input: a `context`-bearing
  build method takes the theme read; a top-level or `const` site either gains a parameter, or
  stays a constant and is 2.6's.
  <br/>**Nothing is committed, so nothing is lost** — but the tree is unbuildable until this is
  either finished with scope-awareness or reset. A: rule which. Recommend reverting the sweep and
  re-running it per 2.5a/2.5b's stated split with the `const`/no-context sites excluded up front,
  rather than repairing 57 sites downstream of a bad rewrite.
  <br/>**Audit scope note:** the full-gate result recorded under 6.14 in
  `redesign-visual-first-experience` (`+1333 ~3 -1`) was measured on the **clean** tree at
  `ee52790`, before these edits existed, and stands.

- [x] 2.5 **241 raw `AppColors.*` sites in 58 files bypass the theme.** Found by 2.1. Until
  they read roles through `Theme.of(context)`, a pack selection will not change those pixels
  and the `AccessiblePalette` overlay does not reach them either (confirmed at
  `milestone_list.dart:292`). Same shape as the 434-site `Icons.*` migration in
  `add-icon-system-and-packs`, so the same instrument applies: migrate the call sites, then
  add a conformance test banning raw `AppColors.*` outside `colors.dart` with a
  **zero-allowlist** ban. Sized as its own phase-worth of work — do not fold it into a Phase
  3 task. Sequencing note: cheapest after Phase 3 lands, since the migration target
  (`AppColorRole` via the theme) must exist before 241 sites can point at it.
  <br/>**DONE 2026-07-30. FULL GATE: `ALL GATES PASSED`, exit 0 — 1347 pass / 3 skip / 0 fail
  (from 1334; +13), analyzer 0 errors / 0 warnings.** The gate was written first and run red:
  **55 files**, not 58, and **275 sites**, not 241 — the count grew because Phase 5 shipped a
  new settings surface into the same problem. Post-migration the gate is green with **zero**
  offending files.
  <br/>**The "zero-allowlist" instruction in this task is wrong, and the reason is worth
  keeping.** The icon ban could be absolute because `icons.dart` is the only file allowed to
  name an `IconData`. Colors have a **definition layer**: a pack must seed its roles from
  constants and a preference provider must fall back to one, so an absolute ban outside
  `colors.dart` would forbid the mechanism from existing. The allowlist is therefore
  seven named files that *define what a role resolves to*, never one that *paints* with it —
  and a second test asserts each entry still reads `AppColors`, so an exemption cannot outlive
  its reason. `categories_service.dart` is in it for a different reason than the rest: its
  presets are **persisted user data**, and re-pointing them at the theme would make categories
  a user already saved drift when a pack changes.
  <br/>**Two bypass classes the site count could not see, both closed here.**
  <br/>• **`LearningState` / `ReviewRating` carried a baked `Color` field.** A widget reading
  `state.color` bypassed the theme *without ever naming `AppColors`* — invisible to the gate
  this task specifies, which is why counting call sites understated the problem. The field is
  deleted (3 call sites, all moved to `colorForState` / `colorForRating`); presentation no
  longer rides on a domain enum.
  <br/>• **A Riverpod `FutureProvider` decided a pixel.** `calendar_view.dart`'s day-detail
  rows carried a resolved `Color` built inside a provider with no `BuildContext`. Replaced
  with an `_ActivityKind` that resolves at the widget — the kind travels, the color does not.
  <br/>**`AppMediaChrome` — the sites that looked correct.** Video player, trim timeline,
  instax viewer and review card named `AppColors.darkBg`/`darkCard`/`darkFill` because those
  surfaces are dark *on purpose*, independent of app brightness. The intent is legitimate,
  which is exactly why the constants survived every prior review. New `ThemeExtension`
  resolves the **active pack at `Brightness.dark`**: the intent survives, the pixels return to
  the theme, and a pack now owns its own media chrome. Gated three ways — equal to the classic
  pack's dark side, identical under `AppTheme.light()` and `AppTheme.dark()`, and *different*
  under the `mono` pack.
  <br/>**Painters take resolved colors, they do not read the theme.** Four `CustomPainter`s
  (`_BurstPainter`, `_PoseOverlayPainter`, `_FlowGraphPainter`, plus `statusStyle` /
  `tierColor` / `_statusMeta` as context-less helpers) had no `BuildContext` at all. Each now
  receives the resolved value from `build`. `_FlowGraphPainter` **shrank** doing it: passing
  the resolved ink deleted three
  `brightness == Brightness.light ? AppColors.lightText : AppColors.darkText` ternaries — the
  theme already answers that question, and duplicating it was what kept the canvas outside the
  pack and the overlay.
  <br/>**Red/green, not assumed.** `test/core/design/color_migration_test.dart` (7 tests)
  asserts the *pre-migration* values fail: restoring `AppColors.stateMastery` at one
  `statusStyle` case turns two tests red (deuteranopia keeps `#1F8A70` instead of Okabe–Ito
  `#009E73`, and monochrome stops collapsing to ink); reverting the revert returns all 7 green.
  This is the `milestone_list.dart:292` defect 2.1 confirmed, now proven fixed by measurement
  rather than by the gate's spelling check.
  <br/>**Gotcha found while writing that test, recorded because it cost a wrong diagnosis:**
  `MaterialApp` wraps its child in an `AnimatedTheme`, so a theme swap is **lerped**, and
  `ThemeExtension.lerp` holds the *old* value for `t < 0.5`. A single `pump()` therefore reads
  the previous theme — the first run reported the classic green under deuteranopia and looked
  exactly like a failed migration. `pumpAndSettle()` is what makes the read the theme under
  test.
  <br/>**NOT PROVEN:** how any migrated surface *looks* — no device, no browser, no screenshot
  judged. The gate proves the constants are unreachable and the axes resolve; it says nothing
  about taste or about a layout that a now-theme-following color may sit badly against
  (→ V.3, `owner-verification-passes`). Also unproven here: `flutter build web --release`.
  <br/>**BROKEN DOWN 2026-07-30 (A).** Re-measured on this tree: **292** raw `AppColors.*`
  reads outside `colors.dart`, of which **209 are widget-layer** (198 `lib/features/**` + 11
  `lib/shared/**`) — those are 2.5's scope. The remaining 83 are not call sites of the same
  kind and are ruled out below. Three sub-units, each independently verifiable, gate last:
  **2.5a** signals (114) · **2.5b** accent + surfaces/ink (95) · **2.5c** the conformance ban.
  <br/>**The substitution table** (`AppTheme._build`, `theme.dart:454–479`, is the authority):
  `background` → `Theme.of(context).scaffoldBackgroundColor` · `card` → `colorScheme.surface` ·
  `fill` → `colorScheme.surfaceContainerHighest` · `text` → `colorScheme.onSurface` ·
  `secondaryText` → `colorScheme.secondary` · `separator` → `colorScheme.outline` ·
  `accent` → `colorScheme.primary` · `onAccent` → `colorScheme.onPrimary` ·
  the 7 signals → `AppSemanticTheme.of(context).<field>`.
  <br/>**Measured de-risk:** only **6** of the 209 sites sit in a `const` expression
  (`settings_screen.dart:681,907` · `sync_status_screen.dart:423` ·
  `calendar_view.dart:362,366` · `notes_section.dart:268`), so the sweep is mechanical
  everywhere else; those six drop `const` or lift the read into `build`. No widget-layer file
  reads `AppColors` outside a `BuildContext` reach.
  <br/>**Scope ruling — `lib/core/**` is NOT in 2.5 and is NOT silently exempt.**
  `lib/core/design/**` (51) is the definition scope: a pack seeding from constants is its job,
  exactly as `icons.dart` names `Icons.*`. The other 32 — `lib/core/models/**` (14),
  `lib/core/services/**` (8), `lib/core/providers/**` (10) — are context-free *defaults*, and
  substituting a theme read there is impossible, not merely awkward. They are 3.4's
  "bakes the fallback into its state" problem one layer down. Captured as **2.6**.
- [x] 2.5a **Signals — the live accessibility defect (114 sites).** Every
  `AppColors.state{New,Learning,Mastery}` and `AppColors.action{Again,Hard,Good,Easy}` read in
  `lib/features/**` + `lib/shared/**` → `AppSemanticTheme.of(context).<field>`. Distribution:
  `actionAgain` 42 · `stateMastery` 33 · `actionGood` 16 · `actionHard` 11 ·
  `stateLearning` 10 · `stateNew` 2 · `actionEasy` 2. Where the raw read is already switched on
  a `LearningState`/`ReviewRating`, use `colorForState` / `colorForRating` rather than restating
  the switch — a second copy of that mapping in a widget is the 3.6 defect.
  <br/>**Red/green is required and available:** `milestone_list.dart:292,297,306` paints
  `AppColors.stateMastery` (`#1F8A70`) into a live decoration while
  `AccessiblePalette.deuteranopia` publishes `#009E73`. A widget test pumping that widget under
  the deuteranopia theme must fail before the sweep and pass after. One such test is the proof
  for the class; do not write 114 of them.
  <br/>**DONE 2026-07-30 (`1bff436`). 116 sites, not 114 — the estimate was low by two.** Raw
  signal reads under `lib/features/**` + `lib/shared/**` are now **0**, verified by count and
  held by 2.5c. RED/GREEN ran on the named target:
  `test/features/lab/milestone_list_signal_theme_test.dart` pumps `MilestoneList` under
  `AppTheme.light(palette: AccessiblePalette.deuteranopia)` and failed pre-sweep with
  `Expected: not <2067056> / Actual: <2067056>` — `#1F8A70` reaching the pixel with the overlay
  bypassed. A second case pins the standard palette so the fix cannot drift into always-deuter.
  <br/>**The substitution was mechanical; the *scope* was not, and that is the finding.** A
  blind text rewrite of `AppColors.X` → `AppSemanticTheme.of(context).X` compiles only where a
  `BuildContext` is in reach. It was not, at ~23 sites — `statusStyle(String)` in
  `combo_detail/widgets/status_tag.dart` is the clean specimen: a top-level function with no
  `context` parameter, where all three rewritten arms named an identifier that does not exist.
  The analyzer was used as the oracle to find every one, then each was plumbed: painters take a
  resolved color read in `build`, and `statusStyle` / `dotColor` / `achievement_tile` take a
  `BuildContext` or an `AppSemanticTheme`. No widget restates a `LearningState`/`ReviewRating`
  switch, so no 3.6 defect was introduced. **A text-level sweep cannot honor the 2.6 split,
  because the thing it must not touch is invisible at the text level** — scope is the input a
  color migration needs and an icon migration did not.
  <br/>Of the six named `const` sites, `calendar_view.dart:362,366` dropped `const` on the two
  signal `_Dot`s while keeping it on the adjacent `Color(0xFF9333EA)` literal; the other four
  resolved in the same sweep. Six now-unused `colors.dart` imports removed.
- [x] 2.5b **Accent, surfaces, and ink (95 sites).** `AppColors.accent` (68) →
  `colorScheme.primary`; the 27 `light*`/`dark*` reads → the slot table above.
  <br/>**Not mechanical, and this is the whole risk of the unit:** a widget naming
  `AppColors.darkBg` (6) / `darkFill` (5) / `darkText` (3) / `darkCard` (2) /
  `darkSeparator` (1) has hardcoded a *brightness*, which for player chrome or a camera
  overlay may be deliberate — that surface is always dark regardless of theme. Each such site
  is a judgement: convert it, or keep it and say why. Any kept site must be re-expressed
  against the value it actually means, not left naming a theme constant, because 2.5c bans the
  name. List every kept site with its reason in this ledger.
  <br/>**DONE 2026-07-30 (`1bff436`) — and the "keep it and say why" branch was refused in
  favor of a type, which is the better answer.** This task asked for a *list of exceptions*;
  what shipped is `AppMediaChrome` (`theme.dart:164`), a `ThemeExtension` for surfaces that are
  dark **on purpose** — video players, the trim timeline, the instax viewer. It resolves the
  active pack at `Brightness.dark` and publishes `background` / `card` / `fill` / `separator` /
  `ink`, so those surfaces keep their intent (stay dark under a bright photo) *and* return their
  pixels to the theme: a pack owns its own dark side, so media chrome follows the pack without
  ever following the app's light mode. Seven files read it.
  <br/>This is the same move as `BackLeading` (6.2) and `AppScreen` — **a rule shipped as a type
  cannot be violated by the next screen, and a list of blessed exceptions can.** The dark-brightness
  reads were never "hardcoded a brightness by mistake"; they were an unnamed role. Naming it is
  what let the ban stay absolute with no widget exemptions at all.
- [x] 2.5c **The conformance ban.** `test/core/design/color_conformance_test.dart`,
  mirroring `test/core/design/icon_conformance_test.dart`. Land it **last** — it is red until
  2.5a and 2.5b are both in. Record the ban's scope and the substitution table in
  `docs/design/TOKENS.md` → Color Packs, and add the ban to the `openspec/AGENTS.md` review
  checklist beside the `Icons.*` one. `scripts/docs_ledger_check` green.
  <br/>**DONE 2026-07-30 (`1bff436`). This task specified a zero-length allowlist over
  `lib/features/**` + `lib/shared/**`; the gate that shipped is different, and stronger.** It
  bans `AppColors.*` across **all** of `lib/`, with a 7-entry `_definitionLayer` set.
  **Zero-allowlist is not available for color and the reason is structural, not a concession:**
  the icon ban could be absolute because `icons.dart` is the only file permitted to name an
  `IconData`, whereas color *has* a definition layer — a pack must seed its roles from
  constants and a preference provider must fall back to one, so an absolute ban would forbid
  the mechanism from existing. Every entry is a file that *defines* what a role resolves to,
  never one that *paints* with it, and no widget can qualify. Banning all of `lib/` with a
  justified layer is a tighter gate than banning two directories with none: it covers
  `lib/core` widgets and any directory added later.
  <br/>**The anti-rot half is the part worth keeping.** A second test asserts every
  `_definitionLayer` entry still exists *and still reads* `AppColors.*`, so an exemption cannot
  outlive its reason — the failure mode of every allowlist is a stale line nobody dares delete,
  and this one deletes itself. `TOKENS.md:156` records the ban.
- [ ] 2.6 **Context-free color defaults in `lib/core/**` (32 sites).** Split out of 2.5 by the
  scope ruling above. `learning_state.dart` (7), `rating_colors.dart` (4),
  `learning_state_colors.dart` (3), `categories_service.dart` (8), `theme_providers.dart` (10)
  name `AppColors` constants with no `BuildContext` in reach, so the theme read 2.5 uses does
  not exist for them. This is the same shape as 3.4's finding — a provider that bakes its
  fallback into its state cannot express "unset", so its default *is* a hardcoded color that
  no pack and no overlay can move. The answer is a seam (defaults resolved at the read, not at
  the store), not a substitution, which is why it is not part of the sweep. Not blocking: these
  are defaults behind values the theme already overrides for every rendered pixel 2.5 touches.
  <br/>**RESCOPED 2026-07-30 (A), after 2.5a–c landed. It is 25 sites in 4 files, not 32 in 5,
  and only one of them is still an open question.** `learning_state.dart` went to **0** — its 7
  reads were `LearningState` → color, which is `AppSemanticTheme.colorForState`, so they were
  never context-free at all and 2.5a absorbed them correctly.
  <br/>Of the remaining four, three are **answered, not deferred**, and 2.5c's `_definitionLayer`
  is where the answer is recorded: `rating_colors.dart` (4) + `learning_state_colors.dart` (3)
  are immutable default snapshots fed *into* `AppTheme` as overrides — a color the theme consumes
  cannot read the theme, so naming a constant there is the mechanism working; and
  `categories_service.dart` (8) is a picker palette of **persisted user data**, not rendered
  theme — a category's color is stored per-category, so re-pointing those presets at the theme
  would make already-saved categories drift when a pack changes. That one is a ruling to keep,
  not a migration to do.
  <br/>**The residual is `theme_providers.dart` (10)** — the genuine 3.4 shape: a provider that
  bakes its fallback into its state cannot express "unset", so its default *is* a hardcoded color
  no pack can move. `colorRoleOverridesProvider` (3.4) already demonstrates the fix by omitting
  unset roles while reading the same keys, so the seam exists and this is a migration onto it
  rather than a design question. Still not blocking, and still not part of any sweep.
- [ ] 2.7 **Two crews can work one task concurrently and the board cannot tell.** Found the hard
  way on 2.5 (see the resolved audit finding above). `## NOW` names the one active *change* and
  the next unticked *task*, which is enough to stop two sessions picking different work and
  useless at stopping them picking the *same* work. Nothing in `status.sh`, `verify.sh`, or the
  ledger records that a task is in flight, so the second session's only signal was file mtimes —
  noticed by an agent, not by an instrument.
  <br/>**Cheap and sufficient:** claim-on-start. A session ticking into a task writes one line
  naming the task, the role, and the commit it started from, and `status.sh` prints an unclosed
  claim as a warning beside `NEXT`. Derived from the log, not stored state, exactly like the
  rest of the board. Not a lock and should not become one — the goal is that a second session
  *sees* the collision in its first minute, which is the whole cost here.
  <br/>Belongs in the `docs/manual/FACTORY.md` operating model rather than this change, since it
  is a property of the crew protocol and not of color. Recorded here because this is where it was
  found; move it when a Teacher session touches FACTORY.md.

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

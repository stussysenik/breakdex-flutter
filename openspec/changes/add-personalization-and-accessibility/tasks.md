# Tasks — Personalization & Accessibility

Ledger rule: tick each box in the same commit that lands the work.

## Phase 1: Parametric naming

- [x] 1.1 Audit render sites of the default nouns ("Moves"/"Move", "Combos"/"Combo") —
  `rg` sweep. Actual: ~15 display sites (fewer than the ~25 estimate; the rest were
  filesystem-path literals in `lib/core/services/*`, which are a storage contract and
  intentionally NOT routed). Display sites: breakdex tabs (×2), combos title,
  move_list Arsenal title fallback + segment labels (×2), mastery_prescreen title +
  lane toggle (×2), move_category title, combo_detail breadcrumb, progress_explorer
  subject segments (×2), flow node metric, add-flow choice cards (×2).
- [x] 1.2 Extend the Global Labels setting (Settings → Visuals & Style) to both data-banks;
  a label provider resolves custom noun → default; clearing resets. Built dedicated typed
  `entityNamesProvider` (`entity_names_service.dart`, singular+plural per bank) + two
  rename tiles with singular/plural dialogs (blank field = restore default).
- [x] 1.3 Route all audited call sites through the provider (tabs, titles, empty states,
  dialogs). Long-name layout resilience rides `tighten-athlete-controls-and-stats-clarity`.
- [x] 1.4 Tests: rename renders app-wide, reset restores defaults, no stored-data mutation.
  `entity_names_test.dart` (6 cases: defaults, rename+restart, blank-clears, default-writes-
  no-override, reset, unrelated-key-untouched). `add_screen_test` updated to supply prefs.

## Phase 2: Flow-order + party default

- [x] 2.1 Add the add-flow order preference (after-metadata | edit-while-adding) and branch
  the flow routing; both orders converge on identical move records (test proves equivalence).
  Built `AddFlowOrder` enum + pure `resolveAddFlowVideoPath` (the whole behavioural delta),
  `addFlowOrderProvider` (SharedPreferences, mirrors `appModeProvider`), branched `_startClipFlow`
  (trim-first routes the picked clip through `/video-editor` before metadata; cancel falls back to
  the picked path → unchanged record), and a Settings → Practice "Add Flow" segmented picker.
  `add_flow_order_test.dart` proves record equivalence when no crop is applied + pointer-only
  divergence on a deliberate crop.
- [x] 2.2 Flip the fresh-install default to `AppMode.party` in `app_mode.dart` fallback ONLY
  for absent keys; test that a stored `anki` survives the update (data-safety). Added an explicit
  `'anki' => anki` case so only absent/unknown keys resolve to party; `app_mode_test.dart` proves
  fresh-install → party and stored-`anki` → anki (upgrade path).

## Phase 3: Settings IA + live feedback

- [ ] 3.1 Regroup Settings into one-concern sections (Practice, Appearance, Library & Data,
  System & Sync); extract sections from the 1771-LOC screen into files per section.
- [ ] 3.2 Absorb the rescoped `add-quiet-playback-and-senior-drill-ui` Phase 4: consolidate
  quiet-mode + review-composer panels, delete the dead `silentPracticePlaybackProvider`
  (tick that change's ledger in the same commit).
- [ ] 3.3 Self-confirming rows: typography row renders in its font, color rows show live
  swatches, naming row shows the live noun; verify no setting requires restart.
- [ ] 3.4 Tests: section ownership snapshot, live-application of typography/color/naming.

## Phase 4: Accessible themes

- [x] 4.1 Define deuteranopia-safe and grayscale ramps as tokens (`colors.dart` +
  `TOKENS.md` same-commit); build the two theme variants in `theme.dart`.
  Added the Okabe–Ito `deuter*` semantic tokens (7) to `colors.dart`; monochrome reuses
  the existing `mono*` grayscale surface ramp + `AppSemanticTheme.ink`. New
  `AccessiblePalette { standard, deuteranopia, monochrome }` axis (orthogonal to
  theme/brightness/viewingMode) threads through `AppTheme.light/dark/_build` and is
  persisted by `accessiblePaletteProvider`. TOKENS.md documents both ramps same-commit.
- [x] 4.2 Pair every color-carried signal (ratings, states, categories) with icon/shape/label;
  golden test under a grayscale filter.
  Double-encoding was already present and is now proven: rating buttons pair color+icon+label
  (WCAG 1.4.1), state pills pair color+label, category chips render with their name. Ratings
  are made palette-aware (follow the theme semantic ramp under an accessible palette). Scope
  call: the ramp swap applies to the app-controlled semantic signals (states + ratings); user-
  authored category colors are NOT non-destructively remapped (lossy + data-safety) — their
  name label already means "color is never alone". Verification uses a structural grayscale
  test (`accessible_palette_test.dart`: monochrome + `ColorFilter.matrix` grayscale → asserts
  4 distinct rating icons + 4 labels survive) rather than a pixel golden — no golden infra
  exists in-repo and goldens are font/platform-flaky; the structural assertion proves the
  actual requirement (non-color encodings survive color loss) more reliably.
- [x] 4.3 Settings exposure in Appearance with live preview; modes compose with existing
  theme + restore exactly on toggle-off.
  Added an "Accessibility" panel to Settings → Visuals & Style (segmented `AccessiblePalette`
  picker + description + `_AccessiblePalettePreview` showing live state pills + rating chips —
  selecting a palette rebuilds the app theme so the preview recolors in place, no restart).
  Compose/restore proven in test: `standard` theme is byte-identical to the baseline (surfaces,
  accent, semantic ramp, and user-customized state colors all return exactly on toggle-off).

## Phase 5: i18n foundation

- [x] 5.1 Wire `flutter_localizations` + `l10n.yaml` + `app_en.arb` + generated delegates
  into the shell; CI check that `flutter gen-l10n` output is committed and current.
  Added `flutter_localizations` + `generate: true` (pubspec), `l10n.yaml` (committed
  output at `lib/l10n/gen/`, `synthetic-package` dropped — dead in Flutter 3.41),
  `lib/l10n/app_en.arb`, and threaded `AppLocalizations.localizationsDelegates` +
  `supportedLocales` + `onGenerateTitle` through `MaterialApp.router`. Generated
  `lib/l10n/gen/*` committed. CI gate: `scripts/check_l10n.sh` regenerates and fails on
  drift; new `.github/workflows/ci.yml` runs it + `flutter analyze` on PRs.
  `l10n_foundation_test.dart` green (4 cases: supported-locale, appTitle, parametric
  plural composition, ICU-plural + parametric nouns).
- [x] 5.2a Extract shell + library + add + review + move-detail screens (~230 strings);
  parametric nouns compose via placeholders.
  Landed: `bottom_nav_shell` (5 tab labels), `breakdex_screen` (title), `add_screen`
  (6 form strings + parametric SAVE button + name-collision error), the flashcard-review
  surface (`flashcard_review_screen` + `create_deck_sheet`, `item_schedule_detail_sheet`,
  `mastery_prescreen`, `rating_button_row`, `schedule_review_screen`, `srs_parameters_card`,
  `state_picker_sheet`), and move detail (`move_detail_screen` + `move_detail_overlays`).
  Added 150 keys to `app_en.arb` (60 `md*`, 90 `rev*`); regenerated + committed
  `lib/l10n/gen/*`. Parametric nouns (move/combo singular+plural) compose via placeholders
  from `entityNamesProvider`, never concatenated (`mdRenameEntity`, `revEntityBoxes`,
  `mdDeleteUsedInCombos`, …); ICU plural for `revItemCount`; the pre-existing `nameTakenError`
  is reused across add + category-create. Four widgets promoted Stateless/Stateful →
  Consumer variants to reach `entityNamesProvider` (`_VideoMissingCard`, `RenameOverlay`,
  `_ReviewEmptyState`, `_ScheduleEmptyState`). `dart analyze` clean on the touched tree.
- [ ] 5.2b Extract the settings screen (the fifth of the top-five); parametric nouns compose
  via placeholders. Deferred to its own budgeted slice — settings has the densest string
  surface (appearance/accessibility panels, mode pickers) and is left unticked per the
  same-commit ledger rule.
- [x] 5.3 Adopt the no-new-hardcoded-strings review rule; add a grep gate note to the review
  checklist. Added a "Localization" non-negotiable to `openspec/AGENTS.md` review
  checklist: user-facing copy resolves through `AppLocalizations`; grep gate
  `rg "Text\('" lib/` on the diff must surface only pre-existing sites; parametric nouns
  compose via placeholders, never concatenation.

## Verification

- [ ] V.1 `dart analyze` + `flutter test` green; goldens updated deliberately.
- [ ] V.2 Patrol journey: rename data-banks → verify tab/title/dialog rendering → switch
  color-blind and monochrome modes → run a review → change flow order and add a clip
  edit-first (iOS + Android).
- [ ] V.3 Fresh-install simulator run proves party default; upgrade path proves stored mode
  survives.

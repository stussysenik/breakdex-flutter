# Tasks — Personalization & Accessibility

Ledger rule: tick each box in the same commit that lands the work.

## Phase 1: Parametric naming

- [ ] 1.1 Audit render sites of the default nouns ("Moves"/"Move", "Combos"/"Combo") —
  `rg` sweep, expect ~25 call sites; record the list in the commit.
- [ ] 1.2 Extend the Global Labels setting (Settings → Visuals & Style) to both data-banks;
  a label provider resolves custom noun → default; clearing resets.
- [ ] 1.3 Route all audited call sites through the provider (tabs, titles, empty states,
  dialogs). Long-name layout resilience rides `tighten-athlete-controls-and-stats-clarity`.
- [ ] 1.4 Tests: rename renders app-wide, reset restores defaults, no stored-data mutation.

## Phase 2: Flow-order + party default

- [ ] 2.1 Add the add-flow order preference (after-metadata | edit-while-adding) and branch
  the flow routing; both orders converge on identical move records (test proves equivalence).
- [ ] 2.2 Flip the fresh-install default to `AppMode.party` in `app_mode.dart` fallback ONLY
  for absent keys; test that a stored `anki` survives the update (data-safety).

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

- [ ] 4.1 Define deuteranopia-safe and grayscale ramps as tokens (`colors.dart` +
  `TOKENS.md` same-commit); build the two theme variants in `theme.dart`.
- [ ] 4.2 Pair every color-carried signal (ratings, states, categories) with icon/shape/label;
  golden test under a grayscale filter.
- [ ] 4.3 Settings exposure in Appearance with live preview; modes compose with existing
  theme + restore exactly on toggle-off.

## Phase 5: i18n foundation

- [ ] 5.1 Wire `flutter_localizations` + `l10n.yaml` + `app_en.arb` + generated delegates
  into the shell; CI check that `flutter gen-l10n` output is committed and current.
- [ ] 5.2 Extract shell + top five screens (library, add, review, settings, move detail)
  (~250 strings); parametric nouns compose via placeholders.
- [ ] 5.3 Adopt the no-new-hardcoded-strings review rule; add a grep gate note to the review
  checklist.

## Verification

- [ ] V.1 `dart analyze` + `flutter test` green; goldens updated deliberately.
- [ ] V.2 Patrol journey: rename data-banks → verify tab/title/dialog rendering → switch
  color-blind and monochrome modes → run a review → change flow order and add a clip
  edit-first (iOS + Android).
- [ ] V.3 Fresh-install simulator run proves party default; upgrade path proves stored mode
  survives.

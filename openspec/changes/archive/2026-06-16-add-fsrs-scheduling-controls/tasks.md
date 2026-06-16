# Tasks — Add FSRS Scheduling Controls

> Data-safety gate (applies to every task): SharedPreferences only — no DB schema change, no
> migration, no write to `fsrs_cards`. Defaults must equal the prior hardcoded constants.

## 1. Settings model & persistence
- [x] 1.1 Introduce `FsrsSettings` (desiredRetention, learningSteps, relearningSteps, maximumInterval, enableFuzzing) with a `FsrsSettings.defaults` const equal to today's constants, `copyWith`, and prefs encode/decode (retention→double, maxInterval→int, fuzzing→bool, steps→`List<int>` minutes). Keep `FsrsConfig` as the display type (alias or map from `FsrsSettings`).
- [x] 1.2 Add a prefs-backed store/reader with per-parameter clamping and default fallback (missing/out-of-range → default). — `FsrsSettings.fromPrefs` / `writeTo`, with clamp helpers.
- [x] 1.3 Unit test: defaults equal the prior hardcoded constants; round-trip encode/decode for each parameter; missing/corrupt prefs → defaults. — `test/core/models/fsrs_settings_test.dart`

## 2. Riverpod notifier
- [x] 2.1 Add `FsrsSettingsNotifier` + `fsrsSettingsProvider`, seeded from prefs (defaults when absent), with setters (`setDesiredRetention`, `setMaximumInterval`, `setFuzzing`, `setLearningSteps`, `setRelearningSteps`) and `resetToDefaults`; each setter clamps, writes prefs, updates state.
- [x] 2.2 Unit test: each setter persists and reloads; `resetToDefaults` restores constants; clamping enforced. — `test/core/providers/fsrs_settings_notifier_test.dart`

## 3. Inject settings into the scheduler
- [x] 3.1 Change `FsrsService` to build its `fsrs.Scheduler` from an injected `FsrsSettings` instead of hardcoded literals (constructor takes settings; default param = `FsrsSettings.defaults` so existing direct constructions and tests keep working).
- [x] 3.2 Make `fsrsServiceProvider` watch `fsrsSettingsProvider` and reconstruct the service when settings change, so the next review uses current values.
- [x] 3.3 Redefine `fsrsConfigProvider` to derive from `fsrsSettingsProvider` (drop the `static const` dependency) so the card reflects edits live. — `FsrsService.config` removed.
- [x] 3.4 Unit test: a `FsrsService` built from non-default settings yields a different next-due for the same card+rating than defaults (injection wired); editing settings does **not** write/alter an existing stored `fsrs_cards` row (non-destructive). — `test/core/services/fsrs_settings_injection_test.dart`

## 4. Editable SrsParametersCard (in place)
- [x] 4.1 Convert `SrsParametersCard` displays into controls: retention slider [0.70–0.97], maximum-interval control (days, ≥1), fuzzing switch, learning/relearning step presets, with concise explainer copy.
- [x] 4.2 Add a "reset to defaults" affordance.
- [x] 4.3 Wire all controls through `fsrsSettingsProvider`; ensure the card reflects current persisted values and updates immediately on edit.
- [x] 4.4 Widget test: editing the retention slider calls the notifier and the displayed value updates; reset returns to 0.85. — `test/features/flashcard_review/srs_parameters_card_test.dart`

## 5. Verification
- [x] 5.1 `flutter analyze` stays at zero issues. — "No issues found!"
- [x] 5.2 Run the FSRS + settings test suites green (incl. the new tests).
- [ ] 5.3 Manual (on-device, optional): edit retention → review a due card → confirm interval shifts; restart app → confirm persistence. **Automated proxy covered:** interval shift proven by the injection test; persistence proven by the notifier reload test; **no schema/migration triggered** is structurally guaranteed — this change adds no table/column/migration (prefs-only).
- [x] 5.4 Confirm a never-opened-controls path schedules identically to the previous build (defaults preserved). — `FsrsSettings.defaults` equals the prior constants (model test) and is the scheduler default param; the existing `fsrs_service_clock_test` still passes unchanged.

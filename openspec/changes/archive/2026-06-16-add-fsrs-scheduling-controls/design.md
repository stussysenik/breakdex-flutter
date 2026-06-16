# Design — FSRS Scheduling Controls

## Constraint that shapes every decision

Late-stage production app, deployed user data. The data model must not be abused: no schema
change, no migration, no rewrite of `fsrs_cards`. Therefore parameters live in
**SharedPreferences**, and the only runtime effect is which values the `fsrs.Scheduler` is
constructed with. This keeps the blast radius at "future scheduling math," never "stored data."

## Current state (grounding)

- `FsrsService` (`lib/core/services/fsrs_service.dart:153`) builds a single `final fsrs.Scheduler`
  in its constructor from hardcoded literals (`:164`), and exposes a `static const config`
  (`:175`) of the same values.
- `fsrsConfigProvider` (`lib/core/providers.dart:471`) returns `FsrsService.config`.
- `SrsParametersCard` reads `fsrsConfigProvider` and renders it read-only.
- `processReview()` (`:190`) calls `_scheduler.reviewCard(card, rating)` then `_dao.upsert(...)`.

## Approach

### 1. `FsrsSettings` model
Reuse the existing `FsrsConfig` shape (desiredRetention, learningSteps, relearningSteps,
maximumInterval, enableFuzzing). Add a `FsrsSettings.defaults` const equal to today's constants,
plus `copyWith` and JSON-ish (prefs) encode/decode. (Either rename `FsrsConfig` → `FsrsSettings`
or alias; keep `FsrsConfig` as the public display type to avoid churn in `SrsParametersCard`.)

### 2. Persistence — SharedPreferences, encoded primitively
- `fsrs.desiredRetention` → double
- `fsrs.maximumInterval` → int (days)
- `fsrs.enableFuzzing` → bool
- `fsrs.learningSteps` / `fsrs.relearningSteps` → `List<int>` of minutes (encode `Duration`s as
  whole minutes; decode back)
- Reads clamp/validate; any missing or out-of-range value falls back to the corresponding default.

### 3. Riverpod notifier
`FsrsSettingsNotifier extends Notifier<FsrsSettings>` (or AsyncNotifier if prefs load is async),
seeded from prefs (defaults when absent). Setters: `setDesiredRetention`, `setMaximumInterval`,
`setFuzzing`, `setLearningSteps`, `setRelearningSteps`, `resetToDefaults`. Each writes prefs then
updates state. Exposed as `fsrsSettingsProvider`.

### 4. Inject into `FsrsService` (scheduler rebuilt from current settings)
`FsrsService` takes a `FsrsSettings` and builds its scheduler from it. Because settings can change
at runtime, `fsrsServiceProvider` **watches** `fsrsSettingsProvider` and reconstructs the service
when settings change (the service is effectively stateless aside from `dao`/`clock`, so rebuild is
safe). The next `processReview` then uses the latest parameters. No in-flight card is mutated by a
settings change — only the math applied on its *next* review.

> Chosen over "mutate `_scheduler` in place via a setter" because Riverpod's watch/rebuild is the
> idiomatic seam and avoids hidden mutable state in the service.

### 5. `fsrsConfigProvider` derives from settings
Redefine `fsrsConfigProvider` to map `fsrsSettingsProvider` → `FsrsConfig`, so `SrsParametersCard`
reflects edits live. Remove the dependency on the `static const`.

### 6. Editable `SrsParametersCard`
Keep its layout; make values interactive:
- **Retention**: slider, range **0.70–0.97** (the FSRS-valid band), step 0.01, with a one-line
  explainer ("higher = more frequent reviews").
- **Maximum interval**: stepped control / slider in days, sane cap (e.g. 1–36500), default 36500.
- **Fuzzing**: switch.
- **Learning / relearning steps**: pick from a small preset set (e.g. none, [10m], [1m,10m],
  [10m,1d]) rather than a free editor in v1.
- **Reset to defaults** button.

## Validation & edge cases
- Retention clamped to [0.70, 0.97] before persisting and before constructing the scheduler
  (guards against the `fsrs` package asserting on out-of-range input).
- `maximumInterval` must be ≥ 1.
- Steps lists decode to non-negative `Duration`s; an empty list is allowed (skip learning steps)
  but the UI presets keep at least the current behavior available.
- Corrupt/missing prefs → defaults (no crash, no data effect).

## Alternatives considered
- **DB-backed settings table** — rejected: introduces a schema migration on a deployed data model
  for zero benefit over prefs. Violates the data-safety constraint.
- **Per-deck overrides** — deferred: requires extending the `decks` schema; out of scope.
- **Weight optimization from review history** — deferred: separate, larger feature.

## Verification strategy
- Unit test: defaults equal the prior hardcoded constants (proves behavior-preservation).
- Unit test: notifier persists and reloads each parameter; out-of-range/missing → defaults.
- Unit test: `FsrsService` built from non-default settings produces a different next-due than
  defaults for the same card+rating (proves injection is wired), while a settings change does
  **not** alter an existing stored card row (proves non-destructiveness).
- Manual: edit retention, review a card, confirm interval shifts; restart app, confirm persistence.

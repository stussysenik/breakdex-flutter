# Add FSRS Scheduling Controls — User-Tunable Spaced Repetition (Prefs-Only, Non-Destructive)

## Summary

Make the FSRS scheduler parameters user-editable from the review/settings surface,
instead of hardcoded constants baked into the build. Today every learner is locked to
`desiredRetention: 0.85`, `learningSteps: [10m]`, `relearningSteps: [10m]`,
`maximumInterval: 36500`, `enableFuzzing: true` — set in `lib/core/services/fsrs_service.dart:164`
and shown **read-only** by `SrsParametersCard`. This change persists those parameters in
**SharedPreferences** and injects them into `FsrsService`, and upgrades `SrsParametersCard`
to be editable in place.

## Motivation

- Retention is the single highest-leverage knob in spaced repetition: a learner who wants
  tighter recall (0.90) or fewer, longer-spaced reviews (0.80) currently cannot have it.
- The display surface already exists (`SrsParametersCard` reads `fsrsConfigProvider`), so the
  delta is small: persistence + setters + injection + edit controls.
- The app already stores user settings in SharedPreferences (categories, review mode), so this
  uses an established, low-risk pattern.

## Data safety (non-negotiable — production app with deployed data)

This change is **strictly additive and non-destructive**:

- **No database schema change. No migration.** Parameters live in SharedPreferences only.
- **Stored `fsrs_cards` rows are never modified** by this change. Editing a parameter affects
  only the *next* `Scheduler.reviewCard()` computation when a card is naturally reviewed; existing
  stability, difficulty, and due dates are untouched.
- **Defaults equal today's exact constants.** A user who never opens the controls experiences
  byte-for-byte identical scheduling. Missing/corrupt prefs fall back to those defaults.
- No user data is deleted, moved, or rewritten anywhere in this change.

## Scope

### In scope
- A persisted, global `FsrsSettings` (desiredRetention, learningSteps, relearningSteps,
  maximumInterval, enableFuzzing) backed by SharedPreferences.
- A Riverpod notifier with setters + a "reset to defaults" action.
- Inject settings into `FsrsService` so the scheduler is built from current values; the next
  review uses the latest settings.
- `fsrsConfigProvider` derives from the live settings (so the card reflects edits immediately).
- Make `SrsParametersCard` editable in place: retention slider, max-interval control, fuzzing
  toggle, learning/relearning step presets, reset button — all within safe, validated ranges.

### Out of scope (explicit non-goals)
- **No FSRS weight (parameter) optimization** — that needs a review-history optimizer; deferred.
- **No per-deck / per-category scheduling overrides** — would require a schema change; deferred.
  Scheduling stays **global**.
- No changes to stored card data, review history, or the rating flow itself.

## Relationship to other changes

- Touches the FSRS path only; does **not** modify `add-combo-journey-system`,
  `state-machine-crud`, or any storage/sync change.
- `tighten-combo-journey-and-review-polish` explicitly listed "No new review modes or FSRS
  changes" as out of scope — this change owns that FSRS surface cleanly and separately.

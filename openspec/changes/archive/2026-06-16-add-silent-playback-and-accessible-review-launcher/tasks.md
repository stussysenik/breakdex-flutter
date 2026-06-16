# Tasks - Add Silent Playback and Accessible Review Launcher

## Phase 1: Silent Playback
- [x] 1.1 Add a persisted silent-practice playback setting
- [x] 1.2 Route the setting through the shared video wrapper so move/combo/review surfaces all respect it
- [x] 1.3 Recreate video controllers when the setting changes so `mixWithOthers` is applied reliably

## Phase 2: Review UI
- [x] 2.1 Replace the review-card dot artifact with a textual count badge
- [x] 2.2 Redesign the state-based launcher into larger button-first rows with stacked counts
- [x] 2.3 Keep total-count information to a single summary placement near the primary CTA
- [x] 2.4 Tighten haptic feedback on the launcher's primary actions

## Phase 3: Validation
- [x] 3.1 Add/update provider tests for the silent-practice setting
- [x] 3.2 Add/update widget tests for the review-card counter and launcher layout
- [x] 3.3 Run focused Flutter tests and analyze on touched files

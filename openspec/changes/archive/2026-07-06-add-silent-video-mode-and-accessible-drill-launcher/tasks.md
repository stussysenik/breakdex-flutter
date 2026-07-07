# Tasks — Add Silent Video Mode & Accessible Drill Launcher

## Phase 1: Playback Preference
- [ ] 1.1 Add a persisted silent-video-mode preference
- [ ] 1.2 Apply the preference in the shared video player using `mixWithOthers`
- [ ] 1.3 Recreate active controllers safely when the preference changes
- [ ] 1.4 Surface the preference in Settings with concise explanatory copy

## Phase 2: Review Chrome
- [ ] 2.1 Remove the dot overlay artifact from the active review card
- [ ] 2.2 Replace it with a simple textual progress badge
- [ ] 2.3 Keep first-look and assessment-stage behavior unchanged otherwise

## Phase 3: Drill Launcher
- [ ] 3.1 Redesign state rows into larger button-like tiles
- [ ] 3.2 Move the total into a compact summary near the primary CTA
- [ ] 3.3 Add stronger haptic feedback to launcher interactions

## Phase 4: Validation
- [ ] 4.1 Update provider/widget tests for the new preference and review UI
- [ ] 4.2 Run focused Flutter tests
- [ ] 4.3 Run analyzer on touched files

# Tasks — Clarify Review Loop, Media Cleanup & Color Customization

## Phase 1: Review Loop
- [ ] 1.1 Make state-based review launcher counts due-only instead of total-by-state
- [ ] 1.2 Keep brand-new entities without an FSRS row launchable as `New`
- [ ] 1.3 Replace swipe-preview review navigation with a single centered reveal-first card
- [ ] 1.4 Update move review writes so visible state follows the FSRS result
- [ ] 1.5 Reduce learning-step aggressiveness and verify interval previews still match
- [ ] 1.6 Add/update provider tests for due-only and missing-card behavior
- [ ] 1.7 Pause playback when media becomes covered, backgrounded, or non-primary
- [ ] 1.8 Preserve the active card when live review data refreshes mid-session

## Phase 2: Sync & Media Cleanup
- [ ] 2.1 Reconcile `moves.learningState` from synced `fsrs_cards` after pull
- [ ] 2.2 Preserve pending `videoSynced=false` state across later metadata writes
- [ ] 2.3 Remove remote uploaded video objects during delete sync
- [ ] 2.4 Ensure move/combo delete flows clean local video files and thumbnails
- [ ] 2.5 Add/update tests for sync reconciliation and relative-path cleanup
- [ ] 2.6 Surface source and album filenames on move detail using the app-managed naming scheme

## Phase 3: Settings Colors
- [ ] 3.1 Add a reusable arbitrary color editor control
- [ ] 3.2 Replace preset-only accent and rating color pickers with the reusable editor
- [ ] 3.3 Use the same editor for category color creation/rename flows
- [ ] 3.4 Add persistence tests for arbitrary ARGB values

## Phase 4: Validation
- [ ] 4.1 Run focused Flutter tests after each slice
- [ ] 4.2 Run analyzer on touched files
- [ ] 4.3 Confirm OpenSpec scope still matches the integrated change set

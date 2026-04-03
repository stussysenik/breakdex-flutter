# Tasks — Add Quiet Playback And Senior-Friendly Drill UI

## Phase 1: Quiet Playback
- [ ] 1.1 Add a persisted app-wide `Keep music playing` preference
- [ ] 1.2 Route the preference through the shared video player wrapper
- [ ] 1.3 Reinitialize active players when the preference changes so audio mixing takes effect immediately
- [ ] 1.4 Add provider and settings-widget tests for the preference

## Phase 2: Review Cleanup
- [ ] 2.1 Replace the dotted in-session progress overlay with a compact count badge
- [ ] 2.2 Keep the current reveal/assess loop unchanged otherwise
- [ ] 2.3 Update review-card widget tests for the new overlay

## Phase 3: Drill Launcher
- [ ] 3.1 Redesign the state rows as larger count-first buttons
- [ ] 3.2 Move the total into a quieter equation-style summary below the rows
- [ ] 3.3 Keep launch haptics and due-only behavior intact
- [ ] 3.4 Update the mastery prescreen widget test

## Phase 4: Settings Cleanup
- [ ] 4.1 Fold review card/playback and review-state controls into one review settings panel
- [ ] 4.2 Remove dead duplicate review-state settings widgets

## Phase 5: Validation
- [ ] 5.1 Run focused Flutter tests for providers, review card, settings, and mastery prescreen
- [ ] 5.2 Run `flutter analyze` on touched files

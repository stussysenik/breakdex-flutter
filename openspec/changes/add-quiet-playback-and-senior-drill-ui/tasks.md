# Tasks — Add Quiet Playback And Senior-Friendly Drill UI

## Phase 1: Quiet Playback
- [x] 1.1 Add a persisted app-wide `Keep music playing` preference (landed `46c604c`)
- [x] 1.2 Route the preference through the shared video player wrapper (landed `46c604c`)
- [x] 1.3 Reinitialize active players when the preference changes so audio mixing takes effect immediately (landed `46c604c`)
- [x] 1.4 Add provider and settings-widget tests for the preference (landed `46c604c`)

## Phase 2: Review Cleanup
- [x] 2.1 Replace the dotted in-session progress overlay with a compact count badge (landed `46c604c`)
- [x] 2.2 Keep the current reveal/assess loop unchanged otherwise (landed `46c604c`)
- [x] 2.3 Update review-card widget tests for the new overlay (landed `46c604c`)

## Phase 3: Drill Launcher
- [x] 3.1 Redesign the state rows as larger count-first buttons (landed `46c604c`)
- [x] 3.2 Move the total into a quieter equation-style summary below the rows (landed `46c604c`)
- [x] 3.3 Keep launch haptics and due-only behavior intact (landed `46c604c`)
- [x] 3.4 Update the mastery prescreen widget test (landed `46c604c`)

## Phase 4: Settings Cleanup
- [x] 4.1 Fold review card/playback and review-state controls into one review settings panel (landed `46c604c`)
- [x] 4.2 Remove dead duplicate review-state settings widgets (landed `46c604c`)

## Phase 5: Validation
- [x] 5.1 Run focused Flutter tests for providers, review card, settings, and mastery prescreen (landed `46c604c`)
- [x] 5.2 Run `flutter analyze` on touched files (landed `46c604c`)

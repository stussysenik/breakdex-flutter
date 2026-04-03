# Add Quiet Playback And Senior-Friendly Drill UI

## Summary

Add an app-wide quiet playback mode that keeps external music playing while Breakdex videos stay muted, remove the dotted review-progress artifact from the immersive card, and redesign the Drill launcher around larger, count-first buttons with stronger tactile feedback.

## Motivation

The current review launcher is still visually dense for a quick drill flow, and the in-session overlay still shows small progress dots that read like debug noise instead of useful guidance. Separately, athletes need a reliable "music-first" mode where they can keep Spotify or Apple Music running while reviewing clips. Settings should expose that behavior cleanly without growing into more fragmented review-state controls.

## Scope

### In scope
- Persisted app-wide quiet playback preference
- Video player integration that mutes app video audio and enables audio mixing for external music
- Compact review settings organization with the quiet playback toggle
- Removal of the review-overlay progress dots in favor of a single count badge
- Larger state-launch buttons, aligned count column, and a quieter total summary on the Drill launcher
- Targeted tests for the new setting and updated review/drill UI

### Out of scope
- A full move-semantics settings redesign
- Per-screen custom audio policies outside shared video playback
- Reworking deck browsing beyond the state-based launcher surface

## Capabilities

1. `quiet-playback` — app videos can stay muted while other audio apps keep playing
2. `review-progress-cleanup` — review cards show one clear session counter instead of dotted preview artifacts
3. `senior-drill-launcher` — larger, clearer launch targets with aligned counts and restrained summary text

## Dependencies

- Shared `video_player` wrapper in `lib/shared/widgets/video_player_widget.dart`
- Existing review settings persistence via Riverpod + `SharedPreferences`
- Existing state-based drill launcher in `lib/features/flashcard_review/widgets/mastery_prescreen.dart`

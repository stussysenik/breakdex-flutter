# Add Silent Playback and Accessible Review Launcher

## Summary

Add an app-level silent practice mode that keeps Breakdex videos muted while allowing external music to keep playing, and simplify the review launcher into a larger, button-first layout with clearer counts and stronger tactile feedback. At the same time, remove the remaining dot-based progress artifact from the active review card and replace it with a readable count badge.

## Motivation

Breakdex is a practice tool, so the review flow needs to feel physically obvious and low-friction. Right now the launcher still leans on smaller, denser state rows, and the active review card still shows dot progress that reads like a visual artifact instead of useful guidance. Playback also lacks a true "practice silently while listening to music" mode, even though that is a common athlete workflow.

The product contract for this slice is:
- Breakdex videos can run silently without stomping on external music.
- Review progress is communicated with readable counts, not decorative dots.
- Due-state launching feels like a set of large, explicit actions rather than a compact dashboard.
- Settings density improves by keeping the new mute control inside the existing review-card configuration surface instead of adding another long section.

## Scope

### In scope
- Persisted silent-practice playback preference
- External-audio-friendly video controller initialization for Breakdex video surfaces
- Forced mute while silent mode is on
- Removal of the review-card dot indicator in favor of a readable count badge
- Larger state-launch buttons with vertically stacked count treatment
- Stronger haptic feedback on primary review-launch interactions
- Focused test coverage for settings persistence and launcher/review-card rendering

### Out of scope
- A full redesign of every Settings section
- Changes to rating logic, FSRS scheduling, or review state semantics
- Desktop/web-specific audio-session behavior beyond what `video_player` already supports

## Capabilities

1. `silent-practice-playback` - app videos stay muted and initialize with external-audio-friendly playback settings
2. `accessible-review-launcher` - larger button-first drill launcher with readable counts and clear total placement
3. `review-progress-counter` - replace dot artifacts with a compact textual session counter

## Dependencies

- Existing `video_player` wrapper stack (`RobustVideoPlayer` -> `VideoPlayerWidget`)
- Existing Riverpod/shared-preferences settings infrastructure
- Existing review launcher and review-card components

# Add Silent Video Mode & Accessible Drill Launcher

## Summary

Add an app-level silent video mode that keeps Breakdex clips muted so athletes can listen to their own music while drilling. At the same time, simplify the active review chrome by removing the dot overlay artifact and redesign the state-based drill launcher into a larger, button-first surface with clearer count placement and stronger tactile feedback.

## Motivation

The current playback model assumes the app's clip audio should be active whenever a video plays. That clashes with a common training flow where the athlete wants to keep background music running and use Breakdex as a silent visual coach. The review session also still carries a dot-based overlay that reads like a leftover preview artifact instead of deliberate progress UI. Finally, the drill launcher is still too dense and too subtle for high-frequency use on device; it should favor larger tap targets, clearer grouping, and a single obvious action path.

## Scope

### In scope
- App-level silent video mode persisted in settings
- Use `video_player` audio-mix behavior so muted app playback does not interrupt external music where supported
- Apply silent mode consistently to review, move detail, combo detail, move list creation, and analysis playback surfaces through the shared player
- Remove the review-session dot artifact and replace it with a simple progress counter badge
- Redesign the state-based drill launcher into larger, button-like rows with quieter copy and clearer total placement
- Add stronger haptic feedback on key drill/review actions
- Focused tests for playback preferences and review launcher/review card behavior

### Out of scope
- Full settings-page IA overhaul outside the touched review/playback surfaces
- Replacing all app buttons with a new shared component system
- Native audio-session customization outside what the Flutter `video_player` plugin already supports

## Capabilities

1. `silent-video-mode` — app videos can stay muted while external audio continues
2. `review-progress-cleanup` — remove dot artifacts and use a cleaner session progress badge
3. `accessible-drill-launcher` — large state buttons, explicit totals, and stronger tactile feedback

## Research Notes

- Flutter `video_player` exposes `VideoPlayerOptions.mixWithOthers`, and the plugin's iOS/macOS/Android implementations route that option to platform audio-session behavior.
- Flutter's haptic APIs map `selectionClick` and `mediumImpact` to the platform-native feedback generators on iOS and Android.
- Android accessibility guidance recommends touch targets of at least 48 x 48 dp with spacing between them; the launcher changes should stay comfortably above that floor.

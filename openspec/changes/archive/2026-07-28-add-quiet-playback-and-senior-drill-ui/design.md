# Add Quiet Playback And Senior-Friendly Drill UI — Design

## Research Notes

- Flutter's official `video_player` package exposes `VideoPlayerOptions.mixWithOthers`, which is the right path for letting app playback coexist with external audio.
- Apple exposes `AVAudioSession.CategoryOptions.mixWithOthers` for this same audio-session behavior on iOS.
- Flutter's `HapticFeedback` API maps cleanly to selection, medium-impact, and success feedback, which is enough for the drill launcher and review flow without adding a custom haptics abstraction for this slice.

## Quiet Playback

### Product behavior
When `Keep music playing` is enabled, Breakdex video surfaces should:
- start muted
- keep external audio apps uninterrupted
- continue using the same shared playback coordinator so only one Breakdex surface plays at a time

### Persistence
The preference should live in `SharedPreferences` as a single app-wide boolean because it affects every shared video surface, not only review cards.

### Player integration
`VideoPlayerWidget` should become the single integration point:
- initialize `VideoPlayerController.file` with `VideoPlayerOptions(mixWithOthers: quietModeEnabled)`
- force effective volume to `0` while quiet mode is enabled
- reinitialize the controller when the preference changes so the audio-session option actually takes effect for the current clip
- preserve position and play/pause state during that reinitialization

Local mute controls may still exist, but quiet mode remains authoritative while enabled.

## Review Progress Cleanup

The immersive review overlay should stop showing tiny dots. Replace them with a single compact `current of total` badge centered in the top overlay. This preserves orientation without implying swipe-preview navigation.

## Drill Launcher

### Layout
The state-based launcher should use:
- one clear section title (`Moves` / `Combos`)
- three large vertical state buttons
- aligned trailing counts for fast scanning
- one restrained equation-style total below the rows
- one large bottom action button

### Interaction
- state rows stay tappable for direct launch into a single state
- the bottom CTA still launches the combined due queue
- haptics remain on selection/start actions, with medium impact for launch

### Visual language
Keep the current design system, but reduce color noise:
- use subtle state-color accents instead of full colored cards
- increase target size and spacing instead of adding more decorative labels
- rely on typography and alignment for hierarchy

## Settings Information Architecture

The review settings surface should stay in one panel:
- quiet playback + first-look toggles in one compact list
- state name/color editing in the same panel, below the card/playback toggles

This removes extra review-panel chrome without hiding the actual controls.

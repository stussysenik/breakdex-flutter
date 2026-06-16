# Add Silent Playback and Accessible Review Launcher - Design

## Research Basis

This slice follows platform guidance instead of inventing a custom interaction model:

- Flutter's `HapticFeedback` APIs map directly to native feedback generators, including selection and impact styles.
- Flutter's `video_player` exposes `VideoPlayerOptions.mixWithOthers`, which is the correct cross-platform control for allowing external audio to continue when the app does not need exclusive playback.
- Apple's Assistive Access guidance emphasizes large controls, streamlined pathways, and avoiding hidden or decorative interactions.
- Android accessibility guidance recommends touch targets of at least `48dp x 48dp`, with larger targets preferred.

## Silent Practice Playback

### Product behavior
When silent practice mode is enabled:
- Breakdex video surfaces stay muted
- video playback should initialize in a mode that allows external music/audio to continue
- inline mute controls should not compete with the global silent mode

### Implementation shape
Persist a single boolean preference and feed it through the shared video wrapper stack. `VideoPlayerWidget` should recreate its controller when the preference changes so controller-level `VideoPlayerOptions.mixWithOthers` is applied consistently.

Effective playback rules:
- `effectiveMuted = widget.muted || silentPracticeMode`
- `mixWithOthers = silentPracticeMode`

This keeps the feature deterministic and avoids mixing Breakdex audio with music when the learner explicitly wants silent practice.

## Review Progress Counter

The active review card should not use dot progress. Dots read as preview chrome rather than actionable information, especially against video. Replace them with a compact textual badge like `1 of 3`, keeping the close button intact.

This keeps progress legible while reducing visual noise and avoiding color or shape memory.

## Accessible Review Launcher

### Layout principles
- One primary concept per tap target
- Large rows with clear labels and stacked count treatment
- Minimal dependency on state color for comprehension
- Total count placed once, near the launch CTA, not repeated as a chip and subtitle

### Component shape
Each state row becomes a large tappable button with:
- state label
- large numeric count
- small singular/plural count caption

The aggregate total stays below the state rows as a quiet equation summary, followed by the primary launch button.

### Haptics
- segmented toggles: `selectionClick`
- direct state launch: stronger impact
- "review all" launch: stronger impact

This matches the action hierarchy without making every small interaction feel heavy.

## Settings Density

Keep the new silent practice toggle inside the existing review card settings section so the Settings page does not get longer. The review-state rename/color controls remain consolidated into one list-based section.

# Add Silent Video Mode & Accessible Drill Launcher — Design

## Silent Video Mode

### Product behavior
Silent video mode is a user preference, not a per-card surprise toggle. When enabled, Breakdex clips should:
- initialize with muted volume
- request audio mixing so external music is not interrupted where the platform/plugin supports it
- remain visually playable without exposing contradictory local unmute affordances

### Integration point
The shared `VideoPlayerWidget` already centralizes controller creation, volume updates, fullscreen handoff, and playback coordination. The new preference should be read there so every playback surface inherits the same rule instead of reimplementing it in each feature screen.

### Reconfiguration
`mixWithOthers` is configured when the controller is created. If the silent-mode preference changes while a clip is mounted, the shared player should recreate the controller, restore the previous position, and resume playback when safe.

## Review Progress Chrome

The session overlay should stop rendering dot progress. Replace it with a compact textual counter badge (`1 of 3`) centered in the top scrim. This keeps orientation without reading like a carousel or preview artifact.

## Accessible Drill Launcher

### Layout
The state-based launcher should favor a single-column stack of large pressable rows:
- left: review-state label
- right: large count
- full-row tap target
- no explanatory subcopy per state

### Total placement
The collective total belongs directly above the primary action, where it can confirm scope without competing with the state rows. A compact equation-style summary (`1 + 1 + 1 = 3`) keeps the relationship visible without adding a separate badge.

### Haptics
- lane toggles: `selectionClick`
- state-row selection: `lightImpact`
- start session / assess transition: `mediumImpact`

These stay purposeful and task-oriented instead of firing on every visual change.

## Validation

Add or update tests for:
- silent-mode preference persistence
- review card progress badge rendering
- launcher copy/count layout expectations

Run analyzer plus focused Flutter tests after implementation.

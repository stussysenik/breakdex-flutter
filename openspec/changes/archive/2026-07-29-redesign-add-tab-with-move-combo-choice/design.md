# Design: Add Tab Move/Combo Choice

## Context

The "Add" tab (`/add`, bottom nav index 1) currently hosts `AddScreen`, which presents a single "Select a Clip" button. Tapping it immediately launches the video picker sheet, then a metadata sheet, then calls `MoveCreationService.createMove()`. There is no path to create a combo from this tab.

Combo creation lives in `CreateComboScreen` at the modal route `/create-combo`. It is reachable only via the Breakdex tab → Combos → FAB. This is a discoverability problem: the dedicated "Add" tab — the app's central "create something new" surface — cannot create combos.

The Breakdex hub (`BreakdexScreen`) already uses a two-tile stacked layout pattern for "Moves" and "Combos" navigation. This same mental model — two clearly-labeled entry points — is the right pattern for the Add tab.

## Goals / Non-Goals

**Goals:**
- Replace the single-button `AddScreen` with a two-option choice layout
- "Create Move" launches the existing clip-import flow (video picker → metadata → creation) with a new count step
- "Create Combo" navigates to the existing `CreateComboScreen` modal
- The AppBar becomes context-appropriate ("Add" instead of "Add Move")
- Each move stores a `count` (number of beats, 1–16) used for proportional beat grid visualization
- The combo builder shows a **beat grid** — proportional colored blocks per move, count axis, timeline, and summary stats
- Toggle to show/hide the beat grid (incremental rollout)
- Preserve all existing haptic feedback, duplicate checking, and validation

**Non-Goals:**
- Changing the `RobustVideoPlayer` — reused as-is with `autoPlay: true`
- Changing the `MoveCreationService` core logic — only added `count` parameter
- Modifying the bottom nav shell or routing architecture
- Audio analysis for BPM detection (hardcoded 100 BPM, tuneable later)

## Decisions

### 1. Stacked card layout (not side-by-side)

The Breakdex hub already uses stacked full-width tiles for Moves / Combos entry. This pattern works well in portrait mobile and is already familiar to users. Side-by-side would compress the tap targets too much on smaller screens.

Each card follows the `AppSurfaces.panel(raised: true, radius: AppRadius.md)` pattern used across the app, with:
- A large icon (48px, primary color with 0.7 alpha)
- Title text (titleMedium)
- Descriptive subtitle (bodySmall, secondary color)
- The entire card is the tap target — no internal button needed

### 2. Move creation via existing flow with count step

The `_startClipFlow()` method and `_ClipMetadataForm` widget in `AddScreen` are preserved. They handle the "Create Move" card tap. A new **count step** is added to `_ClipMetadataForm` (after name and category): a ± stepper (1–16, default 4) labeled "Counts" / "N beats". The count is stored on the Move model.

### 3. Combo creation via route push (not inline)

Rather than embedding `CreateComboScreen` inline or reimplementing combo creation, the "Create Combo" card pushes `/create-combo` via `context.push<String>('/create-combo')`. This reuses the full CreateComboScreen including its move picker, reorderable list, save logic, and edit-mode support.

### 4. Beat grid as proportional block visualizer

The beat grid replaces the need for guesswork about sequence composition. It shows:
- **Blocks**: each move rendered as a colored block sized proportionally to its count (e.g., a 4-count move is 2× wider than a 2-count move)
- **Count axis**: numeric labels (1, 2, 3…) beneath the blocks
- **Timeline**: a playback-progress bar with a playhead dot at the active move's midpoint
- **Time labels**: `0:00` and `0:14` (derived from count × 60/BPM)

Colors cycle through a 4-color palette (#E45D7A, #2F6BFF, #1F8A70, #B7791F) matching the app's semantic color system.

### 5. BPM hardcoded at 100

100 BPM is standard breaking tempo. 1 count = 0.6 seconds. Total time = total counts × 0.6s. Future: user-configurable BPM in settings.

### 6. Count range 1–16

Most breaking moves are 2, 4, or 8 counts. The stepper allows 1–16 with a ceiling to prevent absurdly long single moves. The beat grid collapses axis labels beyond 16 ticks (shows "…N").

### 7. Toggle for incremental rollout

The beat grid overlay has an on/off toggle at the top of the combo builder. Default: ON. This lets the feature ship immediately and be turned off if the concept needs iteration.

### 8. Set concept (future)

The database already has `sets` and `set_items` tables (v15) supporting hierarchical composition: a Set can contain moves, combos, or other sets. No UI exists yet; this is acknowledged as the next logical abstraction layer after beat grids stabilize.

## Risks / Trade-offs

- **Risk: Grid clutter at high counts** — If a combo has 32+ counts, the grid blocks become very small and the count axis overflows. **Mitigation**: Axis caps at 16 labels; grid uses `Expanded(flex: count)` so proportions remain correct even at high totals.
- **Trade-off: One extra tap for move creation** — Previously, tapping the Add tab and then "Select a Clip" was a single action. Now it's: tap Add tab → tap "Create Move" → same flow. **Accepted**: The added clarity of the choice justifies the one extra tap.
- **Risk: `_ClipMetadataForm` is a private widget** — It's defined inside `add_screen.dart` as a private class. **Accepted**: This is a simple change to one file; extraction is premature.

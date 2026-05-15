# Redesign Add Tab with Move/Combo Choice

## Why

The dedicated "Add" tab (bottom nav index 1) is currently a one-purpose screen — it only lets users import a video clip to create a move. Combo creation is hidden behind a separate modal route (`/create-combo`), reachable only by navigating to Breakdex → Combos → tapping the FAB. This means the "Add" tab is a dead-end for combos: a user who lands there wanting to build a sequence has no path forward. The mental model should be "I want to add something" → "Is it a move or a combo?" — then enter the appropriate flow. Right now that fork doesn't exist.

## What Changes

- Replace the single "Select a Clip" button on `AddScreen` with a two-option layout: **Create Move** and **Create Combo**
- "Create Move" triggers the existing clip-import flow (VideoPickerSheet → MetadataSheet → MoveCreationService) with a **new count step** (2–16 beats per move)
- "Create Combo" navigates to the existing `CreateComboScreen` via the `/create-combo` modal route
- **Beat Grid** overlay on `CreateComboScreen` — a proportional visual strip showing each move sized by its count, with a timeline and count axis
- **Summary bar** on `CreateComboScreen` — total moves, counts, and estimated time (@ 100 BPM)
- **Toggle** to show/hide the beat grid overlay (incremental rollout)
- **`count` column** added to Moves table (database migration v16→v17, default 4, range 1–16)
- **Set concept** scaffolding exists in the database (sets + set_items tables at v15); not yet surfaced in UI but the data model supports combos-of-combos composition

## Capabilities

### New Capabilities

- `add-tab-move-combo-choice`: The Add tab presents a user-facing choice between creating a move (clip import) or a combo (sequence builder), replacing the previous clip-only flow.
- `move-count-metadata`: Each move stores a count (number of beats), set during move creation and used for beat grid visualization.
- `combo-beat-grid`: The combo builder visualizes the sequence as proportional count-blocks with a timeline and summary stats.

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

- **`lib/features/add/add_screen.dart`** — Replaced single-button layout with two choice cards; added count step to metadata form; navigates to `/create-combo`
- **`lib/features/create_combo/create_combo_screen.dart`** — Added beat grid overlay, toggle, summary bar, count display in sequence items
- **`lib/core/services/move_creation_service.dart`** — Accepts and stores `count` on move creation
- **`lib/core/models/move_creation.dart`** — Added optional `count` field (default 4) to `CreateMoveRequest`
- **`lib/core/database/tables/moves.dart`** — Added `count` column (int, default 4)
- **`lib/core/database/database.dart`** — Schema v16→v17 migration
- **`lib/core/models/reviewable_item.dart`** — Updated placeholder Move constructor with `count: 4`
- **`lib/core/navigation/app_router.dart`** — No route changes; existing `/create-combo` route reused

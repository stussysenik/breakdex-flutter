# Design — Tighten Combo Journey & Review Polish

## Root causes found (session 2026-06-11)

These are the diagnosed defects driving this change. Recorded so a resuming session doesn't re-derive them.

### 1. Plan-a-combo silently never persisted
`_PlanPickerSheet` (lib/features/combos/combos_screen.dart) popped itself, **then** ran
`showDatePicker(...).then(...)` against the popped sheet's `context`/`ref`. By the time the
user picked a date, `context.mounted == false` → early return → **no insert, no error**.
The date picker visibly worked, so the feature felt "stale" rather than broken.

**Fix pattern:** modal sheets only *return* a selection (`Navigator.pop(context, comboId)`).
All writes happen in the long-lived caller (`planComboFlow(context, ref, {presetDate})` in
combos_screen.dart). This is the house rule for every picker sheet: **sheets select, callers
write.**

### 2. Planned days invisible on calendar
`_dayColor` painted future planned days `primary.withValues(alpha: 0.05)` — indistinguishable
from empty. Plans inserted via the (working) combo-detail "Plan for a day…" action therefore
"didn't show up". Fix: planned days get a visible ring + up-to-3 plan count dots beneath the
day number; past activity keeps heat fill; today keeps the solid ring.

### 3. Assess stage removed the move switcher
`ReviewCard` passes `showMetadataPanel: !_assessmentStageVisible`; `InstrumentPanel` returns
`SizedBox.shrink()` when hidden — taking the interactive BeatGrid with it. The replacement
`_ComboBeatAssessment` built `BeatGridItem`s **without `onTap`**. Fix: pass `onStepSelected`
through to the assessment beat grid (driving the same `_comboStepIndices` map so the video
swaps too). The grid is interactive in both stages.

### 4. Beat grid visual debt
- Step labels at fontSize 7 — unreadable.
- Tick row used fixed 16px-wide cells laid LTR while blocks are flex-proportional — ticks
  never aligned with blocks.
- A static 4px gray "timeline bar" carried no information.
- `activeIndex` constructor param was dead (per-item `isActive` is the real input).

### 5. Gallery picker mismatches
- "IMPORT N VIDEOS" button allowed multi-select but imported only `_selectedIds.first`.
- Tile metadata = filename only, 8px. No date, no size/duration.
- Import overlay shows stage + % but iCloud download progress can stall silently; retry only
  via generic snackbar.

## Beat grid redesign

One shared `BeatGrid` serves combo detail, instrument panel, and assessment stage.

```
BEAT GRID                                    16 BEATS
┌──────────────┬──────┬────────────────────┬──────┐
│ 4            │ 2    │ 8                  │ 2    │   blocks: flex = beat count,
│ Toprock      │ Drop │ Windmill           │ Fr.. │   height 48, active = primary
└──────────────┴──────┴────────────────────┴──────┘
│ ╷ ╷ ╷ │ ╷ ╷ ╷ │ ╷ ╷ ╷ │ ╷ ╷ ╷ │              ticks: one per beat, Expanded
1       5       9       13                        (same flex math → always aligned),
                                                  every 4th tick emphasized (4/4 time)
```

Decisions:
- **Proportion = width.** flex by `count` (unchanged), but blocks get height 48 and an
  AnimatedContainer so active-state changes feel alive.
- **Legibility floor.** Count at 13px bold tabular; label 10px; `LayoutBuilder` hides the
  label (keeps count) when a block is narrower than ~44px instead of rendering 7px text.
- **Ticks align by construction.** Tick row is a `Row` of `total` `Expanded` children — the
  same flex space as the blocks — emphasized every 4 beats (breaking is counted in 4s).
  Beat numbers render under emphasized ticks only.
- **No dead ink.** The static gray bar is removed.
- **Interactive everywhere.** `onTap` wired in all three render sites; blocks are the hit
  targets (48px tall row ≥ 44pt HIG minimum).
- Colors stay within the design language: primary accent + surface containers, no invented
  per-move palette. The `ComboStepLine` numbered-node switcher (create-combo, party) is
  unchanged except its existing name+beats label support.

## Gallery picker design

- **Videos only:** Photo Library fetch is already `PHAssetMediaType.video`-scoped native-side;
  Dart keeps the `duration > 0` guard for library assets. App-storage tab filters by extension.
  iCloud assets are included (`includeHiddenAssets false`, network access allowed on demand).
- **Tile overlay (logical order):** primary line = duration + size (what you scan for when
  picking a take), secondary line = date, tertiary = filename. Date/size resolved lazily per
  tile; size via `PHAssetResource` may be unknown until download → render "—" rather than 0.
- **Selection semantics:** single-select (radio behavior). Tapping a second tile moves the
  selection. Button reads "IMPORT VIDEO". (True batch import is out of scope.)
- **Determinate progress:** the import overlay binds to `StorageActionMachine.progress`
  stages; the iCloud download stage must forward the native `progressHandler` fraction so the
  bar moves during download (the 0→100 jump came from only stamping stage boundaries).
  A stall detector logs via StageLogger after 2s without progress advance (reuses the
  journey-change reactivity rule).
- **Edge network:** download timeout surfaces a retry affordance in the overlay itself (not a
  snackbar); cancel always available; retry re-requests the same asset.

## Validation strategy

- Widget tests: plan flow (insert lands; calendar/dot rendering), beat grid (tap targets in
  assess stage; label-hiding at narrow widths), picker sheet (single-select semantics).
- `flutter analyze` + `flutter test` green as the gate for every phase.
- FlowDeck simulator smoke (simulator already has videos): create combo → jot → tag → plan
  (queue + calendar day + week visibility) → review session combo card → assess stage step
  switching → gallery import with progress → export/trim.

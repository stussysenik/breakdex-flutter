## 1. Redesign AddScreen layout

- [x] 1.1 Replace single "Select a Clip" button with two stacked choice cards ("Create Move" and "Create Combo") using `AppSurfaces.panel` pattern
- [x] 1.2 Add distinct icons per card: `video_call_rounded` for Move, `linear_scale_rounded` for Combo
- [x] 1.3 Add descriptive subtitles per card explaining what each option creates
- [x] 1.4 Change AppBar title from "Add Move" to "Add"

## 2. Wire up creation flows

- [x] 2.1 Connect "Create Move" card tap to existing `_startClipFlow()` method
- [x] 2.2 Connect "Create Combo" card tap to `context.push('/create-combo')`
- [x] 2.3 Add `go_router` import for navigation to combo screen

## 3. Add count per move

- [x] 3.1 Add `count` column to Moves table (int, default 4, migration v16→v17)
- [x] 3.2 Add count field to `CreateMoveRequest` model
- [x] 3.3 Pass count through `MoveCreationService.createMove()` to database insert
- [x] 3.4 Add count stepper (1–16, default 4) to `_ClipMetadataForm`
- [x] 3.5 Update placeholder Move constructor in `reviewable_item.dart` with `count: 4`

## 4. Beat grid on CreateComboScreen

- [x] 4.1 Add `_showBeatGrid` toggle state (default: true)
- [x] 4.2 Build toggle row widget using `AppSurfaces.panel`
- [x] 4.3 Build beat grid widget with proportional colored blocks (`Expanded(flex: count)`)
- [x] 4.4 Build count axis labels (1…N, capped at 16)
- [x] 4.5 Build timeline with elapsed bar and playhead (midpoint of active move)
- [x] 4.6 Build summary bar (moves, counts, time @ 100 BPM)
- [x] 4.7 Show count per move in sequence list subtitle

## 5. Verify

- [ ] 5.1 Verify move creation flow works end-to-end from the Add tab (video picker → metadata → save) with count
- [ ] 5.2 Verify combo creation launches correctly and returns to Add tab after save
- [ ] 5.3 Verify duplicate name checking still works for moves
- [ ] 5.4 Verify haptic feedback still fires on category selection and submission
- [ ] 5.5 Verify beat grid renders correctly with varying move counts
- [ ] 5.6 Verify beat grid toggle hides/shows the overlay
- [ ] 5.7 Run existing tests and confirm no regressions
- [ ] 5.8 Run `flutter analyze` with zero errors

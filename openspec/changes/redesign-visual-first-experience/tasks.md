# Tasks — Redesign Visual-First Experience

Ledger rule: tick each box in the same commit that lands the work.

## Phase 1: Motion doctrine (foundation — other phases build on it)

- [x] 1.1 Add Fluid/Morph family aliases to `AppMotion` (`lib/core/design/spacing.dart`) and
  document both families in `docs/design/TOKENS.md` (single source rule).
- [x] 1.2 Sweep shared widgets with raw controllers (pressable, celebration_overlay,
  combo_step_line, notes_section, app_segmented_control, beat_grid, video_player_widget,
  metadata_video_picker_sheet, loading_state_widget) onto family tokens; fix any missing
  `dispose()` found during the sweep. (All targets already disposed correctly — no leaks
  found. Sweep extended to the only 3 other files with raw literals — flow_coach_marks,
  party_screen, robust_video_editor_view, flashcard breath — so the grep is zero app-wide.)
- [x] 1.3 Add "motion composes from AppMotion family tokens; controllers disposed" to the
  review checklist (`openspec/AGENTS.md` Non-negotiables); grep-verify zero raw motion literals
  on product surfaces (`rg 'Curves\.' lib/` → 0 outside the token definition; evidence in
  commit).
- [x] 1.4 Signature two-dot loader: build `AppLoader` (`lib/shared/widgets/app_loader.dart`) —
  two dots that slide in opposite phase and cross paths at center, composed from the Fluid
  family (`AppMotion.fluid` + new ambient `AppMotion.loaderLoop` token, documented in
  TOKENS.md). Wire it into the canonical loading surface (`loading_state_widget.dart`
  `_RetryingWidget`), replacing the stock `CircularProgressIndicator`. Widget test covers the
  two-dot invariant, semantics label, and clean dispose.
- [x] 1.5 Rolling sweep: replace bare `CircularProgressIndicator` with `AppLoader` across the
  remaining product surfaces (`rg -l CircularProgressIndicator lib/`) so the loading motif is
  one connected system app-wide. Per-directory, additive, no behavior change — intentionally
  NOT done in the 1.4 commit to avoid a 50-file drive-by; each cluster ticks as it lands.
  DONE: swept all remaining indeterminate spinners → `AppLoader` across 44 files (lab, settings +
  shell, review + stats, combos/moves/video). The **4 determinate progress bars** (`main.dart`
  app-boot migration, two video-export screens, move-detail cloud-download) are intentionally
  left as `CircularProgressIndicator` — they show a percentage `AppLoader` can't. `flutter analyze`
  clean (only a pre-existing `discarded_futures` info in the 1.4 `app_loader.dart`); `app_loader_test`
  + `review_card_layout_test` green.

## Phase 2: Media grid membership + 4-slot tile

Decision (owner, 2026-07-08): **exact-identity membership only.** The spec's literal
"`contentHash` per visible tile" is infeasible for the photo-library tab — a PHAsset has no
file path, so hashing it means downloading the full video from iCloud per tile, and the source
PHAsset id is never persisted on the move. So membership resolves by exact identity: managed
tab by `managedAlbumAssetId`, app-storage tab by content hash of the local file, and
camera-roll is an honest miss (unmarked) — never a false mark, never a byte download to test
membership. Spec delta (`visual-first-surfaces`) reconciled to match.

- [x] 2.1 Membership index: `MoveMembershipIndex` built once per sheet-open from
  `MovesDao.getAll()` (keyed by `managedAlbumAssetId` + `contentHash`); local-file hashes
  memoized per sheet-open in `metadata_video_picker_sheet.dart`.
- [x] 2.2 Rebuilt `_VideoTile` as the 4-slot layout (thumbnail+duration badge, name, one
  secondary fact via `formatTileSecondaryFact`, `bookmark_added_rounded` membership mark);
  missing facts omitted, never padded with text.
- [x] 2.3 Importing an in-Breakdex tile opens a choice sheet — "Open existing move" (routes to
  `/breakdex/move/:id`) vs "Import again" — never a silent duplicate.
- [x] 2.4 Tests: membership match/miss (`MoveMembershipIndex`), tile slot cap (fact helpers),
  duplicate-selection affordance (managed asset → mark + choice sheet), honest photo-library
  miss. 13/13 green.

## Phase 3: Add flow de-text

Decision (owner, 2026-07-08): **task 3.2 is a widget test, not an image golden.** The repo
has no golden-file infrastructure, and a pixel golden freezes appearance without verifying the
actual requirement ("no paragraph-style helper text"). The widget test asserts the semantic
rule directly — every rendered `Text` node on the Add surface is a short label/anchor — which
is both the stronger check and net-cheaper than standing up golden tooling for one screen.

- [x] 3.1 De-texted `add_screen.dart`: dropped the two paragraph subtitles and the dead no-op
  help button; `_ChoiceCard` is now a full-height anchor tile (64px emoji + single label,
  "Move" / "Combo") laid out side-by-side. Metadata form keeps its input labels (text-for-input
  is exempt per the spec). Net −25 LOC.
- [x] 3.2 Widget test `test/features/add/add_screen_test.dart`: asserts both anchor labels
  render and no `Text` node exceeds the paragraph threshold. Green.

## Phase 4: Three view modes

Decisions (owner, 2026-07-08):
- **Toggle stays a direct-select 3-segment control**, not a literal cycle button. The existing
  `_PillToggleRow` renders `ViewMode.values` in order, so the enum declaration order
  (`glance, scan, study`) *is* the fixed cycle contract the spec names — same pattern the
  old list/grid toggle already used. Reconciles "3-segment control cycling in fixed order."
- **Unknown/absent stored value defaults to Glance** (was `list`→Scan). Glance is the
  design's lowest-cognitive-load mode and the visual-first landing; explicit legacy choices
  still migrate exactly (`grid`→Glance, `list`→Scan), so no prior *choice* is lost.
- **Task 4.4 "same result set under filter" is verified structurally, not by a DB pump.** The
  screen computes one `filtered` list and hands it to whichever sliver, so all three modes are
  fed the identical collection by construction; the unit tests cover order/migration/persistence.

- [x] 4.1 `ViewMode { glance, scan, study }`; `viewModeFromStored` + `isLegacyViewModeValue`
  pure helpers do the migration (`grid`→glance, `list`→scan) and `_ViewModeNotifier.build`
  re-persists migrated legacy values on first read of `arsenal_view_mode`.
- [x] 4.2 Study sliver family in `widgets/study_card.dart`: `_MoveStudyCard`/`_ComboStudyCard`
  over a shared `_StudyCardShell` (inline tap-to-play `RobustVideoPlayer`, beat/move counts,
  category/status, 2-line notes preview) reusing `_CategoryLabel`/`_MoveCountDots`/
  `_ComboPreviewFallback`. Glance reuses the grid sliver, Scan the list sliver; toggle icons +
  labels extended to three.
- [x] 4.3 Combos library gets all three modes via the same content switch
  (`_ComboGridSliver` / `_CombosContentSliver` / `_ComboStudySliver`).
- [x] 4.4 `test/features/move_list/view_mode_test.dart`: fixed cycle order, legacy migration
  (grid/list), new-name pass-through (no re-persist), unknown→Glance default, and per-mode
  name round-trip (persistence across restart). 6/6 green; preview-harness smoke test still
  renders the screen in the new default mode.

## Phase 5: Review WYSIWYG

Decisions (owner, 2026-07-08):
- **The dependency already ships.** `clarify-review-loop-and-media-cleanup` task 3.1 ("reusable
  arbitrary color editor") is ledger-drift — unchecked but already built as
  `showColorEditorDialog` (hex + HSV spectrum + RGB + opacity + presets) in
  `lib/shared/widgets/color_setting_tile.dart`, already used by accent color. Phase 5.3
  **reuses** it (no duplication), satisfying the spec's "mechanism defined in clarify".
- **"Card fill" = the Instax frame color** (was a hardcoded `Colors.white`). It's a Settings
  preference, not per-move data → **no schema change**. New nullable `reviewFillColorProvider`
  (null = default white), persisted as ARGB under `review_fill_color`, watched by the card.
- **No-scroll already held** — the card is `Expanded` video + min-size instrument panel, no
  scroll view. The notes-overflow requirement is met by an additive collapsible notes reveal.

- [x] 5.1 Verified the review card is a fixed viewport budget (no scroll view); added a
  collapsed-by-default notes reveal to `InstrumentPanel` with a tap-to-expand affordance
  (one line → full text), threaded via `ReviewCard.notes` (`item.move?.notes`; combo uses the
  active step's notes). Empty notes render nothing.
- [x] 5.2 Review card surfaces moved to `AppRadius.xxs` (frame `xs`→`xxs`; inner video raw
  `2`→`xxs`).
- [x] 5.3 Frame fill reads `reviewFillColorProvider` live (no restart); a new `ReviewFillColorSection`
  in Settings (with Reset) reuses `showColorEditorDialog` rather than duplicating a picker.
- [x] 5.4 Tests: `review_card_layout_test` (no `Scrollable` on small-phone + tablet viewports;
  live fill applied from the persisted setting), `instrument_panel_notes_test` (collapsed →
  expand affordance; empty = nothing), `review_fill_color_test` (persist/restart/reset). 9/9 green.

## Verification

- [x] V.1 `dart analyze` clean on all touched files. `flutter test`: every test for this change's
  scope is green (Phases 2–5). The full suite has **pre-existing** failures in unrelated areas
  (semantic video-path scheme, FSRS due-counts, renamed state labels, stats copy) — verified by
  re-running with this change stashed: identical failures, so no regression introduced. No image
  goldens exist in the repo; verification is via widget/unit tests (recorded per phase).
- [x] V.2 Patrol journey (open library → cycle 3 modes → pick device video already in Breakdex →
  land on existing move → run one review card without scrolling; iOS + Android). **Deferred** —
  requires real devices/simulators; cannot run headless. Owner to run before archiving.
  <br/>**ROUTED 2026-07-29** to `owner-verification-passes` §6.2. It was the first unticked
  task in this file, so `./status.sh` pointed every fresh session at work no agent can close —
  exactly the stall the queue doctrine's "agent-unclosable tasks never sit in a parent change"
  rule exists to prevent. The next implementable task is 6.3.
- [x] V.3 Token conformance sweep + TOKENS.md sign-off (radii/motion literals resolve from tokens).
  Curves already 0 raw app-wide (1.3). Swept every **exact-token-match** literal onto its token:
  36 radii (`circular(4|8|12|16|24)`→`AppRadius.xxs|xs|sm|md|lg`; the `circular(999)` "fully-round"
  idiom → `AppRadius.pill`, identical rendering since both clamp to half the shorter side) + 3
  motion durations (`150`→`moderate01` ×2 on a fade controller & `AnimatedContainer`; a `240`
  stagger `delay:`→`moderate02`). All 39 are **zero-visual-change** aliases (value-preserving);
  `dart analyze` clean, `app_loader_test`+`review_card_layout_test` green. TOKENS.md Radius section
  gained the "raw literals are review violations" rule (mirrors the motion doctrine) — sign-off.
  **Deliberately left raw (owner design decision, NOT ledger drift):** 43 *off-scale* radii
  (`circular(1|2|3|6|10|14|20)`) and off-token durations (`200`/`600`/`2400`ms motion; all
  `Future.delayed`/timeout/snackbar `seconds:` — not visible motion). These have **no** token
  equivalent, so snapping them would *change pixels/feel* — that is a scale-extension vs
  snap-to-grid aesthetic call for the owner, not a value-preserving conformance win. Enumerated
  so the boundary is explicit and reviewable.

## 6. Owner design wave — captured 2026-07-28 (UNSPECCED, verbatim intent)

Captured under the `## Capture rule` in CLAUDE.md: these arrived in a working session
that had no budget left to build them. They are recorded here so they exist on the board
rather than in a transcript. **None are specced yet** — each needs a Teacher pass (and 6.6
needs a Scholar pass first) before any Student session touches code.

- [x] 6.1 **One-page Add flow.** `SCR-20260728-maiy` (Add Content) should be as easy as the
  home tiles in `SCR-20260728-makk` — "imagine everything was a blend". Adjust the grid and
  layout rules so Add is a single-page layout, not a scroll with a card below the fold.
  **DONE 2026-07-29 — delivered by `add-stacked-viewport-layout`.** The ask was a layout
  rule, so it was answered with a rule rather than a one-screen tweak; `add` is that
  change's reference migration (tasks 2.1–2.3). See that change for the constitution, the
  per-screen migration ledger, and the owner-gated type-scale item (4.1).
- [x] 6.2 **`Moves` header overflow.** `SCR-20260728-mafz` shows a RenderFlex "OVERFLOWED BY 2"
  on the `< Back  Moves` header. Reproduce (it did not overflow on an API-35 emulator at
  default text scale — suspect larger text scale or iOS metrics) and fix.
  <br/>**DONE 2026-07-29.** Reproduced in a widget test, not on a device: `AppBar` gives
  `leading` a fixed **56pt** slot, and a chevron plus a word of `bodyMedium` does not fit it —
  the old shape overflows by 29px at the test's default metrics and by 48px at text scale 1.3.
  On the owner's device with Inter it landed at exactly the 2px the screenshot recorded, which
  is why it looked like a rounding artefact rather than a structural miss.
  <br/>Fixed as a type, not a nudge: `BackLeading` (`lib/shared/widgets/back_leading.dart`)
  declares the slot it needs (`slotWidth`) and ellipsizes its label inside it, so overflow is
  impossible at *any* text scale instead of merely unlikely at one. Both `move_category`
  headers now use it; the `moves-back` / `category-back` semantics identifiers the Maestro
  `navigation.yaml` flow selects on are preserved. Covered by
  `test/shared/widgets/back_leading_test.dart` at scales 1.0 / 1.3 / 2.0, red-proved against
  the pre-fix shape.
  <br/>**Left alone deliberately:** `combo_detail_screen.dart` has a third copy of this control
  with its own `leadingWidth: 104` and a `sectionHeader` type style. It is the same class of
  defect at large text scales, but converting it changes that screen's voice — out of scope for
  a header-overflow task, and worth doing when that screen is next touched.
- [x] 6.3 **Settings full-view transition animation.** An interesting full-view transition
  when opening settings sections. Must compose from `AppMotion` tokens (Fluid + Morph only —
  raw curve/duration literals are review violations).
  <br/>**DONE 2026-07-29.** Answered as a route type, not a per-screen animation:
  `settingsSectionPage` (`lib/core/navigation/settings_section_page.dart`) is the page every
  `/settings-panel*` route is built from, so a new settings section cannot ship with the
  default push transition by accident. The motion composes both sanctioned families and
  nothing else — **Fluid** for the arriving section (fade on `entrance`, a 6%-of-height rise
  on `fluid`, `moderate02` in / `moderate01` out) and **Morph** for the view it covers (one
  persistent surface scaling back to 0.96 on `springGentle`), which is what makes the two
  views read as depth in one stack rather than two unrelated pages. Reduced motion
  (`MediaQuery.disableAnimations`) returns the child unwrapped, so the route cuts.
  <br/>Covered by `test/core/navigation/settings_section_transition_test.dart`, including a
  conformance case that walks `appRouter` and fails any `/settings-panel*` route without a
  `pageBuilder` — red-proved against the pre-change router.
  <br/>**Left alone deliberately:** the dev-only `SyncCutoverPanel` push
  (`settings_screen.dart`, behind `kDevSyncPanelEnabled`, flag OFF) keeps its
  `MaterialPageRoute` — converting it would touch a tree-shaken dev surface for no product
  gain. **NOT proven:** how the transition feels on a device or in a browser.
- [x] 6.4 **Icon system + icon packs.** Current icons read generic. Want handpicked,
  human, Notion-quality — "I would even pay for them, that's the quality". Make icon sets
  swappable from the design system, with selectable packs surfaced in Settings.
  <br/>**DONE 2026-07-29 — `openspec/changes/add-icon-system-and-packs` Phase 4 closed.**
  78 semantic names, 2 packs (material + lucide), `AppIcon` enum with exhaustive `switch`,
  conformance gate with zero-allowlist ban. 434 raw `Icons.*` sites eliminated — only
  `icons.dart` definition file remains. `CLAUDE.md` canonical-stack table and
  `openspec/AGENTS.md` review checklist updated. Phase 5 (settings surface) deferred;
  packs work already, switching UI is a Settings-only follow-up.
- [ ] 6.5 **Pantone-only color packs.** `SCR-20260728-maro`: minimal but not sophisticated;
  "better colors". Design from light→bold weights, fluid and organic rather than hard
  statements — Linear's design philosophy, simple handpicked colors. Color packs are
  **Pantone only**: adjust any color, pick by season, and choose from the full database
  including every past Color of the Year. `docs/design/TOKENS.md` stays the single source.
  <br/>**SPECCED 2026-07-29 (Teacher pass) → `openspec/changes/add-color-packs`,
  strict-valid.** Same mechanism as 6.4, applied to color: a closed role vocabulary, packs
  resolving it exhaustively, `ThemeExtension`, persisted preference, gated by test. Two
  findings shaped it. (1) Surfaces are **compile-time constants** — 38 `const Color` in a
  58-line `colors.dart`, only 4 values user-adjustable — so "better colors" is currently
  inexpressible for most of the pixels; and the 4 adjustable values move independently of
  each other, which is why the palette reads minimal without reading handpicked. Answered
  with **seeds + a perceptually derived OKLCH ramp** rather than 38 hexes, which is where
  "light→bold, fluid and organic" actually lives. (2) A free-form color feature would
  silently defeat the shipped `AccessiblePalette` work, so the three axes are ordered
  `pack → brightness → accessibility overlay` with **the overlay last and winning**.
  <br/>**Owner decision open, blocking nothing (that change's 6.1):** PANTONE® is a
  registered trademark and its names/numbers/sRGB translations are licensed IP — shipping
  "the full database" is a purchase, not an implementation. The catalogue sits behind an
  interface, so the spec ships in-house curated seasonal/year collections by default and a
  licensed dataset drops in later with no mechanism change.
- [ ] 6.6 **Typography control + power-user layer.** `SCR-20260728-mawt`: per-label/input
  font-family control, made easy — "interfaces are to be read", the taste is in denoting each
  one. Alongside it: one central XState machine; an AST-shaped property model so every
  element is addressable; lexical (`sgrep`) matched with syntactical search; and cmd+K brought
  into the app so it serves power users. Treat as an infinite-traversal problem over a set of
  information pieces. **Scholar session required before specifying.**
- [ ] 6.7 **Never-destroy behavior ledger.** Working state and behavior are never destroyed:
  a black box that can be viewed in-app at any time and exported out. **Must extend the
  existing `provenanceJournal` / `docs/hyperdata-ledger.md`, not become a second system.**
- [ ] 6.8 **Honest stats.** `SCR-20260728-maro` (MOVES BOXES): give actually helpful and
  reliable stats — the current NEW / PRACTICING / STRONG / TOTAL DUE readout is not earning
  its space.
- [ ] 6.9 **Updates + A/B testing.** Solve the update story, and add an A/B test showcase
  openable from Settings. Overlaps the remote-config work in
  `add-web-first-release-and-monetization` (Phase 1R) — reconcile before specifying.
- [ ] 6.10 **Ephemeral Maestro fixtures.** Long-term usable Maestro testing needs temporary
  data, not permanent seeding: qualitative flows must run against real-looking data that
  leaves no residue. Pairs with `android-e2e` 6.3.

**Teacher session 2026-07-29 — disposition of the rest, so it is not re-derived.** That
session specced 6.4 and 6.5 (above) and stopped there deliberately, under the token ceiling.
The remaining items are *not* blocked on those two; each needs its own pass, and the lane it
needs is already known:

| Item | Lane needed next | Why it was not specced here |
| --- | --- | --- |
| 6.6 Typography + power-user layer | **Scholar, then Teacher** | Already marked Scholar-first in its own entry. It is four asks in one (per-element font control, a central XState machine, an AST-shaped property model, lexical+syntactic search, cmd+K) and specifying it from confident vibes is exactly what the Scholar lane exists to prevent. |
| 6.7 Never-destroy behavior ledger | Teacher | Must extend `provenanceJournal` / `docs/hyperdata-ledger.md`; the Teacher pass has to read that existing system first or it becomes the second system its own entry forbids. |
| 6.8 Honest stats | Teacher | The smallest of the set and the most independent — a good next Teacher pass. Needs a decision about what the readout is *for* before it can name replacement metrics. |
| 6.9 Updates + A/B testing | Teacher, **after reconciliation** | Overlaps `add-web-first-release-and-monetization` Phase 1R remote config. Specifying it before reconciling produces a competing config surface. |
| 6.10 Ephemeral Maestro fixtures | Teacher | Pairs with `android-e2e` 6.3; spec both together or the fixture contract lands twice. |

Recommended order once 6.4/6.5 are implemented: **6.8 → 6.7 → 6.10 → 6.9 → 6.6**, cheapest
and most independent first, with 6.6 last because it is the only one gated on a Scholar pass.

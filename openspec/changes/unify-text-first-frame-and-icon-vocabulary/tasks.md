# Tasks

Owner asks captured 2026-08-01. Ticks are same-commit with the work (ledger rule).
Items 1–2 and 6–7 landed this session; 3–5 and 8 are captured, not built.

## 1. The row atom — DONE

- [x] 1.1 `AppRow` in `lib/shared/widgets/app_row.dart` — label, optional `value`, optional
      `leading`, optional `trailing` control, `identifier` for E2E, `enabled`. Floor is
      `AppLayout.rowHeight`; chevron appears only when tappable so a readout and a choice are
      never confused. Flat by construction — no fill, no elevation.
- [x] 1.2 Add screen migrated to `AppSection(title:)` + two `AppRow`s; `_ChoiceCard` deleted.
      New l10n key `addSectionCreate` ("Create") supplies the section label the owner asked
      for, matching Drill's `CUSTOM DECKS` and Settings' `PRACTICE & REVIEW`.
- [x] 1.3 Gate: `flutter analyze` clean; `test/design/` + `test/features/add/` 21 green,
      including the pre-existing "choice rows land on the block grid" assertion.

## 2. Icon vocabulary — DONE

- [x] 2.1 `CupertinoPack` — all 80 names, exhaustive `switch`, constants verified against the
      SDK's `cupertino/icons.dart` rather than recalled.
- [x] 2.2 `IconPackId.cupertino` added and made the default; `fromKey` falls to it.
- [x] 2.3 `AppIcon.library` (book) and `AppIcon.dojo` (training floor) added to all three packs.
- [x] 2.4 Nav rewired: Breakdex → `library`, Review (anki mode) → `dojo`.

## 3. Overlays must compute their own coordinates — SHEETS DONE, DIALOGS OPEN

Owner, on `SCR-20260801-mxjs`: *"unreliable reliance on the viewport … you need to be always
calculating your own coordinates. Apple Native would have done this better."* The "Plan a
combo" sheet is clipped by band 4.

Cause, found by reading the shell: a sheet opened from a screen inside the tab shell is pushed
onto that branch's *nested* navigator, which lives inside the shell `Scaffold`'s **body** — and
the shell sets `extendBody: true`. So the viewport the sheet measures runs to the physical
bottom while its last `56 + padding.bottom` is under the blurred band. The viewport is not
unreliable; it is honestly reporting a box that something else paints over.

- [x] 3.1 `showAppSheet` (`lib/shared/widgets/app_sheet.dart`) owning
      `navBandHeight + MediaQuery.padding.bottom`, mirroring how `AppScreen` owns it for
      screens. It *removes* the bottom safe-area padding from the subtree before applying the
      inset, so the ~20 bodies that wrap themselves in `SafeArea` cannot count the home
      indicator twice — the guarantee holds whatever the body is built from. It also sets
      `useSafeArea: true` for every sheet: the top edge is a coordinate too, and a tall
      scroll-controlled sheet must stop at band 1 rather than slide under the status bar.
      `viewInsets` is left untouched, so sheets that lift above the keyboard still do.
- [x] 3.2 All 24 `showModalBottomSheet` call sites migrated; zero remain outside the helper.
      Per-site chrome went with them — 8 hand-copied `RoundedRectangleBorder`s, one
      `BorderRadius.zero` "brutalist" variant, one lone `showDragHandle`, and every
      `backgroundColor: Theme.of(context).colorScheme.surface`. The single surviving parameter
      is `backgroundColor`, for the two sheets whose body paints its own container and must
      pass `Colors.transparent` or get a second surface drawn behind it.
- [x] 3.3 `test/shared/widgets/app_sheet_test.dart` — clearance at 600/800/1000pt viewports,
      each asserting the inset is applied **once** as well as at all. RED first against a bare
      `showModalBottomSheet`: 34pt of clearance where 90 is required, at all three heights —
      exactly the 56pt band. Green after.
- [ ] 3.4 Dialogs are a different computation and were **not** folded into `showAppSheet`.
      An `AlertDialog` is centred, so band 4 only bites one tall enough to reach it; shifting
      every dialog up by 56pt would misplace the 30-odd short ones to fix the few tall ones.
      The fix there is a max-height clamp, not an inset. 34 `showDialog` sites across 19 files
      remain unmigrated — deliberately, with this reason, not by omission.

## 4. Frame migration — 28 screens — NOT BUILT

`AppScreen` binds 5 of 33 screens. Migrate in batches, adding each to the
`frame_conformance_test.dart` allowlist **in the same commit** so the guard grows with the fact.

- [x] 4.1 Tab-level: `move_list` (`AppScreen.slivers`, `wide`), `combos` and the drill screen
      (`AppScreen.fill`). Two frame facts were missing and were added first, red-first:
      **(a)** the frame's scroll inset was the flat `scrollBottomInset` (72), so migrating a
      screen that correctly used `kBottomNavigationBarHeight + padding.bottom` onto it would
      have *regressed* clearance on a home-indicator device — it is now
      `AppScreen.bottomInsetOf(context)`, the same sum `showAppSheet` owns, and a fill child
      calls that helper rather than re-deriving it; **(b)** `AppScreen.fill` + `pinned`, for a
      content band that is not one scroll the frame can pad (combos' `IndexedStack` of three
      self-scrolling views) and for a control that must stay under the header without band 2
      growing. Nine hand-rolled `screenEdge` gutters came out of `move_list` because the frame
      now owns that column, and combos' three lists traded a magic `80` for the real inset.
      `settings` is **not** in this batch: `/settings-panel` pushes the same widget on the
      **root** navigator, where there is no band 4 to inset and a back affordance is required,
      which is the detail-frame ruling 4.2/4.3 owes — it rides with 4.3, not with a second
      frame variant invented here.
      Roster grew by `move_list` + `combos` in the same commit. `flashcard_review_screen` is
      held out and *bounded* instead: a new test pins it at exactly one `Scaffold` (the
      immersive drill session, deliberately band-less) and asserts it uses `AppScreen.fill`, so
      the exemption cannot widen back into a hand-built header.
      Gate: analyzer 0/0, 1361 pass / 3 skip / 0 fail.
- [x] 4.2 Detail screens: `move_detail`, `combo_detail`, `lab_detail`, `move_category` (both
      of its screens). The ruling 4.1 deferred here turned out to have a false premise: all
      four are pushed **inside** the shell branch, so band 4 was never absent and no second
      frame variant was needed. The only missing fact was a way back, and it is now a fact
      about the **route**, not a flag — `AppScreen` reads `Navigator.canPop`, so a tab root
      cannot render a control that would do nothing and a pushed screen cannot forget one.
      A screen may only *name* it (`backIdentifier`), which is what keeps `.maestro`'s
      `moves-back` selector alive. Red-first: the affordance absent at the root, present when
      pushed, ≥44 square, with the title's centreline unmoved and content still starting at
      `headerHeight + contentTopGap` — proved red before `AppLayout.backSlot` existed.
      **The chevron carries no word.** The crumb line rendered directly above it already says
      where back goes; typing it twice is two strings to keep in sync, and `combo_detail`'s
      said "Combos" while `lab_detail`'s said "Lab" and `move_category`'s said "Back".
      **`BackLeading` was deleted in the same commit** (widget + test): it existed only to
      stop three screens hand-rolling a labelled `AppBar` leading, and no screen builds an
      `AppBar` any more. Its slot-width ruling (`SCR-20260728-mafz`) is superseded by
      `backSlot`, not lost.
      Each screen also stopped repeating its own title: `move_detail` typed the move name in
      a `SliverAppBar` *and* again as `titleLarge` two lines below it; `combo_detail` and
      `lab_detail` did the same. One name, on the frame's baseline.
      Three took `AppScreen.fill` for a stated reason — `move_detail` and `combo_detail`
      because overlays layer over the whole band, `lab_detail` because half its sections are
      deliberately full-bleed (the set sequencer scrolls edge to edge) and a uniform gutter
      would inset them. `move_category`'s index took the scrolling default and its detail
      took `fill` + `pinned` (the same shape combos got in 4.1), trading a hand-rolled
      `kBottomNavigationBarHeight + padding.bottom + xxl` for `AppScreen.bottomInsetOf`.
      Roster grew by all four in the same commit. Gate: analyzer 0 errors/0 warnings,
      **1362 pass / 3 skip / 0 fail**. How any of it *looks* is owner-gated.
- [ ] 4.3 Settings sub-screens (7 files) — the cheapest batch, all already list-shaped.
      **Unblocked by 4.2**: `/settings-panel` pushes on the root navigator, and the frame's
      back affordance is read from the route, so it needs nothing 4.2 did not already ship.
      The open question there is band 4, not back: the root navigator has no nav band, so the
      bottom inset `AppScreen` reserves is dead space on those routes.
- [ ] 4.4 Remaining: auth, battle, party, video editors, instax, dev panels. Includes extracting
      the immersive drill session out of `flashcard_review_screen` so that file joins the roster.
- [ ] 4.5 Flip `frame_conformance_test.dart` from an allowlist to a denylist once the remainder
      is small — the guard should fail on a *new* bespoke Scaffold, not merely tolerate old ones.

## 5. The grid basis must be adjustable — NOT BUILT

Owner: *"a showcase of precision and like grids and rules (i could easily adjust the basis on
which grids and rules of the application are built upon)"*, plus: pre-seed a dev mode showing
every element so each one can be seen functioning.

- [ ] 5.1 Make `AppLayout` overridable at runtime (a `ThemeExtension` carrying the constants,
      defaulting to today's values) so gutter / baseline / blockGrid / rowHeight / headerHeight
      can be changed live and every screen re-flows. The constants stay the default, not the law.
- [ ] 5.2 Dev gallery route, pre-seeded with real fixture data (`automation_fixture_service`
      already seeds moves/combos), rendering every primitive — `AppScreen`, `AppSection`,
      `AppRow` in each state, all 3 icon packs side by side, all 17 color roles, the motion
      families. Extends `lib/dev/preview_harness.dart` rather than starting a new harness.
- [ ] 5.3 Live sliders in that gallery bound to 5.1, so the basis is adjusted by moving a
      control, not by editing a constant and hot-restarting.
- [ ] 5.4 Motion: owner wants **morph-first** animation, "how graphics are rendered from first
      principles", Skia-level precision, a CSS-native equivalent in Flutter. The locked doctrine
      already names two families (Fluid + Morph on `AppMotion`); this task is to make Morph the
      *default* for layout/shape continuity and to prove it with a shared-element transition
      between the Add row and the screen it opens.

## 6. Default categories — DONE

- [x] 6.1 Expanded to the owner's canonical 8, in the owner's order: Power Moves, Footwork,
      Freezes, Go Downs, Toprock, Transitions, Burns, Blow Ups. Order is meaning — it runs the
      way a set is built, not alphabetically.

## 7. Uncategorized is a fallback, not a category — DONE

- [x] 7.1 The Uncategorized block renders only when `activities.uncategorized.count > 0`, so a
      clean library never advertises an empty bucket and moves are never orphaned. The
      `/breakdex/moves/uncategorized` route stays reachable either way.

## 8. Videos must name where they live — NOT BUILT

Owner: videos should carry a visible reference to their cloud location (Google Drive, Dropbox)
so the bidirectionality is legible; and where a thing has many children, a preview should
introduce it.

- [ ] 8.1 Surface the cloud pointer on the move/video surface. `source_origin_badge.dart`
      already exists — check whether it can carry this before building anything new (fit before
      build). Drive pointers are already stored; this is a display gap, not a data gap.
- [ ] 8.2 State the direction, not just the location: local-only / uploaded / pending / failed
      are different facts, and one badge that conflates them is worse than no badge.
- [ ] 8.3 Parent-with-many-children preview: a combo or category with N items shows a
      representative strip before you open it. Composes from the atom model (move → combo →
      set); do not invent a new container type for it.

## 9. Lexical address line — DONE

Owner ask, 2026-08-01: "always show the slug / page location of where you are… and the
breadcrumb clickable."

- [x] 9.1 `breadcrumbsFor(path)` / `crumbLabel(segment)` in
      `lib/shared/widgets/app_breadcrumb.dart` — pure, router-free, unit-tested. Segments are
      slugified (decoded, lowercased, spaces and underscores to hyphens); an opaque id longer
      than 16 chars is elided in the middle, because 36 characters of uuid says nothing a
      reader can use.
- [x] 9.2 `AppBreadcrumb` renders the trail as one line of type — no chips, no chevrons, no
      boxes. Tail is the current page (onSurface, w600); ancestors are muted links. The trail
      scrolls horizontally with `reverse: true`, so where-you-are stays pinned when the trail
      outgrows the column.
- [x] 9.3 A crumb links only if `GoRouter.configuration.findMatch` resolves its prefix, so
      `/breakdex/move` (a prefix, not a page) renders as plain text instead of a link that
      would bounce the user home. The router's own matcher is the authority — a hand-kept list
      of linkable segments would drift from the route table.
- [x] 9.4 `AppLayout.crumbHeight` (16) + `crumbGap` (4) live *inside* the unchanged
      `headerHeight` (16 + 4 + 36 = 56 centred in 72, 8/8 padding, still on the block grid).
      Band 2 does not grow: a header that changes height between screens is the exact
      discontinuity the frame exists to remove.
- [x] 9.5 No router above (a plain widget test) renders nothing rather than throwing —
      `GoRouter.maybeOf`, never `GoRouterState.of`.

## 10. Pickers de-chipped — DONE

Owner ask, 2026-08-01, against the Settings screenshot: the accessibility segment, the font
pills, and the ragged `Wrap` runs read as spreadsheet furniture, not as the text-first
structure already ruled.

- [x] 10.1 `AppChoiceList<T>` in `app_row.dart` — a single-select rendered as `AppRow`s, one
      option per line, chosen one marked with a check. A filled pill makes the selected option
      a different *kind* of object from its siblings, so the eye compares shapes instead of
      comparing options.
- [x] 10.2 All five `_SegmentedPicker` call sites migrated (theme, accessibility palette, app
      mode, add-flow order, move-detail caption) plus the font `ChoiceChip` `Wrap`;
      `_SegmentedPicker` deleted. The per-instance `fontSize: 11` on the caption picker went
      with it — a local type shrink is the drift the atom removes.

## 11. Ledger reconciliation

- [x] 11.1 `icon_pack_test.dart` "fromKey returns material for unknown keys" asserted the old
      default and went red the moment 2.2 landed; re-pointed at `cupertino` with the reason
      inline.
- [x] 11.2 `category_recency_test.dart` expected `Nothing here yet` twice, which 7.1 made
      false — Uncategorized is a holding pen, not a category, so it renders only while it
      holds something. Now asserts one.
- [x] 11.3 Gate: `flutter analyze lib` clean (1 pre-existing `discarded_futures` info in
      `app_loader.dart`); `flutter test` **1353 green / 3 skipped / 0 failing**.
      NOT PROVEN: the visual result on device or web — owner-gated, as always.

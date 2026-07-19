# Tasks — humanize-video-surfaces-and-gate-release

> **Phase dependencies:** Phase 2 starts immediately. Phase 1 lands after
> `fix-video-backup-truth-and-unify-account` 4.7 (sandbox rescue — design D1
> sequencing). Phase 3 ticks last; 3.2 additionally needs that change's Phase 3
> (one-account auth) so user #2 walks the released flow.
> Ledger rule: tick in the same commit as the work, with terminal evidence.

## Phase 1 — Picker collapse (after backup-change 4.7)

- [ ] 1.1 Manifest-backed library list: pure `buildBreakdexVideoItems()` joining live
  manifest rows to owning moves/combos — title (owner name, else basename stripped of
  the ` - hash8`/full-hash suffix), effectiveDate, resolver-backed path. Red: fixture
  with owned + ownerless + tombstoned rows — tombstoned excluded, no raw hash/UUID in
  any title, newest-first by effectiveDate. Verify: unit tests green, analyze clean.
- [ ] 1.2 Tab collapse: SELECT VIDEO renders exactly two tabs — **In Breakdex**
  (default, 1.1-backed) and **Import** (existing PhotoKit grid, videos-only) — with
  `VideoPickResult` contracts unchanged for both consumers. The VIDEO LIBRARY tab is
  removed; confirm `discoverRecoverableManagedAssets` keeps a reachable entry point in
  the recovery/settings surface (add one there if the picker was the only route —
  design D3). Verify: widget tests (pure-override harness) for both tabs + default-tab
  assertion, analyze clean.
- [ ] 1.3 Honest durations (design D2): lazy per-tile probe via the existing controller
  seam, in-memory cache; unprobed/unprobeable shows no badge. Delete the `duration: 1`
  hack. Red: tile with probe-failure renders no badge (today: fabricated `0:01`).
  Verify: unit test for cache + widget test, analyze clean.
- [ ] 1.4 On-device proof (owner, 30s): open picker → In Breakdex is default, newest
  clip on top with real title + date, durations real or absent (no `0:01` wall);
  Import shows camera roll videos; pick from each tab lands in a move. Evidence:
  screenshot pair in the tick.

## Phase 2 — Subtitle legibility (independent, start now)

- [x] 2.1 Row subtitles show the date, not `originalVideoName`. DONE 2026-07-19.
  The `originalVideoName` sweep found **one** offending subtitle —
  `move_category_screen.dart:961` — and two legitimate keeps: the move-detail
  provenance row (that is 2.2's surface, where the filename is the point) and
  `video_player_widget`'s "Video not found" diagnostic. `_MoveRow` is now a
  `ConsumerWidget` rendering the shared `LibraryDateLabel` at
  `move.effectiveDate(sort)`, so the shown date is the same one the active sort
  ordered by.
  **Ruling (D4 addendum): the caption follows the resolved source, never the
  requested sort.** The fallback chains that make `effectiveDate` *total* also make
  the sort a false label — an unfilmed move ordered under "Filmed" is ordered by its
  `createdAt`, and captioning that "Filmed" would have replaced a useless subtitle
  with a lying one. New `LibraryDateSource` + `effectiveDateSource(sort)` mirrors the
  chain link for link on both `Move` and `LibraryRow` (a combo can never report
  `filmed` — it has no capture event, the same fact `LibraryFilmedFallbackNotice`
  already discloses). A property test asserts every source agrees with the date
  `effectiveDate` actually returned, so the two cannot drift apart.
  Red: the five `effectiveDateSource` unit tests failed to compile against the
  pre-fix model, and the fallback case is the one that pins the ruling.
  **Scope limit, stated plainly:** the widget tests pump the subtitle composition,
  not the category screen — `_MoveRow` is private and booting that screen drags in
  live Drift streams (the documented flake class), so no test reds against the old
  UUID subtitle at screen level; the swap itself is covered by analyze + the shared
  widget's contract.
  Verify: `library_sort_test` 16 green, 5 new `LibraryDateLabel` widget tests green,
  models+features **+267 vs a stashed-baseline +257, identical ~7 -7 — 0 regressions**,
  `flutter analyze` 0 errors, `check_l10n.sh` green (3 new ARB keys, placeholdered).
- [x] 2.2 Detail-screen provenance + caption. DONE 2026-07-19.
  **Scope corrected by the owner mid-task.** As written this was a confirm, and the
  confirm passes: the labeled Video Info panel already renders both
  `originalVideoName` and file size (`move_detail_screen.dart:297-308`). But the
  sweep in 2.1 undercounted — there are **two** renderings on this screen, and the
  second one is the defect. A monospace caption sat directly under the move's name
  showing `originalVideoName`, falling back to `ID: <hash8>`: the same UUID-subtitle
  disease 2.1 cured on category rows, one screen deeper, and exactly what D4's own
  text already anticipated ("the subtitle becomes the date… `originalVideoName`
  remains on the move detail screen" — the panel *is* that home, the caption is not).
  The caption now shows the added date via the shared `LibraryDateLabel`
  (`createdAt`, `LibraryDateSource.added`), so the detail screen cannot word a date
  differently from the library. Owner-selectable: new `MoveDetailCaption` preference
  (Date / Filename / ID / None, default Date) persisted under `move_detail_caption`
  following the `AddFlowOrder` notifier idiom, surfaced as a `_SegmentedPicker` in
  Settings → Library ("Move Caption").
  **Ruling (D4 addendum): a raw identifier is reachable only by explicitly selecting
  it, never by fallback.** `filename` on a move with no filename falls back to the
  *date*, not to a hash — asking for a name and being handed an identifier is the
  precise defect being replaced, and `createdAt` is non-null on every move so the
  fallback is always available. A property test walks every mode against a move with
  neither filename nor hash and asserts only `contentId` yields an `ID:` string, so a
  future mode cannot quietly reintroduce the UUID caption.
  **A wrong turn worth recording:** the first proposal was to delete the caption
  outright as a duplicate of the panel row. It is not a duplicate — the panel is
  gated on `move.videoPath != null` (`:271`) while the caption was gated on
  identity, so for a **cloud-only move** (bytes not local, hash present — the state
  the whole backup effort produces) the panel does not render and that caption was
  the only identifying text on the screen. Deleting it would have been a silent
  information loss of exactly the kind D11 warns about. Replacing it with a date
  keeps the slot populated for those moves; the `videoPath`-vs-identity gating
  asymmetry on the panel is filed under 2.3 as a separate finding.
  Red: 9 resolver/enum tests failed to compile against the pre-fix model; the
  filename-with-no-filename case is the one that pins the ruling.
  Verify: 12 new tests green (9 pure resolver + 3 widget, no ProviderScope and no
  Drift, so the documented live-stream flake class cannot apply), affected suites
  (settings + move_detail + move_list + move_category + core/models) **187/187, 0
  failures**, full suite **1193 green / 11 skipped / 9 red**, red set **byte-identical
  to a stashed baseline** (`diff` empty — 5 card-count + 2 party + preview harness +
  bottom-nav shell, all documented flake classes) → **0 regressions measured**,
  `flutter analyze` 0 errors (9 pre-existing infos untouched), `check_l10n.sh` green
  (1 new ARB key), `flutter build web` green.
- [ ] 2.3 Codify the review rule (design D4): add "no content hash, UUID, or raw
  filename as primary/secondary text on library surfaces" to the review checklist in
  `openspec/AGENTS.md` conventions (alongside the tokens-conformance item). Include
  the 2.2 addendum — an identifier may be shown only when explicitly selected, never
  reached by fallback. Evidence: the diff.
  **Carried finding from 2.2 (needs an owner ruling, not just a checklist line):**
  provenance placement on move detail is keyed on byte locality, not identity — the
  Video Info panel is gated on `move.videoPath != null` (`move_detail_screen.dart:271`),
  so a cloud-only move shows no filename, size, or recorded date anywhere, even though
  `asset_manifest` holds `fileSizeBytes` for that same content hash. Related: the
  detail screen reads size only from `moves.videoFileSize` and never from the manifest,
  so legacy rows with a null size silently hide the row (`orphan_restore_service.dart:112`
  is the only place that backfills one from the other).

## Phase 3 — Multi-user release gate

- [ ] 3.1 Write `docs/release/sync-release-gate.md`: the four gates with their proving
  change/task ids — (a) asset truth: backup change 4.7 + 4.8 + 4.6 device proof;
  (b) totality: `make-sync-total-and-registry-driven` complete; (c) Phase M: M.4 soak +
  M.5 config flip ticked in the Appwrite master change; (d) fresh-second-user proof
  (3.2). Doc only. Verify: file exists, gates link to real task ids.
- [ ] 3.2 [OWNER+AGENT] Fresh-second-user end-to-end proof (needs backup-change Phase 3
  one-account flow): a non-owner Google account signs in on a device or web build →
  Appwrite user created, Drive folder provisioned on *that* account's quota → import
  one video → it uploads to their Drive and appears on their own web login after
  hydrate. Agent verifies isolation server-side with existing `.env.local` API access:
  user #2's documents carry only their `userId`, zero rows cross into user #1's space,
  owner's counts unchanged. Evidence: server queries + screenshots in the tick.
- [ ] 3.3 [OWNER] Declare sync released: all four gates ticked with evidence → mark the
  general Google-Drive-sync effort done in `ROADMAP.md` (NOW block + backlog) and
  record the declaration date in the gate doc. Evidence: the diff linking all four.

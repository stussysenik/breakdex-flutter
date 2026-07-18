# Humanize Video Surfaces + Multi-User Release Gate

## Why

Owner screenshots (2026-07-19) show the storage plumbing leaking into the product's two
most-used video surfaces:

- **The SELECT VIDEO picker exposes three tabs by backend, not by intent.** PHOTO
  LIBRARY / VIDEO LIBRARY / APP VIDEOS are three places bytes happen to live — a dancer
  cares about exactly two things: "show me my breaking videos" and "let me pull in a new
  one". The default tab (Photo Library) is ~80% non-breaking noise (screen recordings,
  mockups); the tab that actually holds the library (App Videos) is buried third and
  reads like a debug screen — raw UUID titles (`AC3DD8C4-65EB-41A…`), byte sizes as the
  primary label, and a **fabricated `0:01` duration on every tile**
  (`metadata_video_picker_sheet.dart:240` hardcodes `duration: 1` so the badge renders).
  VIDEO LIBRARY has literally no sort (`PHAsset.fetchAssets(in:options:nil)` — album
  order) which is the owner's "doesn't show the most recent".
- **Move rows subtitle with identifiers, not information.** The category list renders
  `originalVideoName` as the subtitle — for camera-roll imports that is a raw UUID
  (`7ff8c14c-55f3-49e2-a0f7-…`), for the rest a filename (`OPTW 02-08-26 VERTICAL PART
  1.mp4`). Nobody filters powermoves by UUID. The information a dancer thinks in is
  **when** — the date the clip entered the library / was filmed — which
  `add-library-time-and-metadata-browsing` already made canonical (`effectiveDate`) but
  which never displaced the filename in the subtitle slot.
- **No stated finish line for sync.** The architecture for private per-user sync is
  locked and largely built, but "Google Drive sync is done, releasable multi-user" is
  currently a feeling, not a checklist. The gates exist — scattered across four changes
  — and the one thing never proven is a *second* real user end-to-end.

## What Changes

**Phase 1 — Picker collapse (two tabs by intent):**
- **In Breakdex** (default): the app's own library — real move titles from the owning
  entity where one exists, date-added, real durations (probed, never fabricated),
  newest-first by real dates. One list, playable, no UUIDs.
- **Import**: the photo-library grid (videos-only, creation-date sort it already has).
- The VIDEO LIBRARY tab (historical "Breakdex albums" recovery scan) leaves the picker —
  it is a maintenance concern, not a browsing destination.

**Phase 2 — Subtitle legibility:**
- Move rows subtitle with the date (`effectiveDate` idiom), not
  `originalVideoName`. Filenames demote to the detail screen.
- Review-checklist rule: no content hash, UUID, or raw filename is ever rendered as
  primary or secondary text on a library surface.

**Phase 3 — Multi-user release gate (checklist, almost no code):**
- Names the four gates that make "sync done" a measurement: asset truth (rides
  `fix-video-backup-truth-and-unify-account` Phase 4), sync totality
  (`make-sync-total-and-registry-driven`), Phase M soak/flip (Appwrite master change),
  and a **fresh-second-user end-to-end proof** — the one net-new item: a Google account
  that is not the owner's signs in, gets provisioned on its own Drive quota, imports a
  video, and sees it on its own web login, with zero crossover into user #1's space.

## Capabilities

- `video-picker` (new) — intent-based picker: In Breakdex + Import, honest metadata.
  Spec delta: `specs/video-picker/spec.md`.
- `library-legibility` (new) — dates over identifiers on library surfaces. Spec delta:
  `specs/library-legibility/spec.md`.
- `sync-release-gate` (new) — the conditions under which multi-user sync is declared
  released. Spec delta: `specs/sync-release-gate/spec.md`.

## Dependencies & sequencing

Phase 1's "In Breakdex" list is trustworthy only after the manifest is honest —
`fix-video-backup-truth-and-unify-account` 4.7 (hash-indexed sandbox rescue) lands
first. Phase 2 is independent and can start immediately. Phase 3's checklist ticks last
by definition; its fresh-user proof additionally needs that change's Phase 3
(one-account auth) so user #2's experience is the released one-button flow, not the
legacy two-consent flow.

## Footprint estimate

| Surface | Current | Target |
| --- | --- | --- |
| `lib/shared/widgets/metadata_video_picker_sheet.dart` | ~1050 LOC | +90/−120 (tab collapse, manifest-backed list, duration probe) |
| `lib/features/move_list/widgets/move_row.dart` (subtitle) | ~245 LOC | +6/−4 |
| Category screen row subtitle | ~830 LOC | +6/−4 |
| Review checklist (`openspec/AGENTS.md` or docs manual) | — | +4 lines |
| Fresh-user runbook (`docs/`) | — | +40 lines (doc only) |
| Tests | — | +10–14 (picker widget tests on pure-override harness, subtitle unit/widget, duration-probe unit) |

## Non-goals

- **No new storage or schema** — the picker's In Breakdex tab is a view over
  `asset_manifest` + owning entities; durations are probed and cached in memory, not
  persisted (a duration column is a separate decision if probing proves slow).
- **No thumbnail pipeline** — same ruling as 2.3 in the backup change: frame extraction
  does not exist yet and is not invented here.
- **No changes to import mechanics** — the Import tab reuses the existing PhotoKit
  pagination and `VideoPickResult` contract unchanged.
- **No cross-user sharing, no E2EE, no CRDTs** (locked non-goals).

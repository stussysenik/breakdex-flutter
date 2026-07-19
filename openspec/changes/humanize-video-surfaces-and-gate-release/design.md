# Design — humanize-video-surfaces-and-gate-release

## D1 — The picker's library tab reads the manifest, not the filesystem

The current APP VIDEOS tab is a raw recursive directory scan
(`metadata_video_picker_sheet.dart:210-254`): titles are `basename(path)` (hash
suffixes and all), "creation date" is `stat.changed` (ctime — moves/renames reset it),
duration is a hardcoded `1`. Every defect is a consequence of re-deriving metadata from
the filesystem when the database already holds the truth.

**Ruling:** In Breakdex is a query, not a scan — live manifest rows joined to owning
moves/combos: title = owning entity's name (fallback: basename with the ` - hash8`
suffix stripped), date = the owner's `effectiveDate` idiom from
`add-library-time-and-metadata-browsing` (manifest `createdAt` when ownerless), path =
`VideoPathResolver` (which self-heals). Ownerless-but-live rows still appear — listing
what the app holds is the tab's contract — but they render with the humanized fallback
title, never a raw UUID.

This depends on the manifest being honest about paths, which is exactly what
`fix-video-backup-truth-and-unify-account` 4.7 (D10, hash-indexed sandbox rescue)
delivers. Sequencing, not coupling: the picker code has no dependency on the rescue
lane, it just shouldn't ship a "trustworthy" list before the underlying rows are.

## D2 — Durations are probed, never fabricated

The `duration: 1` hack exists because `formatDurationBadge` hides the badge at `<= 0`
and someone wanted badges. Inverted priorities: a fabricated `0:01` on every tile is
worse than no badge.

**Ruling:** probe real duration lazily per visible tile (AVAsset metadata via the
existing video-controller seam), cache in memory for the sheet's lifetime, and while
unprobed or unprobeable show **no badge** — the `<= 0` behavior is correct and now
intentional. No duration column, no migration; if probing proves slow on 200-item
libraries, persisting becomes its own decision with measurements in hand.

## D3 — Where the VIDEO LIBRARY tab goes

`discoverRecoverableManagedAssets` scans historical "Breakdex" Photos albums — a
recovery/maintenance capability, not a browsing surface, and its unsorted album-order
listing is the owner's "doesn't show the most recent" complaint. It leaves the picker.
Its existing entry point in the recovery/settings surface is unchanged; if none proves
reachable, exposing one there is in scope for the removal task — removing the tab must
not orphan the capability.

## D4 — Subtitle: date displaces filename, filename demotes to detail

`add-library-time-and-metadata-browsing` added date *lines* but left
`originalVideoName` in the subtitle slot, so rows lead with UUIDs. The subtitle becomes
the date ("Added Jun 17" / "Filmed Jun 17" per the effectiveDate source), matching the
sort dimension so what you sort by is what you see. `originalVideoName` remains on the
move detail screen — provenance is real information, just not row-level information.

**Review rule (added to the checklist):** no content hash, UUID, or raw filename as
primary/secondary text on any library surface. This is the UI face of the D10 axiom in
the backup change — identifiers are for machines; surfaces show names and dates.

**Addendum (2.2, 2026-07-19) — an identifier is opt-in, never a fallback.** The move
detail screen carried the same defect one layer down: a caption under the move's name
rendering `originalVideoName`, falling back to `ID: <hash8>`. "Provenance remains on the
detail screen" above means the *labeled* Video Info row, not a bare caption — a subtitle
slot is a subtitle slot on every surface. That caption now shows the added date through
the shared `LibraryDateLabel`, and is owner-selectable via `MoveDetailCaption`
(Date / Filename / ID / None, default Date).

The rule the preference must not break: **selecting `Filename` on a move that has no
filename resolves to the date, not to a hash.** Fallback is where identifiers leak back
in — a mode is a request for a *kind* of information, and silently substituting a
machine identifier when that kind is unavailable is how the original defect arose.
`createdAt` is non-null on every move, so an honest fallback always exists. A property
test walks every mode against a move with neither filename nor hash and asserts only
`contentId` can produce an `ID:` string.

**Correction to note, because the first reading was wrong.** The caption initially looked
like a duplicate of the panel's `Original` row, i.e. safe to delete. It is not: the panel
is gated on `move.videoPath != null` while the caption was gated on identity, so a
**cloud-only** move — bytes not local, hash present, precisely what the backup change
produces — renders no panel, and the caption was its only identifying text. Deleting it
would have been a silent information loss (D11's lesson: a disappearing identity reads as
a soft-delete). The date keeps that slot populated. The residual finding — provenance
placement keyed on byte locality rather than on identity, so *which* surface carries it
flips with whether the bytes happen to be local — is filed under 2.3 as a checklist item,
not fixed here.

## D5 — The release gate is a spec so it can be false

"Sync is done" has been a vibe repeatedly (see `feedback_verified_layer_labeling`:
"auth works" while zero user accounts existed). Making the gate a requirement with
scenarios makes it *falsifiable*: each gate names the change/task that proves it, and
the declaration tick requires linked evidence. The only net-new engineering surface is
the fresh-second-user proof — everything else is cross-referenced, not duplicated, per
the extend-don't-umbrella convention. The fresh-user proof deliberately uses a
non-owner Google account end-to-end (sign-in → provisioning on their Drive quota →
import → their web login) because multi-user is a claim about user #2, and only user #1
has ever existed.

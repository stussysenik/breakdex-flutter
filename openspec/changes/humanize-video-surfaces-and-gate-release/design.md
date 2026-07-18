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

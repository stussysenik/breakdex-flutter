# Fix Video Backup Truth + One-Account Magic Sync

## Why

Live evidence from the owner's device (2026-07-17, screenshots + Drive inspection) proved
the video-backup pipeline is structurally dishonest and practically stalled:

- **Integrity Report: 67 checked · 0 OK · 67 "missing"** — while every one of those videos
  plays fine in the app. `IntegrityVerifier` hashes `asset.localPath` (a *relative* path by
  design, v10+) without `VideoPathResolver.toAbsolute()`
  (`lib/core/sync/integrity_verifier.dart:152`), so every check throws
  `PathNotFoundException`. The uploader resolves correctly
  (`asset_sync_engine.dart:321`); the verifier forgot.
- **Only 1 of 67 videos reached Google Drive** after the owner connected Drive — yet the
  UI said **"All synced"**. Three compounding faults:
  1. `_uploadUnderprotected` **returns** on the first `waitForWifi` file instead of
     skipping it (`asset_sync_engine.dart:249-252`) — one over-cap file blocks every file
     behind it.
  2. `_processQueue` processes only `maxConcurrent` (1–2) operations per cycle with no
     drain loop (`asset_sync_engine.dart:261`) — a 67-video library needs ~34 manual
     sync taps to upload.
  3. `syncHealthProvider` returns `SyncHealth.allSynced` **as the default** when the
     engine has never emitted progress (`sync_providers.dart:355`) — the label is a
     default, not a measurement.
- **Nobody can tell which Google account holds the backup.** The Drive row says only
  "Connected"; the app-login row shows the Appwrite email. The owner searched the wrong
  Drive first. Two lookalike Google sign-ins (Appwrite OAuth for data, `google_sign_in`
  for video bytes) is the product's single worst misdirection for a dancer who should be
  thinking about moves, not account plumbing.
- **Web offers a tappable Drive row that can only fail** — `google_sign_in` Drive setup
  is not wired for web.

Product ruling (owner, 2026-07-17): backup must work like magic — one sign-in, full
quality, honest status. This change delivers the truth-and-throughput floor now and the
one-account unification behind it.

## What Changes

**Phase 1 — Backup truth & throughput (pure fixes, red/green each):**
- Integrity verifier resolves stored relative paths before hashing.
- Upload sweep skips (not aborts on) files deferred by network policy.
- A sync cycle drains the operation queue in `maxConcurrent` batches until empty,
  honoring pause/cancel between batches.
- Sync health is computed from the persistent protection state (underprotected count in
  Drift), never from an unemitted-stream default. "All synced" becomes impossible while
  any live asset lacks a verified cloud copy.
- Dev-only diagnostics dump (manifest rows, copies by provider×status, operations by
  status) so on-device state is inspectable evidence, not guesswork.

**Phase 2 — Account clarity (small UI):**
- The Drive row shows the connected Google account email.
- On web, the Drive row renders as unavailable (visibly degraded, not tappable).

**Phase 3 — One-account magic (owner-gated design, see design.md):**
- Request the `drive.file` scope in the existing Appwrite Google OAuth flow; drive video
  backup with the session's `providerAccessToken`. One Google sign-in = app login + video
  backup, on mobile *and* (later) web. The `google_sign_in` provider path stays as the
  fallback until the new path is proven (additive, flagged).

## Capabilities

- `video-backup` (new) — truthful integrity verification, resilient upload sweep, queue
  drain, honest health. Spec delta: `specs/video-backup/spec.md`.
- `backup-account` (new) — provider account visibility, web affordance honesty,
  one-account unification. Spec delta: `specs/backup-account/spec.md`.

## Footprint estimate

| Surface | Current | Target |
| --- | --- | --- |
| `lib/core/sync/integrity_verifier.dart` | 235 LOC | +3 (resolve path) |
| `lib/core/sync/asset_sync_engine.dart` | ~600 LOC | +15/−5 (sweep skip, drain loop) |
| `lib/core/providers/sync_providers.dart` | ~400 LOC | +15 (DB-derived health) |
| `lib/features/settings/widgets/cloud_sync_section.dart` | ~300 LOC | +20 (email, web state) |
| Dev diagnostics (existing dev panel) | — | +40 |
| Phase 3 gateway (`lib/core/sync/providers/`) | — | +120 (new token-backed Drive client, flagged) |
| Tests | — | +8–12 focused tests (each fix red/green) |

## Non-goals

- **No transcoding / quality work** — uploads are already byte-exact (content-hash named,
  hash-verified). The "low resolution" the owner saw is Drive's preview player, not the
  stored file. Data-safety rule "original bytes are truth" already covers this.
- **No web video playback** — pointer sync for `asset_manifest`/`asset_copies` rides
  `make-sync-total-and-registry-driven` (this change files the reclassification note
  there; see tasks 1.6). Web playback = pointer sync + URL resolver + web token, specced
  separately once Phase 3 lands the token half.
- **No iCloud changes** — same sweep/drain fixes benefit it for free; no iCloud-specific
  work.
- **No cross-user sharing, no E2EE** (locked non-goals).

# Evolve the Web Mirror into a Read-Write Breakdex Platform

## Summary

Supersede the **read-only** `add-web-mirror-player` direction with a **read-write** web app
that can edit the library from a desktop (the "production storefront"): quick journal
reflections, renames, metadata edits, export governance, and video swap-out — all while the
mobile app keeps working unchanged.

The unlock is architectural, and it is the property the owner named directly: **a shared
backend becomes the source of truth; the phone's Drift database and the web's local store both
become caches** of that truth, with **persistent, lazy media** (download once, never
re-download). This dissolves the "phone overwrites Drive on every sync" clobber problem that
makes web writes unsafe today — once both clients reconcile against one canonical truth,
writing from either side is safe.

Identity and media are centralized on a **single Google account (`senik456@gmail.com`)** used
on *both* the phone's Drive sync and web sign-in, so there is exactly one Drive holding the
globally-synced media.

This change is **brownfield-safe and strictly sequenced by risk**: Phase 1 stands up the
shared-truth + cache foundation behind the existing behavior (additive, no destructive
migration); Phase 2 turns on web CRUD against that truth; Phase 3 adds media governance and
video swap-out. Nothing in Phase 1 changes stored rows or removes user state.

## Motivation

- **Real-life DX.** The owner often cannot use the phone (e.g. at work) but wants to do quick
  text edits and journal reflections on training, rename things, and govern exports from a
  desktop. The current mirror is view-only, so none of that is possible.
- **The read-only model cannot grow into this.** `add-web-mirror-player` is explicitly
  "never writes, no backend" and today's sync is one-way (phone → Drive, full-manifest
  overwrite via `manifest_sync_service.dart`). Any web write to `manifest.json` is clobbered on
  the phone's next debounced upload. Read-write **requires** a shared source of truth.
- **The repo already chose a direction.** `add-beam-web-architecture-foundation` commits to a
  canonical backend (`Phoenix + Postgres + S3-compatible storage`) with provider pluggability,
  precisely to avoid parallel architectures. This change implements the *first concrete slice*
  of that "web-access-foundation" capability instead of inventing a competing one.

## Relationship to existing changes

- **Supersedes** `add-web-mirror-player` for everything past read-only. The read-only mirror,
  Drive read layer, auth gate, and demo fixtures it built are **reused as-is** as the read path
  and the offline/cache fallback — they are not thrown away.
- **Implements** the first shippable slice of `add-beam-web-architecture-foundation`'s
  `web-access-foundation` capability (canonical backend reachable from web).

## Data safety (non-negotiable — production app with deployed data)

- **Additive first.** Phase 1 introduces the shared-truth + cache layer *alongside* current
  behavior. The phone keeps writing its local Drift DB as it does today; the canonical backend
  is populated by a one-time, **non-destructive backfill** (read local → write backend; never
  the reverse-delete).
- **Never delete user state.** No phase deletes rows, videos, or manifest data. Renames and
  edits are updates; "remove" in the UI means archive/soft-delete with recovery, matching the
  app's existing archive semantics.
- **Reversible cutover.** Promoting the backend to source of truth is gated behind a verified
  two-way reconcile; until verified, the local DB remains authoritative and the backend is a
  shadow copy. The cutover can be rolled back to local-authoritative.
- **Media is copy-then-verify.** Video swap-out and export never delete the prior media until
  the replacement is uploaded, hashed, and confirmed in the canonical store.
- **One account, least privilege.** All data lives in `senik456@gmail.com`'s Drive; web keeps
  the `drive.file` scope (only files this project created) unless cross-client visibility forces
  `drive.readonly`.

## Scope

### In scope
- **Shared source of truth (provider-agnostic):** a sync contract where a canonical backend
  holds truth and clients hold caches; conflict resolution; non-destructive backfill; reversible
  cutover. Provider selection is an explicit `design.md` decision (see Open Decisions).
- **Local cache + lazy persistent media:** phone (Drift) and web (IndexedDB/Cache API) cache the
  truth; videos download once and persist across reloads (no re-download).
- **Web CRUD:** create/edit journal entries, rename moves/combos, edit metadata — writes hit the
  canonical truth and propagate to the phone.
- **Media governance:** export controls and video swap-out as writes to the globally-synced
  media, copy-then-verify.
- **Enterprise web shell:** persistent toolbar, clear sections, and **breadcrumb navigation**;
  purposeful UI animations/transitions.
- **Identity centralization:** single Google account (`senik456@gmail.com`) for identity + Drive
  across phone and web; allowlist updated accordingly.
- **Reactive streams:** RxJS on the web client; Riverpod + (optional) `rxdart` on Flutter — no
  RxJS added to Dart.

### Out of scope
- Standing up the *full* Phoenix/Postgres/S3 backend (only the first slice + the contract).
- Multi-tenant / multi-user beyond the owner's account(s).
- Rewriting the Flutter app's local-first runtime; it remains the offline authority until cutover
  is verified.
- Real-time collaborative editing / CRDT merge (single-writer-at-a-time assumed; contract leaves
  room for it later).

## Open decisions (require owner sign-off — see `design.md`)
1. **Source-of-truth provider:** honor the documented `Phoenix + Postgres + S3` contract, or use
   **Firestore** as a faster interim provider behind the same contract? (Firestore ships faster
   but deviates from the recorded architecture direction.)
2. **Drive scope:** keep `drive.file` or move to `drive.readonly` if cross-client media
   enumeration is unreliable for the web swap-out flow.

## Impact
- **New web capabilities:** `shared-source-of-truth`, `web-library-crud`, `media-governance`,
  `web-app-shell-navigation`, `identity-centralization`.
- **Mobile (additive):** a backend sync client + non-destructive backfill; no schema deletion.
- **Reuses:** the entire read-only mirror (`web-mirror/`) as the read path + offline cache.

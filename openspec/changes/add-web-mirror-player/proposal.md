# Add Web Mirror Player — Thin Read-Only Library Viewer on Vercel (Drive + Firebase Auth)

## Summary

Ship the first **web-access slice**: a thin, **read-only** web app (Next.js, deployed to
Vercel) that mirrors the user's entire Breakdex library — moves with video playback, combos,
journal notes, practice plans, and FSRS/review state — by reading the `manifest.json` the
mobile app already publishes into the user's own Google Drive, and streaming the videos
straight from that same Drive folder.

The web app authenticates with **Firebase Auth (Google provider)** restricted to an owner
allowlist; the *same* Google sign-in also requests the `drive.file` OAuth scope, so one login
yields both the session (identity/allowlist) and the token used to read Drive. No Firestore
and no backend server are introduced — the fat `manifest.json` in Drive is the index.

This is the concrete implementation of the deferred task **3.4** of
`add-beam-web-architecture-foundation` ("Define the first web-access slice that can ship
without rewriting the mobile app").

## Motivation

- The user owns their footage (Drive) and their graph (the manifest). Today that data is only
  reachable inside the mobile app. A read-only web mirror makes "your data is just files in
  your Drive" *visible* — a frontend proof that the BYO-Drive model works end to end.
- The mobile half is **already built**: `manifest_sync_service.dart` serializes the full
  library and uploads `manifest.json` to the Drive `Breakdex/` folder (debounced 5s,
  activated in `main.dart`), and `gdrive_provider.dart` deliberately uses `driveFileScope`
  "so the web viewer can access files." The remaining work is mostly the web client itself.
- A separate Next.js app on Vercel is the natural fit for a thin, view-only surface (small
  bundle, native Vercel deploy, true read-only) and avoids standing up server infrastructure.

## Data safety (non-negotiable — production app with deployed data)

This change is **strictly additive and read-only with respect to user data**:

- **The web app never writes.** It requests `drive.file` (the scope the app already grants on
  mobile), reads `manifest.json` and video bytes, and renders them. No create/update/delete
  Drive calls. No mutation of the manifest. No Firestore writes (no Firestore at all in v1).
- **The mobile change is additive.** Extending the published manifest with combo **notes** and
  **plans** adds fields to a JSON file that is regenerated on every sync; it touches no
  database schema, runs no migration, and changes no stored row. Existing manifest consumers
  ignore unknown fields.
- **No secrets in the repo.** Firebase web config and the OAuth Web client ID are injected via
  environment variables (Vercel env + local `.env.local`), never committed.
- **Access is allowlisted.** Only the owner's Google account(s) can load the mirror; everyone
  else is rejected at the auth gate even if they reach the URL.

## Scope

### In scope
- **Mobile (additive):** extend `LibraryManifest` + `ManifestSerializer` so the published
  `manifest.json` also carries combo journal **notes** (`ComboNoteEntries`) and practice
  **plans** (`ComboPlans`) — the user-authored data needed for a full mirror.
- **Web app (new):** a Next.js app (in `web/` or a sibling repo) that
  - gates entry behind Firebase Auth (Google), restricted to an owner allowlist;
  - obtains a `drive.file` OAuth token from the same sign-in;
  - fetches `Breakdex/manifest.json` from Drive and resolves each move's video by content
    hash (`Breakdex/<contentHash>.mp4`);
  - renders a **read-only** mirror: moves library + inline video playback, combos and their
    move sequences, journal notes, practice plans/calendar, and FSRS/review stats.
- **Infra:** register a **Web app** in the existing `breakdex-flutter` Firebase project, create
  a **Web OAuth client** in the same Google Cloud project, and deploy to Vercel with env-var
  configuration and secrets hygiene.

### Out of scope (explicit non-goals)
- **No Firestore** and **no backend server** in v1 — the Drive manifest is the index.
- **No writing from the web** — no recording, editing, rating, or planning on web. View-only.
- **No multi-user / sharing** — single owner allowlist only.
- **No Flutter-web build** — the web surface is a separate thin app (a deliberate, recorded
  exception to the "one Flutter codebase" posture, justified by "thin, Vercel, read-only").
- **No semantic Drive renaming** — v1 resolves videos by the existing content-hash filenames;
  the semantic-naming roadmap item is independent.

## Relationship to other changes

- **Implements** the deferred task 3.4 of `add-beam-web-architecture-foundation` (the first
  web-access slice) and honors its `web-access-foundation` posture (web reads the same
  user-owned data, no parallel architecture).
- **Reuses, does not modify,** the sync engine (`gdrive_provider.dart`,
  `manifest_sync_service.dart`); the only mobile edit is additive fields in the serializer.
- **Independent of** `add-combo-journey-system` and `tighten-combo-journey-and-review-polish`
  beyond reading the `ComboNoteEntries` / `ComboPlans` they already populate.
- Defers, per `ROADMAP.md`, semantic Drive naming (Phase 4) and any Firestore graph sync
  (Phase 5 multi-device); those are not prerequisites for a read-only mirror.

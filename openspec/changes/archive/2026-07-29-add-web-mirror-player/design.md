# Design — Web Mirror Player

## Context

The mobile app already publishes a full-library `manifest.json` to the user's Google Drive
(`Breakdex/` folder) and stores videos there content-addressably (`<contentHash>.mp4`). The
goal is a thin, read-only web surface that reflects that data — a "mirror / proof" of the
BYO-Drive model — without introducing a backend or mutating anything.

Three forks were resolved with the user before design:

1. **Web shape:** a separate **Next.js app on Vercel** (not a Flutter-web build). Recorded
   exception to the "one Flutter codebase" posture; justified by the thin, view-only nature.
2. **Data model:** **Drive OAuth + `manifest.json` in Drive** (no Firestore in v1). The fat
   manifest is the index; Firebase is the auth gate only.
3. **v1 content:** a **full mirror** of user-authored data (moves, combos, notes, plans, FSRS),
   not just a video list.

## Goals / Non-goals

- **Goals:** read-only mirror of the whole library; one-login auth that yields both identity
  and a Drive token; zero new backend; no secrets in the repo; owner-only access.
- **Non-goals:** writing from web; Firestore; multi-user; Flutter-web; semantic Drive renaming.

## Architecture

```
  MOBILE (Flutter)              GOOGLE DRIVE (user-owned)        WEB (Next.js on Vercel)
  ────────────────              ─────────────────────────        ───────────────────────
  ManifestSerializer            Breakdex/manifest.json   ◄──────  Firebase Auth (Google)
   (+ notes, + plans)   ──────► Breakdex/<hash>.mp4               + owner allowlist
  manifest_sync_service         Breakdex/<hash>.mp4   ◄────────   + drive.file OAuth token
   (already uploads)                                              fetch manifest → render
                                                                  stream video from Drive
```

### Auth: one sign-in, two outputs

Use Firebase Auth's `GoogleAuthProvider` with `addScope('https://www.googleapis.com/auth/drive.file')`.
A single popup/redirect sign-in produces:

- a **Firebase session** (the `uid`/email — checked against an owner allowlist), and
- a **Google OAuth access token** (`GoogleAuthProvider.credentialFromResult(...).accessToken`)
  used as the `Authorization: Bearer` for Drive REST calls.

This mirrors the mobile "unify to a single Google Sign-In that mints both the Firebase
credential and the Drive-scoped token" decision. The allowlist is a small env-configured set of
emails/uids; a signed-in account not on it is shown an "access denied" state and no Drive call
is made.

### Why `drive.file` is sufficient (and preferred over `drive.readonly`)

`drive.file` grants access only to files an application in the **same Google Cloud project**
created or opened. The mobile client and the new Web OAuth client live in the **same project**
(`breakdex-flutter`), so files the mobile app created under `drive.file` (the `Breakdex/`
folder, `manifest.json`, the `<hash>.mp4` videos) are visible to the web client under the same
scope. This keeps the blast radius minimal — the web app can see only Breakdex's own files,
never the rest of the user's Drive.

- **Fallback (documented, not default):** if cross-client `drive.file` enumeration proves
  unreliable in practice, fall back to `drive.readonly` (broader, sees all Drive). Decided at
  apply-time against a real account; v1 ships `drive.file` first.

### Video resolution contract

The manifest's `moves[].contentHash` maps to a Drive file named `<contentHash>.mp4` in the
`Breakdex/` folder. The web app lists the folder once (`files.list` with the folder id), builds
a `contentHash → fileId` map, and plays via the authenticated media endpoint
(`files.get?alt=media` with the bearer token, streamed into a `<video>`/blob URL, or a
short-lived `webContentLink`). No Drive file IDs need to be stored in the manifest; the hash is
the join key. (Semantic filenames are a future roadmap item and are out of scope here.)

### Reading the manifest

`manifest.json` lands in the `Breakdex/` folder (the uploader's `remotePath`
`breakdex/manifest.json` resolves to the file name `manifest.json` inside that folder). The web
app finds it by name within the folder, downloads it, and renders. Unknown/missing fields
degrade gracefully (e.g., an older manifest without `notes`/`plans` still renders moves/combos).

## Mobile delta (additive)

`LibraryManifest` and `ManifestSerializer` currently emit moves, combos, comboMoves,
categories, fsrsCards, decks, deckMoves, reviews, and assets — but **not** combo journal
**notes** (`ComboNoteEntries`: kind jot/status/plan, optional `videoPath`, body) or practice
**plans** (`ComboPlans`: planDate, completion). Add two new serialized collections:

- `notes[]` — `{ id, comboId, kind, body, videoContentHash?, createdAt }`
- `plans[]` — `{ id, comboId, planDate, completedAt? }`

These are new keys on the same JSON object; the manifest `version` is bumped and the web
reader tolerates their absence. No DB schema change, no migration — the serializer reads
existing tables (`ComboNoteEntries`, `ComboPlans`) that other changes already populate.

> Note: `ManifestSerializer.serialize()` uses `DateTime.now()` for `exportedAt`. We keep the
> existing call site as-is (changing the clock is the separate atomic-time workstream); we do
> not introduce new wall-clock reads in the added fields beyond passing through stored
> timestamps.

## Web app shape

- **Stack:** Next.js (App Router) + TypeScript, Firebase JS SDK (Auth only), `gapi`/REST for
  Drive. Client-rendered behind auth; no server routes needed for v1 (all reads are
  client-side with the user's own token). Optional: a thin route handler later if token
  handling needs to move server-side, but v1 is client-only to stay backend-free.
- **Location:** `web/` in this repo (simplest for a single owner) — kept out of the Flutter
  build. Alternatively a sibling repo; decided at apply-time. Either way it deploys to Vercel
  as its own project.
- **Views (read-only):** Library (moves grid + inline player), Combos (sequence + linked
  moves), Journal (notes timeline), Plans (calendar/list), Stats (FSRS state + review history).
  All projections of the manifest; no inputs that mutate.

## Secrets & deployment

- Firebase web config (`apiKey`, `authDomain`, `appId`, ...) and the OAuth Web client ID are
  **public-by-design client config** but still injected via `NEXT_PUBLIC_*` env vars (Vercel
  env + `.env.local`), never hardcoded. The owner allowlist is an env var.
- Required manual provisioning (the user runs these — the agent cannot mint credentials):
  1. Register a **Web app** in the `breakdex-flutter` Firebase project (gives web config).
  2. Enable **Google** as a sign-in provider in Firebase Auth.
  3. Create a **Web application OAuth client** in the same Google Cloud project; add the Vercel
     domain + `localhost` to Authorized JavaScript origins / redirect URIs.
  4. Add the Vercel deployment domain to Firebase Auth **Authorized domains**.
  5. `vercel login` + link the project; set env vars in Vercel.
- The agent scaffolds all code, env templates (`.env.example`), and Vercel config so these are
  the only manual steps.

## Risks / tradeoffs

- **`drive.file` cross-client visibility** — primary risk; mitigated by same-project clients
  and the `drive.readonly` fallback. Verified against a real account at apply-time.
- **Token lifetime** — Google access tokens are short-lived; the web app re-auths silently (or
  prompts) when a Drive call 401s. Acceptable for a view-only surface.
- **Large-video streaming in-browser** — use range/`alt=media` streaming or `webContentLink`;
  avoid loading whole files into memory.
- **Posture exception** — a separate JS app contradicts the locked "one Flutter codebase" rule.
  Recorded here deliberately; revisit if a second web surface ever appears (then reconsider
  Flutter-web or a shared package).

## Migration / rollout

- Mobile: ships the additive manifest fields in a normal app update; older app versions simply
  publish a manifest without `notes`/`plans` and the web tolerates it.
- Web: deploy to a Vercel preview first, validate against the owner's real Drive, then promote.
  Nothing about the web app can damage mobile or Drive data (read-only), so rollback is just
  taking the deployment down.

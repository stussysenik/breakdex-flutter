# Tasks — Add Web Mirror Player

## Phase 0: Provisioning (owner-run; agent provides exact commands)
- [x] 0.1 Register a **Web app** in the existing `breakdex-flutter` Firebase project; capture the web config — done (App ID `1:499240019967:web:68dcc699a392e14a04e9ca`; `.env.local` written).
- [x] 0.2 Enable **Google** sign-in provider in Firebase Auth; add `localhost` to Authorized domains — done (Firebase Console confirms Google = Enabled 2026-06-17; `localhost` auto-authorized). Vercel domain pending deploy (Phase 5).
- [ ] 0.3 Create a **Web application OAuth client** in the same Google Cloud project; add Vercel + `localhost` to JS origins / redirect URIs
- [ ] 0.4 `vercel login` and link the web project (agent supplies `! ` commands)

## Phase 1: Mobile manifest — add notes & plans (additive, no migration)
- [x] 1.1 Add `LibraryNote` and `LibraryPlan` models to `lib/core/web/library_manifest.dart`; add `notes`/`plans` to `LibraryManifest` + `toJson`; bump `version` (1 → 2)
- [x] 1.2 Read `ComboNoteEntries` and `ComboPlans` in `ManifestSerializer.serialize()` and map into the new collections
- [x] 1.3 Unit test: serializer emits `notes`/`plans` when present and empty arrays when absent; `flutter test` 7/7 green, `flutter analyze` clean
- [ ] 1.4 Verify on a real build that an updated `manifest.json` (with notes/plans) lands in the Drive `Breakdex/` folder (needs running app + Drive auth)

## Phase 2: Web app scaffold + auth gate
- [x] 2.1 Scaffold Next.js (App Router, TS) under `web-mirror/`, excluded from the Flutter build; `.env.example` documents required vars; `npm run build` green
- [x] 2.2 Initialize Firebase JS SDK (Auth only) from `NEXT_PUBLIC_*` env (`src/lib/firebase.ts`); Google sign-in requests `drive.file` scope and returns the access token
- [x] 2.3 Owner allowlist gate (`src/lib/allowlist.ts`); access-denied for non-owners; sign-in gate for unauthenticated; "Not configured" fail-safe when env missing (verified in chrome-devtools — no Drive call without config)
- [x] 2.4 Extract Drive access token from sign-in result; 401/403 → re-acquire token and retry (`src/lib/drive.ts` `DriveAuthError`)

## Phase 3: Drive read layer
- [x] 3.1 Resolve `Breakdex/` folder id; download `manifest.json`; parse into typed models tolerating missing `notes`/`plans` (`normalizeManifest`)
- [x] 3.2 List folder once; build `contentHash → fileId` map for video resolution (`src/lib/drive.ts`)
- [x] 3.3 Streaming playback via authenticated `alt=media` blob URL (cached); "video unavailable" fallback (demo verified — video served as HTTP 206 range)
- [x] 3.4 Verify `drive.file` cross-client visibility; switch to `drive.readonly` if unreliable — RESOLVED 2026-06-17: `drive.file` is per-app-created-files only and cannot see the phone-created `Breakdex/` folder cross-client, so scope switched to `drive.readonly` in `.env.local`. Empirical real-Drive confirmation rides on the owner sign-in (Phase 5). See `evolve-web-mirror-to-crud-platform` task 0.2.

## Phase 4: Read-only mirror UI — built & verified in chrome-devtools (demo fixture)
- [x] 4.1 Library view: moves grid + inline player (video playback verified end to end)
- [x] 4.2 Combos view: combo + ordered move sequence, each move clickable to play
- [x] 4.3 Journal view: notes timeline (kind pill, body, combo, date) — renders new manifest `notes`
- [x] 4.4 Plans view: practice plans with planned/done state — renders new manifest `plans`
- [x] 4.5 Stats view: review rating counts + FSRS state breakdown; empty-states for empty/older manifests
- [x] 4.6 Read-only invariant confirmed — no create/edit/delete affordance; every Drive call is a read

## Phase 5: Deploy & verify (needs Phase 0 credentials)
- [ ] 5.1 Set Vercel env vars; deploy a **preview**; validate sign-in + full mirror against the owner's real Drive
- [ ] 5.2 Confirm non-owner rejection and that all Drive calls are reads (network inspection)
- [ ] 5.3 Promote to production; record the URL (provisioning + deploy steps already in `web-mirror/README.md`)
- [ ] 5.4 Update `add-beam-web-architecture-foundation` task 3.4 reference (first web-access slice shipped)

# Breakdex Web Mirror

A **thin, read-only** web view of your Breakdex library. It reads the
`manifest.json` the mobile app publishes into your Google Drive `Breakdex/`
folder and streams the videos straight from that same folder. Firebase Auth
(Google) is the login gate; the same sign-in grants read access to Drive.

It never writes — not to Drive, not to the manifest, not to any backend. There
is no Firestore and no server. Access is restricted to an owner allowlist.

```
Mobile app ──► Drive: Breakdex/manifest.json + <hash>.mp4 ──► this web app (read-only)
```

---

## Run it

Requires Node 18+ and npm. All commands run from `web-mirror/`.

```bash
npm install
npm run dev          # boots Next.js on http://localhost:3000
```

`npm run dev` first regenerates the UnoCSS stylesheet (`predev` hook), then
starts the dev server. You should see `✓ Ready` and `Environments: .env.local`.

Two ways to view it:

| Mode | URL | Needs credentials? |
| --- | --- | --- |
| **Demo** | http://localhost:3000/?demo=1 | No — sample fixture |
| **Real** | http://localhost:3000 | Yes — Google sign-in to your Drive |

### Demo mode (no credentials)

Open **http://localhost:3000/?demo=1**. This loads
`public/sample-manifest.json` + `public/sample-video.mp4` so you can see every
view (Library, Combos, Journal, Plans, Stats) and video playback without any
Firebase or Drive setup. Good for UI work.

### Real mode (your Drive)

Open **http://localhost:3000**, click **Sign in with Google**, and pick the
owner account on the allowlist. The library then loads live from that account's
`Breakdex/` Drive folder.

This needs (a) a filled `.env.local` and (b) Google sign-in enabled once in the
Firebase console — see [Connect your Drive](#connect-your-drive-one-time-owner-only)
below. On the owner machine `.env.local` is already present; if it's missing,
`npm run dev` shows a "Not configured" screen and you should fill it first.

---

## Connect your Drive (one-time, owner-only)

These steps need interactive console logins the build cannot perform. The app
reuses the **existing `breakdex-flutter` Firebase project** and the already-
registered web app `breakdex-web-mirror`, so the only hard blocker for a *local*
sign-in is enabling the Google provider.

1. **Fill env** — if `.env.local` is not already present:
   ```bash
   cp .env.example .env.local
   ```
   Paste the Firebase web config (Console → Project settings → *Your apps* →
   Web → `breakdex-web-mirror`). Set `NEXT_PUBLIC_OWNER_ALLOWLIST` to the owner
   email(s) that may view the mirror.

2. **Enable Google sign-in** — Firebase Console → **Authentication → Sign-in
   method → Google → Enable → Save**. This is the one required toggle; without
   it sign-in fails with `auth/operation-not-allowed`. Enabling it also
   auto-provisions an OAuth client that already works on `localhost`.

3. **Sign in** — `npm run dev`, open http://localhost:3000, **Sign in with
   Google**, choose the allowlisted owner account.

> `localhost` is authorized by Firebase Auth automatically — you do **not** need
> the OAuth-origins or authorized-domains steps until you deploy (see
> [Deploy to Vercel](#deploy-to-vercel)).

### What each outcome means

| You see | Meaning |
| --- | --- |
| Library loads | ✅ Sign-in + Drive read work end-to-end. |
| "…is not on the owner allowlist" | Wrong account — the function is fine; sign in with an allowlisted email. |
| "No Breakdex folder" / "no manifest.json yet" | Sign-in + Drive token **succeeded**; the mobile app just hasn't synced once yet. |
| `auth/operation-not-allowed` | Step 2 (enable Google) isn't saved. |
| popup blocked / `unauthorized-domain` | Allow popups, or the origin isn't authorized (only relevant off `localhost`). |

---

## Deploy to Vercel

```bash
npm i -g vercel        # or use npx vercel
vercel login
vercel link            # create/link a project; set root dir to web-mirror/
# add the NEXT_PUBLIC_* vars from .env.local in the Vercel dashboard (or `vercel env add`)
vercel                 # preview deployment
vercel --prod          # promote
```

After the first deploy, authorize the live origin (not needed for `localhost`):

- **OAuth client** — Google Cloud Console → APIs & Services → Credentials →
  the Web client → add the Vercel URL to *Authorized JavaScript origins*.
- **Firebase Auth** — Console → Authentication → Settings → *Authorized
  domains* → add the Vercel domain.

`npm run build` runs `next build` (with a `prebuild` UnoCSS pass); `npm start`
serves the production build on port 3000.

---

## Environment variables

See [`.env.example`](./.env.example). All are `NEXT_PUBLIC_*` client config
(public by design — none are secret), still injected via env so the repo carries
no live configuration. `.env.local` is gitignored.

| Var | Purpose |
| --- | --- |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | Firebase web app API key |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | Firebase web app id (required to init) |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | Defaults to `breakdex-flutter.firebaseapp.com` |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Defaults to `breakdex-flutter` |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | Firebase sender id |
| `NEXT_PUBLIC_OWNER_ALLOWLIST` | Comma-separated emails allowed to view |
| `NEXT_PUBLIC_DRIVE_SCOPE` | Drive OAuth scope (see below) |

---

## Scope notes

- Default Drive scope is `drive.file` (sees only files this project created — the
  `Breakdex` folder). If cross-client enumeration is unreliable, set
  `NEXT_PUBLIC_DRIVE_SCOPE=https://www.googleapis.com/auth/drive.readonly`.
- Video resolution: a move's `contentHash` maps to the Drive file `<hash>.mp4`.
- Manifest types mirror `lib/core/web/library_manifest.dart` (manifest v2).

## How it works

- `src/lib/firebase.ts` — `signInWithGoogle()`: one Google popup yields both the
  Firebase session and a Drive OAuth access token (requests `NEXT_PUBLIC_DRIVE_SCOPE`).
- `src/lib/allowlist.ts` — `isOwner()`: rejects any email not on the allowlist
  before any Drive request is made.
- `src/lib/drive.ts` — `loadFromDrive()`: read-only. Finds the `Breakdex/`
  folder, loads `manifest.json`, builds the `contentHash → fileId` map, and
  lazily resolves video object-URLs. Never issues create/update/delete.
- `src/app/page.tsx` — phase machine: `init → needConfig → signedOut → loading →
  ready / error`.

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

## Local preview (no credentials)

```bash
npm install
npm run dev
# open http://localhost:3000/?demo=1   ← full UI against a sample fixture
```

`?demo=1` loads `public/sample-manifest.json` + `public/sample-video.mp4` so you
can see every view (Library, Combos, Journal, Plans, Stats) and video playback
without any Firebase or Drive setup.

## Real setup (owner-run, one-time)

These steps require interactive logins the build cannot perform. Run them
yourself; the app reuses the **existing `breakdex-flutter` Firebase project**.

1. **Register a Web app** in Firebase → Project settings → *Your apps* → Web.
   Copy `apiKey` and `appId`.
   ```bash
   npx firebase-tools login
   npx firebase-tools apps:create WEB "Breakdex Web Mirror" --project breakdex-flutter
   npx firebase-tools apps:sdkconfig WEB --project breakdex-flutter   # prints the web config
   ```
2. **Enable Google sign-in:** Firebase Console → Authentication → Sign-in method
   → enable **Google**.
3. **Create a Web OAuth client:** Google Cloud Console → APIs & Services →
   Credentials → *Create OAuth client ID* → **Web application**. Add Authorized
   JavaScript origins: `http://localhost:3000` and your Vercel domain.
4. **Authorize domains:** Firebase Console → Authentication → Settings →
   Authorized domains → add your Vercel domain.
5. **Fill env:** `cp .env.example .env.local` and paste the values from step 1.
6. Run `npm run dev`, sign in with the owner account, and the library loads from
   your Drive. (Requires that the mobile app has synced at least once, so
   `Breakdex/manifest.json` exists.)

## Deploy to Vercel

```bash
npm i -g vercel        # or use npx vercel
vercel login
vercel link            # create/link a project; set root dir to web-mirror/
# add the NEXT_PUBLIC_* vars from .env.local in the Vercel dashboard (or `vercel env add`)
vercel                 # preview deployment
vercel --prod          # promote
```

After the first deploy, add the Vercel URL to the OAuth client origins (step 3)
and Firebase Authorized domains (step 4).

## Environment variables

See [`.env.example`](./.env.example). All are `NEXT_PUBLIC_*` client config
(public by design) except none are secret — but they are still injected via env
so nothing is committed. `NEXT_PUBLIC_OWNER_ALLOWLIST` controls who may view.

## Scope notes

- Default Drive scope is `drive.file` (sees only files this project created — the
  `Breakdex` folder). If cross-client enumeration is unreliable, set
  `NEXT_PUBLIC_DRIVE_SCOPE=https://www.googleapis.com/auth/drive.readonly`.
- Video resolution: a move's `contentHash` maps to the Drive file `<hash>.mp4`.
- Manifest types mirror `lib/core/web/library_manifest.dart` (manifest v2).

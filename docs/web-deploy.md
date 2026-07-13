# Web deploy — Vercel pipeline (launch-wave L4 / task 4.3)

How the released Flutter web app ships to **breakdex.vercel.app** (0.3 ruling: Vercel
subdomain today, custom product domain swaps in later without re-plumbing).

## The pipeline (already wired)

```
merge to main
  └─ Release workflow (release.yml)
       ├─ npx semantic-release  → bumps pubspec version+build, writes docs/CHANGELOG.md, tags vX.Y.Z
       └─ if a version published → calls deploy-web.yml with that tag
            └─ flutter build web --release --build-number <pubspec build>
               └─ vercel deploy build/web --prod   → breakdex.vercel.app
```

- **Build number**: the single monotonic number in `pubspec.yaml` (semantic-release-pub
  bumps it); the web build embeds it via `--build-number`. Mobile CI (Phase 5) passes the
  same number — one version of record across platforms (4.2).
- **Static config**: `web/vercel.json` (copied into `build/web/` by the Flutter build)
  sets the SPA fallback and marks the entry files (`index.html`, service worker,
  `flutter_bootstrap.js`, `version.json`, `main.dart.js`) `no-cache` so the app's own
  update check lands the new build on the next refresh. It intentionally does **not** set
  `Cross-Origin-Embedder-Policy: require-corp` — that would block cross-origin Google Drive
  video and Google OAuth. Drift's web DB degrades gracefully without cross-origin isolation
  (OPFS via locks → IndexedDB fallback, degradation surfaced), so isolation isn't required.

## One-time owner setup (OAuth-gated — do this once)

The pipeline self-skips (logs a warning, exits 0) until these exist, so nothing stalls.

1. **Create/link the Vercel project** (needs your Vercel login):
   ```bash
   npm i -g vercel
   vercel link          # pick/create the "breakdex" project (scope = your account/team)
   ```
   This writes `.vercel/project.json` locally with the org + project IDs. (Do not commit it.)
2. **Set the production domain** in the Vercel dashboard → Project → Domains: add
   `breakdex.vercel.app`. (A custom domain can be added later with zero redeploy.)
3. **Add three GitHub repo secrets** (Settings → Secrets and variables → Actions):
   - `VERCEL_TOKEN` — Vercel account token (Account Settings → Tokens).
   - `VERCEL_ORG_ID` — from `.vercel/project.json` (`orgId`).
   - `VERCEL_PROJECT_ID` — from `.vercel/project.json` (`projectId`).

That's it — the next release auto-deploys.

## Rollback

- **Fast (recommended for incidents):** Vercel dashboard → Deployments → pick the last good
  production deployment → **Instant Rollback / Promote**. No rebuild; serves immediately.
- **Tag of record:** GitHub → Actions → **Deploy Web (Vercel)** → *Run workflow* → set
  `ref` to the previous good tag (e.g. `v1.3.0`). It rebuilds that tag and deploys it prod.

Because the app auto-updates on refresh and every entry file is `no-cache`, users pick up a
rollback on their next load — no action on their part (this is the user-facing promise in
`GUIDE.md` → "How updates arrive").

## Manual (re)deploy

GitHub → Actions → **Deploy Web (Vercel)** → *Run workflow* → `ref` = any tag/SHA. Same job
the release uses.

# Phase M runbook — owner device pass + live provisioning (2026-07-13)

Prep artifact for the morning device pass that closes the overnight wave. The wave code is
done, green, and **pref-OFF** (device behaviour is byte-identical to pre-wave until you flip
each kill-switch). Nothing here has been run against live — this is the exact, copy-paste,
**non-destructive** command set so provisioning is not improvised at the console.

> ⚠️ **NEVER `appwrite push tables --all`.** CLI 22.6.1 diffs omitted-`array` (config) vs
> `array:false` (deployed) as a change and **recreates existing columns** — it nuked all of
> `moves`'s attributes in 1R.1 and left unrepairable dangling indexes. Provision NEW tables
> **only** with the targeted `create-*` calls below.

Order: **(A) auth → (B) provision the two note tables → (C) redeploy Functions → (D) register
the web origin → (E) M.1–M.6 device pass → (F) push decision.** A–D are owner-gated infra; E is
the live proof; F is your call on the unpushed wave commits (`46abea0..HEAD`, ~17 incl. 5.3/5.4).

---

## A. Authenticate the CLI (headless, API key — not console session)

The CLI prefs `current` points at throwaway projects, **not** `breakdex` (`6a50f25b…`). Auth
from `.env.local` every session:

```bash
cd /Users/s3nik/Desktop/breakdex-flutter
set -a; source .env.local; set +a
# .env.local uses APPWRITE_SECRET / APPWRITE_API_ENDPOINT; the CLI wants these names:
export APPWRITE_ENDPOINT="${APPWRITE_API_ENDPOINT:-$APPWRITE_ENDPOINT}"
export APPWRITE_PROJECT_ID   # already breakdex 6a50f25b… in .env.local
export APPWRITE_API_KEY="${APPWRITE_SECRET:-$APPWRITE_API_KEY}"
appwrite client -e "$APPWRITE_ENDPOINT" -p "$APPWRITE_PROJECT_ID" -k "$APPWRITE_API_KEY"

# Verify you are pointed at the RIGHT project (must show breakdex, database `breakdex`):
appwrite health get
appwrite tables-db list-tables --database-id breakdex | grep -iE "moves|NoteEntries" 
# → you should see the 10 existing tables and NO moveNoteEntries/comboNoteEntries yet.
```

If `list-tables` shows the note tables already present, **stop** — they exist; skip section B.

---

## B. Provision the two note tables (targeted, non-destructive)

Both tables are identical in shape (5 columns, 2 indexes) and mirror `appwrite.config.json`
verbatim. `rowSecurity: true`, permissions `[]` (per-row user permissions enforced by the
Functions). Run the block once for `moveNoteEntries`, then again for `comboNoteEntries`.

```bash
DB=breakdex

for T in moveNoteEntries comboNoteEntries; do
  echo "── creating $T ──"
  appwrite tables-db create-table \
    --database-id "$DB" --table-id "$T" --name "$T" --row-security true

  # columns (order matches config; required cols take no --xdefault)
  appwrite tables-db create-string-column  --database-id "$DB" --table-id "$T" --key id        --size 128     --required true
  appwrite tables-db create-string-column  --database-id "$DB" --table-id "$T" --key userId    --size 64      --required true
  appwrite tables-db create-integer-column --database-id "$DB" --table-id "$T" --key updatedAt --required true
  appwrite tables-db create-string-column  --database-id "$DB" --table-id "$T" --key clientOpId --size 128    --required true
  appwrite tables-db create-string-column  --database-id "$DB" --table-id "$T" --key payload   --size 1000000 --required true

  # indexes (create AFTER columns settle to "available")
  appwrite tables-db create-index --database-id "$DB" --table-id "$T" --key by_user_id        --type key --columns userId id
  appwrite tables-db create-index --database-id "$DB" --table-id "$T" --key by_user_updatedAt --type key --columns userId updatedAt
done
```

**Verify (both tables, all columns `available`, both indexes `available`):**

```bash
for T in moveNoteEntries comboNoteEntries; do
  echo "== $T =="
  appwrite tables-db list-columns --database-id breakdex --table-id "$T" | grep -E "key|status"
  appwrite tables-db list-indexes --database-id breakdex --table-id "$T" | grep -E "key|status"
done
```

> If a `create-index` errors with "column not available yet", wait a few seconds and re-run
> just that index line — column creation is async. Do **not** re-run `create-table` (it will
> error "already exists"; that's harmless but noise).

---

## C. Redeploy the Functions (7-table allowlist)

The note tables are already in both allowlists (`functions/sync-push/lib/reconcile.dart`,
`functions/sync-pull/lib/pull.dart`). Redeploy so live picks them up:

```bash
appwrite push functions --activate true
# verify the two functions are enabled + newest deployment active:
appwrite functions list | grep -iE "sync-push|sync-pull"
```

---

## D. Register the web origin (makes 1.5's httpOnly cookie work)

In the Appwrite **console** → project `breakdex` → **Overview → Platforms → Add platform → Web**:
add the released web origin (and `http://localhost:<port>` for local web testing). Without this,
web OAuth (M.6) returns CORS 403 and the session cookie is never set. This is a console click —
no CLI.

---

## E. Device pass (M.1–M.6) — the live half

Detailed acceptance for each is in
`openspec/changes/migrate-canonical-backend-to-appwrite/tasks.md` (Phase M). Summary + the
**pref-flip order** (each cutover ships OFF; flip only after its soak):

| Step | Proves | Action |
| --- | --- | --- |
| **M.1** | brownfield gate | `flutter run` (flowdeck to manage the sim/device) → clean boot, no red screen, existing moves/videos intact |
| **M.2** | 3.1 live | Google sign-in on iOS via the callback scheme; kill+relaunch → session survives |
| **M.3** | 4.1 gated half | run real-data backfill; confirm row counts on backend match local (per entity) |
| **M.4** | every 4.x cutover | **the flip-the-prefs proof** — enable dual-write→dual-read one entity at a time; edit/delete/**note**/video-pointer on phone, confirm it crosses to web (and back) with **no data loss**; Drive video plays on web (1.4 live half) |
| **M.5** | 1R.4 | flip remote-config live (`kRemoteConfigLiveEnabled`); confirm flags/kill-switches/min-version gate read from `appConfig` |
| **M.6** | 1.5 live | web Google OAuth from the registered origin (section D); httpOnly cookie set; session persists on reload |

**Order within M.4** for each entity: verify OFF (baseline) → flip dual-**write** → soak → flip
dual-**read** → soak → confirm cross-surface. Notes and tombstones last (newest cutovers). If any
entity loses/duplicates data, flip its pref back OFF — that's the whole point of the guard — and
report before proceeding.

---

## F. The push decision (yours)

The wave commits sit local/unpushed: `46abea0..HEAD` (~17, incl. the 5.3/5.4/ledger commits).
They are additive, pref-OFF, and green
(`flutter analyze` 0; `flutter test` 916 green / 9 pre-existing reds / 0 regressions;
`flutter build web` green). Push is **your call** — nothing above depends on pushing first, and
pushing does not flip any device behaviour (all cutovers stay OFF until M.4).

```bash
git log --oneline origin/main..HEAD   # review the 13 before deciding
# git push origin main                 # when you choose to
```

---

*Verified against CLI 22.6.1 and `appwrite.config.json` on 2026-07-13. Commands mirror the
authored config exactly, so live tables are byte-identical to what a `push` would create — minus
the `push`'s destructiveness. Nothing here was executed against live.*

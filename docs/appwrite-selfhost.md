# Appwrite self-host cutover runbook (task 5.4)

> **Document-only.** Nothing here provisions live infra — it is the checklist for the day the
> owner decides to move off Appwrite Cloud onto a self-hosted box. Read
> [`gotcha-appwrite-push-all-destructive`](#never-push-tables---all) before touching schema.
> Endpoint of record and platform posture live in root `CLAUDE.md`; sync internals in
> [`docs/manual/04-sync.mdx`](./manual/04-sync.mdx).

## 0. Why this is easier than a generic cloud→self migration

The one architectural fact that shapes this whole runbook: **the device (Drift/SQLite) is the
canonical source of truth; Appwrite is a shadow copy.** Video bytes live on the user's Google
Drive (pointers only in Appwrite). So a self-host cutover is *not* a high-stakes data transplant —
a freshly stood-up, empty self-hosted Appwrite can be **re-backfilled from the device** with the
same `SyncBackfillService` used in Phase 4, and the videos never move. The only data that is *not*
reconstructable from the device is **server-derived FSRS** (computed by the `sync-pull` /
scheduling Function); that is the sole reason a MariaDB dump/restore step exists at all.

Restore paths, in order of preference:
1. **Re-backfill from device local truth** (`lib/core/sync/backfill/sync_backfill_service.dart`) — the default.
2. **Client-side JSON metadata export** on the user's Drive (`Breakdex/backups/`, task 5.3) — a
   full tombstone-inclusive snapshot, restorable via `StatsExportService.importFromJson`.
3. **MariaDB dump/restore** — only for server-derived state (FSRS) that neither of the above holds.

## 1. Provision the host (Hetzner + Docker Compose)

1. Hetzner Cloud CX22+ (2 vCPU / 4 GB is the documented Appwrite floor; size up for headroom),
   Ubuntu LTS. Attach a volume for `/var/lib/docker` so DB + storage survive a rebuild.
2. Install Docker Engine + Compose plugin.
3. Install Appwrite (one-command installer writes `docker-compose.yml` + `.env`):
   ```bash
   docker run -it --rm \
     --volume /var/run/docker.sock:/var/run/docker.sock \
     --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
     --entrypoint="install" \
     appwrite/appwrite:<pin-the-same-major-as-cloud>
   ```
   **Pin the image tag** to the same Appwrite major the cloud project runs — a version skew can
   change attribute/index semantics and break the config push in §3.
4. Front it with TLS (the installer provisions Traefik + Let's Encrypt; supply the domain and an
   `_APP_DOMAIN` / `_APP_DOMAIN_TARGET`). TLS everywhere is non-negotiable (security posture).
5. Harden `.env`: strong `_APP_OPENSSL_KEY_V1`, locked SMTP, `_APP_CONSOLE_WHITELIST_*` set to the
   owner. At-rest encryption stays on (accepted as-is; no E2EE — server-readable plaintext is
   required for server-derived FSRS and web-studio rendering).

## 2. Point clients at the new endpoint (`.env` swap)

Clients read two values (`lib/core/config/appwrite_env.dart`): `APPWRITE_ENDPOINT`,
`APPWRITE_PROJECT_ID`; server tooling additionally uses `APPWRITE_KEY` (in `.env.local`, never
committed). Swap procedure:

1. Create the project on the self-hosted console; note its **new** project id.
2. Register platforms/origins: iOS bundle id, Android package, **and the web origin** (required for
   CORS before any live web session / remote-config fetch — same lesson as
   `kRemoteConfigLiveEnabled`).
3. Configure the **Google OAuth** provider (client id/secret + the success/failure redirect URLs;
   web uses `Uri.base.origin`).
4. Update `--dart-define`s / `.env.local`: `APPWRITE_ENDPOINT=https://<your-domain>/v1`,
   `APPWRITE_PROJECT_ID=<new-id>`, fresh server `APPWRITE_KEY`.
5. Rebuild + reinstall clients. Old cloud endpoint stays live until §5 verification passes
   (roll-back safety).

## 3. Re-provision schema + Functions

### Never `push tables --all`

`appwrite push tables --all` (CLI 22.6.1) diffs omitted-`array` config against deployed
`array:false` as a change and **recreates existing columns** — it has nuked live tables and left
dangling indexes that only a table drop+recreate could clear. On a **fresh empty** self-host this is
survivable (0 rows), but make it muscle memory to provision with **targeted** calls instead:

1. Push the collection/table shapes from `appwrite.config.json` using targeted
   `tables-db create-*-column` / `create-index` calls, table by table. Auth the CLI via
   `set -a; source .env.local` and export `APPWRITE_ENDPOINT`/`APPWRITE_PROJECT_ID`/`APPWRITE_KEY`
   (do **not** trust the CLI prefs `current` — it points at throwaway projects).
2. Verify all tables + indexes green before any data step.
3. Deploy the three Functions and **activate** each:
   `functions/reviews-append`, `functions/sync-pull`, `functions/sync-push`
   (`appwrite push functions --activate`). Re-create their env vars + scopes; confirm the
   `x-appwrite-user-id` trust + read-only scope posture from the master spec.

## 4. Migrate data

For each entity, prefer re-backfill; fall back to dump/restore only for FSRS.

- **Re-backfill (moves, combos, combo_moves, decks, deck_moves, reviews, note entries, tombstones):**
  run `SyncBackfillService` against the new endpoint from the owner's device — the device holds all
  of it, LWW-idempotent, so a re-run is safe. Tombstones ride along (schema carries `deletedAt`).
- **Server-derived FSRS:** dump from cloud MariaDB and restore into the self-host DB **before**
  first client pull, or let the scheduling Function recompute from the append-only `reviewEvents`
  (which *are* re-backfilled) — recompute is the cleaner path and avoids a cross-host dump.
  ```bash
  # only if recompute is not acceptable:
  mariadb-dump --single-transaction -h <cloud-db-host> -u <user> -p <appwrite-db> \
    <fsrs_table(s)> > fsrs.sql
  mariadb -h 127.0.0.1 -u user -p appwrite < fsrs.sql   # into the self-host container's DB
  ```

## 5. Backup schedule (self-host)

Two independent sinks — never bet durability on one:

1. **Nightly `mariadb-dump`** of the Appwrite DB → **offsite** (e.g. a second provider's object
   store or Hetzner Storage Box), 7-day rolling + weekly retained. Cron:
   ```
   0 3 * * *  docker exec <mariadb-container> mariadb-dump --single-transaction -u user -p<...> appwrite | gzip > /backups/appwrite-$(date +\%F).sql.gz && rclone copy /backups <offsite>:appwrite
   ```
2. **Client-side JSON export** (task 5.3) continues to write `Breakdex/backups/` on each user's
   Drive — endpoint-independent, and it is what makes even a total server loss non-catastrophic.

## 6. Restore drill (run quarterly; binary truth)

1. Stand up a scratch self-host from the pinned image.
2. `mariadb < latest-dump.sql`; bring Appwrite up.
3. Point a **debug** build at it; confirm login, a pull returns the seeded data, FSRS due-dates match
   the device scheduler for a sample move + combo.
4. Independently: import the latest `Breakdex/backups/*.json` into an empty debug DB via
   `StatsExportService.importFromJson` and confirm counts + a known tombstone (deleted move stays
   deleted, not resurrected).
5. Tear down. Record the drill date + result.

## 7. Cutover verification (before retiring cloud)

- All tables/indexes/Functions green on self-host; OAuth login works on iOS, Android, web.
- Re-backfill parity: device edit → self-host pull sees it; self-host edit → device pull sees it
  (the two-surface soak, matching Phase M's M.4).
- FSRS server-derived state matches the local scheduler for a sample set.
- One full restore drill (§6) passed on this host.
- Only then swap the endpoint of record and decommission the cloud project.

# Archive note — 2026-08-10 — reverse-album-delete-archive

**Verdict: STALE — implementation exists in code, spec task list is fiction.** Not
abandoned: the work is largely *already shipped*, but the spec's task breakdown and
commit references do not match reality, so building from the spec would be re-work.

## Why it is archived

Verified 2026-08-10 against the live codebase (`lib/`):

- **Phase 1 commit references are fiction.** The spec claims Phase 1 landed in commits
  `5707fe1`/`b28cfa1`/`d382437`. Those commits are about video storage constraints,
  tombstones, and a layout fix — nothing to do with archive columns. The columns
  (`archived_at`/`archive_reason`) *do* exist in the DB now, landed some other way.
- **Phase 2 (reconciliation) already exists.** `ManagedAlbumReconciliationService`
  (`lib/core/services/managed_album_reconciliation_service.dart`) ships with
  `startup`/`resume`/`libraryChanged` triggers — the spec lists this as not-done.
- **Phase 3 (recovery) already exists.** `recently_deleted_screen.dart` is wired into
  `app_router.dart` + `settings_screen.dart` — the spec lists this as not-done.

A spec whose ticks contradict shipped code is exactly the drift the ledger rule exists
to prevent. Rather than repair a spec whose implementation already exists independently,
it is archived; the code is the source of truth.

## Where the work survives

- `lib/core/database/database.g.dart` — `archived_at`/`archive_reason` columns
- `lib/core/services/sync_service.dart` — archive fields sync through move metadata
- `lib/core/services/managed_album_reconciliation_service.dart` — reconciliation service
- `lib/features/settings/recently_deleted_screen.dart` — recovery UI
- `lib/core/models/move_archive_reason.dart` — archive reason enum

## Honest NOT PROVEN

This archive note asserts *existence* of the files above (grep-verified), not that they
are complete, correct, or tested. Re-opening this work means re-deriving the spec from
the code that already exists, not resuming the fiction task list.

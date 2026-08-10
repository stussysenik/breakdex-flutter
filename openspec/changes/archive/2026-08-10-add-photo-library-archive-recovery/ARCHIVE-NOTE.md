# Archive note — 2026-08-10 — add-photo-library-archive-recovery

**Verdict: DUPLICATE.** Not abandoned — it is the same feature as
`reverse-album-delete-archive`, and repairing both would spec one feature twice.

## Why it is archived

The two changes share identical Phase 1 work (commit hashes `5707fe1`, `b28cfa1`,
`d382437` appear in both task lists) and near-identical scope: external Photos deletion
→ archive the move (not hard-delete) → Recently Deleted UI → iCloud-backed restoration.
They are the same idea written twice. The supersession rule ("retire the contradicted
half, keep the surviving half") applies: the surviving half is
`reverse-album-delete-archive`, which is more complete (30-day purge path, 5 phases).

## Where the work survives

`reverse-album-delete-archive` absorbs this change's scope, plus the explicit
iCloud-restoration language this draft stated well ("restore the video from the Photos
asset, including iCloud-backed assets"). That change is repaired to the current template
in the same session.

## Supabase staleness (carried by the survivor too)

Both drafts reference **Supabase** ("Supabase schema/payload", "Supabase migrations").
The canonical backend is now **Appwrite** (locked ruling). The repair of the survivor
replaces every Supabase reference with Appwrite/Drift — this draft's Supabase language is
NOT carried over.

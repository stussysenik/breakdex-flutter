# Tasks — humanize-video-surfaces-and-gate-release

> **Phase dependencies:** Phase 2 starts immediately. Phase 1 lands after
> `fix-video-backup-truth-and-unify-account` 4.7 (sandbox rescue — design D1
> sequencing). Phase 3 ticks last; 3.2 additionally needs that change's Phase 3
> (one-account auth) so user #2 walks the released flow.
> Ledger rule: tick in the same commit as the work, with terminal evidence.

## Phase 1 — Picker collapse (after backup-change 4.7)

- [ ] 1.1 Manifest-backed library list: pure `buildBreakdexVideoItems()` joining live
  manifest rows to owning moves/combos — title (owner name, else basename stripped of
  the ` - hash8`/full-hash suffix), effectiveDate, resolver-backed path. Red: fixture
  with owned + ownerless + tombstoned rows — tombstoned excluded, no raw hash/UUID in
  any title, newest-first by effectiveDate. Verify: unit tests green, analyze clean.
- [ ] 1.2 Tab collapse: SELECT VIDEO renders exactly two tabs — **In Breakdex**
  (default, 1.1-backed) and **Import** (existing PhotoKit grid, videos-only) — with
  `VideoPickResult` contracts unchanged for both consumers. The VIDEO LIBRARY tab is
  removed; confirm `discoverRecoverableManagedAssets` keeps a reachable entry point in
  the recovery/settings surface (add one there if the picker was the only route —
  design D3). Verify: widget tests (pure-override harness) for both tabs + default-tab
  assertion, analyze clean.
- [ ] 1.3 Honest durations (design D2): lazy per-tile probe via the existing controller
  seam, in-memory cache; unprobed/unprobeable shows no badge. Delete the `duration: 1`
  hack. Red: tile with probe-failure renders no badge (today: fabricated `0:01`).
  Verify: unit test for cache + widget test, analyze clean.
- [ ] 1.4 On-device proof (owner, 30s): open picker → In Breakdex is default, newest
  clip on top with real title + date, durations real or absent (no `0:01` wall);
  Import shows camera roll videos; pick from each tab lands in a move. Evidence:
  screenshot pair in the tick.

## Phase 2 — Subtitle legibility (independent, start now)

- [ ] 2.1 Row subtitles show the date, not `originalVideoName`: category-screen move
  rows + any list row still subtitling a filename/UUID (sweep with grep for
  `originalVideoName` render sites). Label follows the effectiveDate source ("Added …" /
  "Filmed …") so the sorted date and shown date agree. Red: row widget test asserting a
  UUID-named fixture renders a date subtitle and never the UUID. Verify: widget tests
  green, analyze clean, l10n check green.
- [ ] 2.2 Detail-screen provenance: `originalVideoName` (and file size, already
  specced there) visible on move detail — confirm present or add the line. Verify:
  widget test, analyze clean.
- [ ] 2.3 Codify the review rule (design D4): add "no content hash, UUID, or raw
  filename as primary/secondary text on library surfaces" to the review checklist in
  `openspec/AGENTS.md` conventions (alongside the tokens-conformance item). Evidence:
  the diff.

## Phase 3 — Multi-user release gate

- [ ] 3.1 Write `docs/release/sync-release-gate.md`: the four gates with their proving
  change/task ids — (a) asset truth: backup change 4.7 + 4.8 + 4.6 device proof;
  (b) totality: `make-sync-total-and-registry-driven` complete; (c) Phase M: M.4 soak +
  M.5 config flip ticked in the Appwrite master change; (d) fresh-second-user proof
  (3.2). Doc only. Verify: file exists, gates link to real task ids.
- [ ] 3.2 [OWNER+AGENT] Fresh-second-user end-to-end proof (needs backup-change Phase 3
  one-account flow): a non-owner Google account signs in on a device or web build →
  Appwrite user created, Drive folder provisioned on *that* account's quota → import
  one video → it uploads to their Drive and appears on their own web login after
  hydrate. Agent verifies isolation server-side with existing `.env.local` API access:
  user #2's documents carry only their `userId`, zero rows cross into user #1's space,
  owner's counts unchanged. Evidence: server queries + screenshots in the tick.
- [ ] 3.3 [OWNER] Declare sync released: all four gates ticked with evidence → mark the
  general Google-Drive-sync effort done in `ROADMAP.md` (NOW block + backlog) and
  record the declaration date in the gate doc. Evidence: the diff linking all four.

# Tasks — make-sync-total-and-registry-driven

> **Sequencing gate.** This change starts only **after** the live Phase-M pass
> (`migrate-canonical-backend-to-appwrite`) has proven the 9 wired entities on real data
> (owner ruling 2026-07-14, prove-then-generalize). Ledger rule: tick each box in the same
> commit that lands the work, with terminal-verified evidence (analyze/test output). Every
> new-entity slice (S7+) must leave `flutter test` green and the totality test greener than
> before — never redder.

## S1 — Coverage audit (data, no code)

- [ ] 1.1 Enumerate all Drift tables from `lib/core/database/database.dart` and classify
  each: `synced | localOnly(reason) | mustSync`. Ratify the draft table in `design.md` §D6;
  resolve `ProvenanceEvents` explicitly (sync vs reasoned-local) **and ratify the
  `AssetManifest`/`AssetCopies` field-split reclassification filed 2026-07-17 by
  `fix-video-backup-truth-and-unify-account` 1.6 (§D6 note)**. Record as
  `docs/sync-coverage.md` — the human-readable ledger the totality test enforces.

## S2 — Totality test (the keystone; expected RED)

- [ ] 2.1 Add `kLocalOnlyTables` (Set of table ids, each with a `// reason:` comment) beside
  the registry. Add `test/core/sync/sync_totality_test.dart`: enumerate the generated Drift
  table metadata; assert every table id is in the registry OR in `kLocalOnlyTables`. Verify:
  test runs, is **red** with exactly the `mustSync` tables from S1 unlisted (documented count).
  `flutter analyze` clean.

## S3 — Registry descriptor + generic dual-write

- [ ] 3.1 New `lib/core/sync/sync_registry.dart`: `SyncEntity` descriptor (D1) with derived
  pref keys, `pushable`, and `parentType` for pairs (D3); `registry` list seeded with the 9
  existing entities pointing at their existing codecs. Verify: `flutter analyze` clean.
- [ ] 3.2 Refactor `SyncService` dual-write to iterate `registry.where((e) => e.pushable)`
  instead of the hand-written `dualWriteMoves`/`dualWriteCombos`/… dispatch. Delete the
  per-entity methods. **Behaviour-preserving.** Verify: the dual-write parity + byte-identical
  backfill suites green unchanged; `flutter analyze` clean.

## S4 — Generic dual-read / pull

- [ ] 4.1 Refactor dual-read/pull + cursor handling to iterate the registry (per-entity cursor
  from `e.cursorPrefKey`). Delete the per-entity read branches. Verify: dual-read suite
  (`sync_service_dual_read_test`) green unchanged; `flutter analyze` clean.

## S5 — Generic backfill

- [ ] 5.1 Refactor `sync_backfill_service` to drive the registry (encode via `e.encode`).
  Verify: every `*_backfill_appwrite_test` green unchanged (byte-identical proofs hold);
  `flutter analyze` clean.

## S6 — Registry migration complete (9 entities)

- [ ] 6.1 Confirm no hand-wired per-entity sync path remains for the original 9 (grep for
  `entityTable ==` string dispatch and per-entity pref-key constants that duplicate the
  derived keys; remove dead code). Totality test: original 9 all green. Verify: full
  `flutter test` green with **0 regressions** vs the pre-change baseline; `flutter analyze` clean.

## S7+ — Wire the missing user-data tables (one slice each)

> Each slice: codec (`lib/core/sync/codecs/`) → `SyncEntityType` value → registry descriptor →
> provision backend table (targeted `create-*`, **never** `push tables --all`) → extend
> `functions/sync-push/lib/reconcile.dart` + `functions/sync-pull/lib/pull.dart` allow-lists →
> byte-identical backfill parity test → totality test greener. Tick when its row goes green.

- [ ] 7.1 `Sets` + `SetItems` (pair) — the third core atom, first.
- [ ] 7.2 `ComboPlans`.
- [ ] 7.3 `Labs` + `Milestones` + `LabMoves` + `LabEntries` (lab cluster).
- [ ] 7.4 `AuraLinks` + `AuraPresets` (pair).
- [ ] 7.5 `Achievements`.
- [ ] 7.6 `BattleResults`.
- [ ] 7.7 `ProvenanceEvents` — wire **or** move to `kLocalOnlyTables` with reason, per S1.

## S8 — Close the gate

- [ ] 8.1 Totality test **fully green**: every Drift table is registered or reasoned-local.
  `docs/sync-coverage.md` matches. Full `flutter test` green, `flutter analyze` clean,
  `flutter build web` green. Advance ROADMAP `## NOW` in the same commit; note the new
  by-construction guarantee (a future table can't merge unclassified).

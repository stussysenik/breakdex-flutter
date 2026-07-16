# Design — make-sync-total-and-registry-driven

## D1. The registry descriptor (the universal seam)

One immutable value per synced entity. Everything the sync machinery does per entity is
read from this descriptor instead of hand-written:

```dart
class SyncEntity<Row> {
  final SyncEntityType type;         // closed sum-type tag
  final String table;                // Drift/backend table id
  final SyncRecord Function(Row) encode;   // codec half (exists today)
  final Row Function(Map<String, dynamic>) decode; // codec half (exists today)
  final bool pushable;               // fsrsCard is pull-only (false)
  // pref keys are DERIVED, never hand-typed:
  String get dualWritePrefKey => 'sync.$name.dualWrite.enabled';
  String get dualReadPrefKey  => 'sync.$name.dualRead.enabled';
  String get cursorPrefKey    => 'sync.$name.backend.cursor';
}
```

`registry` is a `List<SyncEntity>`. Dual-write, dual-read/pull, and backfill each collapse
to a `for (final e in registry.where((e) => e.pushable)) { … }` loop. The per-entity
`dualWriteMoves`/`dualWriteCombos`/… methods and the string-matched dispatch delete.

**Why this is right-sized, not speculative:** the codecs, the generic `SyncRecord`
envelope, and the `SyncBackend` interface already exist and are already uniform. The
descriptor only *names* the wiring that is currently copy-pasted 9 times. The diff is net
negative on the dispatch path.

## D2. The totality guarantee (making un-synced unrepresentable)

Two directions of exhaustiveness:

1. **Enum → handling** is already total: `SyncBackend` switches on `SyncEntityType` with
   no `default`, so a new enum value is a compile error until handled. Keep this.
2. **Drift table → sync decision** is the *unguarded* direction and the source of the
   12-table gap. The keystone test enumerates the generated Drift table metadata and
   asserts every table id is either (a) present in `registry`, or (b) in an explicit
   `kLocalOnlyTables` set that pairs each id with a written reason. Anything else fails.

```
for table in db.allTables:
   assert table.id in registry.tables  OR  table.id in kLocalOnlyTables  (with reason)
```

This is the Haskell move applied to a place Dart can't type-check: a new feature that adds
a Drift table **cannot merge green** until the author registers it or reasons it local.
The test lands first (S2) and is *expected red* until the last entity is wired — its red
count is the live coverage ledger.

## D3. Pairs and pull-only entities

Some entities travel as **pairs** sharing one write/read switch but independent cursors
(`combos`+`comboMoves`, `decks`+`deckMoves`, the two note tables). The descriptor models
this as a `parentType` link, not a special case in the loop: the pair shares the parent's
pref keys and each member keeps its own `cursorPrefKey`. `fsrsCard` is `pushable: false`
(server-derived, pull-only) — a descriptor flag, not a branch in the dispatch.

## D4. Backend provisioning stays additive and targeted

Every new entity's backend table is created with the targeted `create-table` /
`create-*-column` / `create-index` calls (mirroring the note-table block in
`docs/phase-m-runbook.md`), **never** `appwrite push tables --all` (the CLI diff bug that
recreated `moves`'s columns in 1R.1). New tables that carry typed columns replicate their
Drift shape; entities that are genuinely opaque may use the generic
`{id,userId,updatedAt,clientOpId,payload}` envelope shape (as the note tables do).

## D5. Sequencing — prove, then generalise

Owner ruling 2026-07-14. The live Phase-M pass on the 9 wired entities runs **first**; this
change runs **after** it, so the registry refactor lands on sync code that has already
moved real data once. Rationale: never refactor a load-bearing, data-critical path before
it has been proven on real data. Throughout, the un-synced tables stay local-only — safe,
never lost — so shipping core sync first strands nothing.

## D6. Per-entity classification (drafted; ratified in S1)

| Table(s) | Decision | Reason |
| --- | --- | --- |
| `Sets`, `SetItems` | **mustSync** | third core atom (move→combo→set) |
| `ComboPlans` | **mustSync** | pre-planned beats — the composition moat |
| `Labs`, `Milestones`, `LabMoves`, `LabEntries` | **mustSync** | authored practice structures |
| `AuraLinks`, `AuraPresets` | **mustSync** | user personalization |
| `Achievements` | **mustSync** | earned state; loss = regression |
| `BattleResults` | **mustSync** | user history |
| `ProvenanceEvents` | **classify in S1** | audit trail — may be reasoned-local (regenerable) |
| `SyncLog`, `SyncOperations`, `SyncProviders`, `AssetManifest`, `AssetCopies` | **localOnly** | device bookkeeping / local asset state |

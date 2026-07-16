# make-sync-total-and-registry-driven

## Why

Sync today is **hand-wired per entity**. `SyncEntityType` has exactly 9 values
(`move, combo, comboMove, reviewEvent, fsrsCard, deck, deckMove, moveNoteEntry,
comboNoteEntry`) and each one carries its own SharedPreferences pref keys
(`SyncService.movesDualWritePrefKey` …), its own `dualWriteMoves`/`dualWriteCombos`
method, its own backend cursor, and its own hand-written line in a string-matched
dispatch (`pending.where((e) => e.entityTable == 'moves')`). Adding an entity means a
human must remember to hand-wire all of that **and** provision a backend table **and**
extend the two Function allow-lists. Nothing fails if they forget.

They have forgotten. The database registers **26 Drift tables**; only **9** sync. Five
more are correctly local (`SyncLog`, `SyncOperations`, `SyncProviders`, `AssetManifest`,
`AssetCopies` — device bookkeeping). That leaves **12 user-data tables silently
un-synced**: `Sets`, `SetItems` (the third core product atom, move→combo→**set**),
`ComboPlans` (the pre-planned-beats moat), `Labs`, `Milestones`, `LabMoves`, `LabEntries`,
`Achievements`, `AuraLinks`, `AuraPresets`, `BattleResults`, and `ProvenanceEvents`. The
product grew past the sync layer. This is not data **loss** — Drift stays canonical, so
nothing is gone — but those tables never replicate to web or a second device.

The model is already the right shape for a universal fix: `SyncRecord` / `SyncTombstone`
/ `SyncDelta` are a **generic, provider-neutral envelope** (DOP — data is plain `json`),
every entity is a uniform **codec** (`encode`/`decode` pair), and `SyncBackend` is one
abstract interface. Only the **dispatch + registration** is hand-wired. Turn the 9
hand-wirings into **one registry the machinery iterates**, and add a **totality test**
that makes an un-synced table a red test in CI rather than a production surprise, and
"the product grows and sync picks it up" becomes true by construction.

Sequencing (owner-ruled 2026-07-14): **prove-then-generalize.** The live Phase-M pass on
the 9 wired entities lands first (real data → web, the concrete proof of totality on one
instance). This change executes immediately after, refactoring a system that has by then
run once on real data — never before.

## What Changes

- **`SyncEntity` registry.** One immutable descriptor per synced entity — its
  `SyncEntityType`, Drift table, codec (`encode`/`decode`), derived pref keys
  (dual-write / dual-read / cursor), and local read/apply adapters. Dual-write,
  dual-read/pull, and backfill become a `for entity in registry` loop over descriptors.
  Adding an entity = add one descriptor + one codec. **Behaviour-preserving** for the 9
  existing entities — the parity and byte-identical-backfill suites are the guardrail.
- **Totality test (the keystone).** A test that enumerates every Drift table and fails
  unless the table is registered in the sync registry **or** on an explicit `localOnly`
  allow-list with a written reason. Lands **before** any wiring; goes red immediately
  (proving the 12-table gap); each added entity turns part of it green. A future feature
  that adds a Drift table cannot merge until it is registered or reasoned-local.
- **Wire the 12 missing user-data tables, one slice each** — `Sets`/`SetItems` first
  (core atom), then `ComboPlans`, then `Labs`+`Milestones`+`LabMoves`+`LabEntries`,
  `AuraLinks`+`AuraPresets`, `Achievements`, `BattleResults`. `ProvenanceEvents` is
  classified in S1 (sync vs reasoned-local). Each slice: codec → descriptor → provision
  backend table (targeted `create-*`, **never** `push tables --all`) → extend both
  Function allow-lists → byte-identical backfill parity test → totality test greener.

## Capabilities

- `sync-registry` — a registry-driven, generic dual-write / dual-read / backfill engine
  keyed on a `SyncEntity` descriptor list, replacing the per-entity hand-wiring.
- `sync-totality` — a CI-enforced guarantee that every Drift table is either a registered
  sync entity or an explicitly reasoned local-only table.

## Footprint estimate

| Surface | Current | Target (delta) |
| --- | --- | --- |
| `lib/core/sync/sync_backend.dart` (`SyncEntityType`) | 9 values | +up to 12 values as entities land |
| `lib/core/sync/sync_registry.dart` (new) | — | ~120 LOC (descriptor + registry list) |
| `lib/core/services/sync_service.dart` (dispatch) | per-entity `dualWriteX` methods | net **negative** — hand-wiring folds into the loop |
| `lib/core/sync/codecs/` | 6 codecs | +~7 codecs (one per new entity/pair) |
| `test/core/sync/sync_totality_test.dart` (new) | — | ~60 LOC (the keystone gate) |
| backend tables | 12 live | + targeted `create-*` per new entity (additive) |
| Function allow-lists (`sync-push`, `sync-pull`) | 7 tables | + each new table |

## Non-goals

- **No change to the generic envelope or LWW model.** `SyncRecord`/`SyncDelta`,
  record-level LWW + tombstones, and the dirty-guard are unchanged; this is registration
  and dispatch, not reconciliation semantics.
- **No opaque-blob rewrite of the typed entities.** Server-derived FSRS and web-studio
  rendering need server-readable fields (CLAUDE.md non-goal), so typed codecs stay typed;
  universality comes from the registry, not from erasing schema.
- **No new sync backend or provider.** Appwrite stays canonical; Drift stays the local
  source of truth.

# Domain Restructure Design

Split from `openspec/changes/archive/2026-07-27-engineer-workflow-and-multi-user-foundation/`;
see its Decision 3 for the parent ruling (additive first, then deprecating).

## The map

[`domain-source-map.md`](./domain-source-map.md) is the load-bearing artifact for this
change (task 3.1). It records every current path, its target domain, the four high-fan-in
files excluded from the mechanical batches, and the batch order for 3.2–3.4. Read it
before touching any file.

## Decisions taken here

The umbrella left three folder names open. This change resolves them:

- **`sets`, not `labs`** — the locked atom model is move → combo → set; `lab` is a UI
  surface name. Drift table names (`labs`, `lab_moves`, `lab_entries`) do **not** change:
  renaming tables would be a destructive migration for zero product value.
- **`media` and `backup` are separate domains** — `media` owns bytes, playback, and
  editing; `backup` owns durability (canonical paths, manifest, cloud fan-out, orphan
  restore, janitor, provenance). Today both live under `core/sync`. Folding them would
  hide the durability seam the data-safety posture depends on.
- **`kernel` holds pure primitives and platform seams only** — `Machine<S,E>`, `Failure`,
  clock/utils, the conditional-import `io.dart`/`native_*` seams, remote config,
  entitlement. If a file knows what a "move" is, it is not kernel. `ui` stays separate
  from `kernel` so `kernel` remains widget-free.

The resulting domain list is ten, not the umbrella's eight: `drill` and `progress` were
implicit inside "sets/labs" and are large enough to name.

## Prerequisite the umbrella did not name

`lib/` uses 1678 relative intra-project imports against 4 `package:breakdex/…` ones. Moving
folders under that scheme rewrites import edges in both directions and cannot be verified
by grep. So the first slice of 3.2 is **import normalization** — enable
`always_use_package_imports`, `dart fix --apply`, prove analyzer + full suite green. Large
in LOC, zero in behavior, and it makes every later batch a single path find-replace.
Recommended as a new task `3.2.0`; flagged for the owner rather than added unilaterally.

## Constraints on every batch

- Files moved and imports updated only. **Zero behavior edits** in a move commit.
- `./verify.sh` green in the same commit; `tasks.md` ticked in the same commit.
- `core/providers.dart` (673 LOC, fan-in 113) is drained by colocation, kept as a
  compatibility re-export (3.3), and deleted only when `rg` proves fan-in is 0 (3.5).
- `core/database/database.dart` (fan-in 120) stays one `AppDatabase`. Only DAOs move, and
  only after their domain has landed — splitting it would split Drift codegen.
- `main.dart` (606 LOC) is rewired once at the end, never per batch.

## Rollback

Each batch is an ordinary commit containing only file moves; `git revert` is sufficient
as long as no later batch has built on it. That is why the batches run fan-in ascending.

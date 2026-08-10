# Archive note — 2026-08-10 — add-self-healing-video-reliability-runtime

**Verdict: STALE — runtime fully implemented, spec task framing diverges from the
implementation.** Not abandoned: the runtime is shipped and wired, but the spec's task
breakdown (esp. the split between task 1.1 "define states" and task 4.1 "implement state
machine") does not map to what was built.

## Why it is archived

Verified 2026-08-10 against the live codebase (`lib/`):

- **`VideoReliabilityRuntime` exists** (`lib/core/sync/video_reliability_runtime.dart`)
  with a `VideoReliabilityDisposition` enum: `availableLocally`, `restoredLocally`,
  `waitingForConnection`, `waitingForWifi`, `waitingForBudget`, `failed`. This is more
  nuanced than the spec's task 1.1 claimed (`local/Photos/cloud/blocked/failed`).
- **It is wired into production.** `sync_providers.dart` (provider), `main.dart`
  (startup sweep gating), `move_list_screen.dart` (`_StartupVideoReliabilityBanner`).
- **Spec task 4.1 ("implement state machine") is ticked done** — accurate, it exists.
- **But spec task 1.1 ("define explicit reliability states") is ticked *not done*** —
  yet `VideoReliabilityDisposition` *is* that realization, just with different naming.
  The work exists; the spec's task breakdown does not map to it.

The implementation predates and diverges from the spec's task framing. Repairing the
spec to match code is possible, but the runtime already works — the spec is the stale
artifact, not the code.

## Where the work survives

- `lib/core/sync/video_reliability_runtime.dart` — the runtime + disposition enum
- `lib/core/providers/sync_providers.dart` — `videoReliabilityRuntimeProvider`
- `lib/main.dart` — startup sweep integration
- `lib/features/move_list/move_list_screen.dart` — `_StartupVideoReliabilityBanner`

## Honest NOT PROVEN

This archive asserts the runtime *exists and is wired*, not that it is complete, correct,
or fully tested. Re-opening means re-deriving scope from the implemented runtime, not
resuming the diverged task list.

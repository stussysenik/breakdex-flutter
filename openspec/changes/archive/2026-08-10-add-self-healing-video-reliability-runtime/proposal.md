# Add Self-Healing Video Reliability Runtime

> **Language: Dart (Flutter) + native iOS (PhotoKit).** Depends on: `appwrite`
> (cloud retrieval), `reverse-album-delete-archive` (managed Photos recovery).
> Implementation in a fresh student session — never this one.

## Why

Breakdex has historical Photos recovery, DB backup/restore, cloud video retrieval, and
provenance journaling — but these flows are activated by isolated triggers. There is no
unified reliability runtime that decides *what to verify first*, *what to retry
automatically*, *what to surface as a real problem*, and *what to defer*. Video
reliability is currently best-effort and opaque; it should feel reliable and
explainable.

An explicit reliability subsystem is the lever that turns those isolated fixes into a
coherent product behavior:

1. **Explicit states over ambiguous missing.** The runtime distinguishes at least:
   available locally, recoverable from Photos, recoverable from cloud, blocked by
   policy/connectivity, failed after bounded retries. Without these, the app cannot
   answer whether a missing video is truly gone, merely not local, waiting on
   permission/network, or recoverable automatically.
2. **Deterministic sweep order.** Prioritize moves currently visible or recently opened,
   then assets with recent failures, then assets referenced by upcoming review surfaces,
   then broader background candidates.
3. **Bounded, explainable retries.** Retries are capped by attempt count, time window,
   and connectivity/policy conditions; provenance records *why* recovery stopped so the
   state is explainable, not a silent give-up.

This change is **local-first by construction** (loss function #1 portability): it runs
the same sweep/retry logic on every surface without depending on a server-driven policy
layer. Server-side correlation of cross-install failure patterns is deferred — it is not
a prerequisite for the runtime to ship.

## What Changes

- **Reliability state model.** Explicit states (local / Photos-recoverable /
  cloud-recoverable / blocked / failed) owned by a single runtime, not scattered across
  ad-hoc checks.
- **Sweep policy.** Deterministic priority order + trigger points (startup after first
  frame, resume, connectivity improvement, explicit user repair request).
- **Recovery action loop.** Local-first recovery ordering (local → managed Photos →
  cloud), bounded retry budgets, automatic-vs-user-initiated distinction.
- **Provenance feedback.** Provenance events influence future retry confidence and
  diagnostics severity; successful recoveries suppress false-alarm noise.

## Capabilities

1. `reliability-sweep-policy` — deterministic verification order for assets and moves.
2. `self-healing-action-loop` — automatic retries and recovery attempts with bounded
   budgets.
3. `explainable-video-state` — clear distinction between missing, recoverable, blocked,
   and failed states.

## Footprint estimate

| Surface | Current → Target | Notes |
| --- | --- | --- |
| `lib/core/services/` | +reliability runtime, ~150 LOC | states + sweep + retry loop |
| `lib/features/move_detail/` | +explainable state surfaces, ~80 LOC | blocked/failed explanations |
| `lib/core/services/provenance/` | +feedback wiring, ~60 LOC | retry confidence + severity |
| `test/` | +sweep/retry/recovery tests, ~140 LOC | priority, budgets, provenance feedback |

Net: ~430 LOC, +3–4 files.

## Non-goals

- **No guaranteed OS background execution** — sweeps run at defined trigger points
  (startup/resume/connectivity/user-request), not as a persistent background task.
- **No server-driven policy layer** — cross-install failure correlation and server-driven
  repair suggestions are deferred; the runtime is local-first and fully functional
  without them.
- **No BEAM/Phoenix backend.** The old draft referenced a future BEAM/Gleam role; that
  architecture is dead (superseded by Appwrite, locked ruling). The runtime ships
  against Appwrite + local-first recovery.
- **No immediate replacement of existing retrieval/recovery flows** — the runtime
  composes them behind a unified policy, slice by slice.

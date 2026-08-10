# Spec: Add Self-Healing Video Reliability Runtime

> **Language: Dart (Flutter) + native iOS (PhotoKit).** Depends on: `appwrite`
> (cloud retrieval), `reverse-album-delete-archive` (managed Photos recovery).
> Implementation in a fresh student session — never this one.

This spec defines the unified video reliability runtime: explicit availability states,
a deterministic sweep order, a bounded local-first recovery loop, and a provenance-to-
policy feedback loop. Where it is silent on sync/retrieval semantics, the
`migrate-canonical-backend-to-appwrite` and `reverse-album-delete-archive` specs are
normative.

Module layout (additive):
- `lib/core/services/` — reliability runtime (states + sweep + retry loop).
- `lib/features/move_detail/` — explainable state surfaces (blocked/failed).
- `lib/core/services/provenance/` — feedback wiring (retry confidence + severity).

## ADDED Requirements

### Requirement: Reliability-sweep-policy

The app SHALL verify video availability in a deterministic priority order: moves
currently visible or recently opened first, then assets with recent failures, then
assets referenced by upcoming review surfaces, then broader background candidates.
Sweeps SHALL run on startup (after first frame), app resume, connectivity improvement,
and explicit user repair/inspect request.

#### Scenario: Visible moves are verified first
- **WHEN** a sweep runs
- **THEN** moves currently visible or recently opened are verified before background
  candidates

#### Scenario: Sweep triggers are bounded
- **WHEN** none of the trigger points (startup/resume/connectivity/user-request) fire
- **THEN** the runtime does NOT run a sweep (no unbounded background execution)

### Requirement: Self-healing-action-loop

The app SHALL attempt recovery using the cheapest credible path first: local verified
file, then managed Photos asset, then cloud retrieval. Retries SHALL be bounded by
attempt count, time window, and connectivity/policy conditions. The runtime SHALL
distinguish automatic recovery from user-initiated recovery.

#### Scenario: Local-first ordering
- **WHEN** a video is missing and both a managed Photos copy and a cloud replica exist
- **THEN** the runtime attempts the managed Photos path before the cloud path

#### Scenario: Bounded retries
- **WHEN** a recovery path has failed repeatedly
- **THEN** the runtime stops retrying once its budget (attempt count / time window /
  conditions) is exhausted and marks the asset failed explicitly

#### Scenario: Automatic vs user-initiated
- **WHEN** a recoverable condition is detected passively (e.g. on sweep)
- **THEN** automatic recovery is attempted within its budget; recovery that exceeds the
  budget or requires user consent is surfaced as a user-initiated action

### Requirement: Explainable-video-state

The app SHALL represent video availability with at least these explicit states:
available locally, recoverable from Photos, recoverable from cloud, blocked by
policy/connectivity, failed after bounded retries. Blocked and failed states SHALL be
visible to the user/developer with an explanation of *why*.

#### Scenario: Blocked state is explained
- **WHEN** a video is blocked (e.g. awaiting connectivity or photo-library permission)
- **THEN** the UI surfaces the blocked state with the blocking reason, not a generic
  "missing" indicator

#### Scenario: Failed state records why retries stopped
- **WHEN** a video reaches the failed state
- **THEN** the provenance log records the exhaustion cause (attempt count, time window,
  or policy condition) so the failure is explainable

#### Scenario: Successful recovery suppresses noise
- **WHEN** a previously-failing asset recovers successfully
- **THEN** the runtime suppresses the earlier false-alarm incident noise for that asset

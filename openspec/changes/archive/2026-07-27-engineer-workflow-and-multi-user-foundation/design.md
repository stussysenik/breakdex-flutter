## Context

Breakdex is a brownfield Flutter/Dart product with real local data, a Drift/SQLite
source of truth, Appwrite as the canonical cloud backend, Google Drive-backed video
bytes, and an in-repo Next.js studio. The current project already has:

- root `CLAUDE.md` for load-bearing agent rulings;
- root `ROADMAP.md` for active work and backlog ordering;
- `openspec/changes/` for implementation specs;
- `docs/manual/*.mdx` for technical reference;
- `status.sh` and `verify.sh` for binary gates;
- Flutter `Machine<S,E>` state machines in `lib/core/state_machines/`;
- Drift repositories and sync-aware decorators under `lib/core/data/`;
- Appwrite runbooks and deployment workflows.

The gap is operating discipline for long-running, multi-session delivery. The next
work is large enough that an undifferentiated "agent session" will lose provenance:
closing owner-gated sync truth, reorganizing source files, adding a persistent action
log, proving multi-user cloud sync, testing Android devices, and preparing release.

This design adapts the valoric factory model to Breakdex without replacing existing
OpenSpec/manual infrastructure.

## Goals / Non-Goals

**Goals:**

- Make future sessions recoverable from local files alone.
- Keep research, spec writing, and implementation in separate lanes.
- Reorganize Flutter code by product/domain seams without behavior changes.
- Add a persistent action/audit log for every mutation and relevant machine transition.
- Prove private per-user Appwrite sync across devices before distribution claims.
- Add Android/device test gates suitable for release confidence.
- Keep all work brownfield-safe: no destructive migrations, no orphaned media, no data loss.

**Non-Goals:**

- No shared/collaborative multi-user features such as crews, coaches, presence, or cross-user sharing.
- No CRDT replacement; record-level LWW plus tombstones remains the sync model.
- No E2EE; server-readable data remains required by Appwrite Functions and web tooling.
- No rewrite of Drift, Riverpod, Machine<S,E>, Appwrite, or the Next.js studio.
- No broad refactor during this pre-work. Implementation must happen in later Student sessions.

## Decisions

### Decision 1: FACTORY.md is the process manual; CLAUDE.md remains the law

`CLAUDE.md` already locks stack, non-goals, and session start expectations. Duplicating
that material in a second root-level law file would create drift. `docs/manual/FACTORY.md`
therefore explains process mechanics: roles, records, provenance trace, gates, and failure
modes.

Alternatives considered:

- **Put everything in CLAUDE.md:** simpler lookup, but turns the law file into a process
  handbook and increases edit risk.
- **Use only OpenSpec:** strong for implementation, weak for session discipline and
  long-term provenance outside a single change.

### Decision 2: Session lanes are mandatory: Scholar, Teacher, Student

Large work is split by output type. Scholar sessions write evidence. Teacher sessions
write one OpenSpec change. Student sessions implement one approved spec. This prevents
implementation bias from leaking into research and prevents implementation from inventing
requirements.

Alternatives considered:

- **Single blended agent role:** fastest in the short term, but leaves decisions trapped
  in conversation and makes later review weaker.
- **Issue-only workflow:** good for tracking tasks, insufficient for source-backed design
  and implementation proof.

### Decision 3: Domain restructure is additive first, then deprecating

The current source tree is `lib/core/*` plus `lib/features/*`. The target orientation is
domain-first (`moves`, `combos`, `sets`, `backup`, `sync`, `auth`, `kernel`, `ui`), but
the first implementation pass must be behavior-preserving. Move files only when imports
can be mechanically updated and tests/analyzer remain green. Where churn is high, leave
compatibility export stubs temporarily and remove them in a later explicit cleanup.

Alternatives considered:

- **One-shot hard move:** cleaner final tree, high review and regression risk.
- **No restructure:** avoids churn, but keeps the codebase harder to remember and harder
  for fresh agents to navigate.

### Decision 4: Action audit log is a sidecar over existing writes and machines

The app already has Drift as canonical local truth and Machine<S,E> for state transitions.
Add an append-only sidecar table and writer service that records mutation intent, entity
identity, actor/session context, before/after hashes or compact metadata, result, and error
state. Do not embed audit semantics into every table and do not make the audit table drive
business behavior.

Alternatives considered:

- **Only debug logs:** insufficient for support and post-failure replay; not persisted.
- **Event-sourcing rewrite:** too invasive for a brownfield release path.

### Decision 5: Multi-user means private per-user sync, not collaboration

Each signed-in user gets isolated Appwrite data and Google Drive video scope. Cross-device
sync is the goal; cross-user sharing is deliberately excluded. Appwrite remains a shadow
copy until each entity is verified from Drift and runbook proofs.

Alternatives considered:

- **Shared workspace model now:** materially expands authz, privacy, conflicts, UI, and
  support surface before the single-user product has shipped.
- **Local-only release:** simpler, but blocks cross-device retrieval and recovery goals.

### Decision 6: Device testing is a release gate, not a confidence sentence

Android release readiness requires scripted proofs: Flutter tests, Android smoke build,
Maestro/Patrol flows where available, and a device-farm run. Owner visual/device review
remains the final visual truth. Agents can run and report gates; they cannot self-certify
that a UI "looks right".

Alternatives considered:

- **Manual-only device checks:** useful, but not repeatable.
- **Unit tests only:** misses OAuth, filesystem, native video, Android lifecycle, and
  Appwrite session behavior.

## Risks / Trade-offs

- **Large source moves cause merge churn** → Use tiny batches, analyzer after each batch,
  compatibility exports for hot imports, and no behavior edits in move commits.
- **Audit log creates storage growth** → Store compact metadata, support retention/export
  policy, and keep video bytes out of audit rows.
- **Audit writer failure could block user actions** → Treat audit as best-effort only when
  explicitly designed so; mutation outcome must be logged as failed if the mutation itself
  fails.
- **Live Appwrite provisioning depends on owner credentials** → Split owner-gated tasks
  from agent-runnable verification scripts.
- **Device farm results can drift by OS/device image** → Pin device profiles and record
  the profile matrix in the test artifact.
- **Umbrella scope is too broad** → This change is a sequencing/foundation spec. Each
  implementation phase should remain small and may spawn narrower child changes if the
  diff would exceed the atomic batch target.

## Migration Plan

1. Adopt process files already created in pre-work: `FACTORY.md`, `DECISIONS.md`,
   `READINGS.md`, `session.log`, and `CLAUDE.md` references.
2. Close the current active `fix-video-backup-truth-and-unify-account` owner-gated tasks
   before treating multi-user sync as ready.
3. Run the domain restructure as mechanical, behavior-preserving import moves.
4. Add audit-log schema behind a Drift migration with tests and no deletion of old data.
5. Wire audit logging through repositories/state-machine transitions in small batches.
6. Execute Appwrite Phase M provisioning and cross-device sync proofs from the runbook.
7. Add Android/device test harness and make it part of release readiness.
8. Complete web/payment distribution provisioning after secrets and owner accounts exist.

Rollback strategy:

- Process files can be amended without runtime effect.
- Source moves can be reverted as ordinary commits before further work depends on them.
- Audit schema migrations are additive; rollback disables readers/writers, not the table.
- Appwrite provisioning rollback follows `docs/appwrite-selfhost.md` and
  `docs/phase-m-runbook.md`; Drift remains local source of truth.
- Vercel rollback uses the existing deployment rollback path in `docs/web-deploy.md`.

## Open Questions

- Which exact domain folder names are final: `sets` vs `labs`, `backup` vs `media`, and
  whether `kernel` holds only pure domain primitives or also cross-domain app services.
- Which Android device-farm provider/config is meant by "Argent" in this repo: a local
  script, an external service, or a to-be-created wrapper.
- Whether audit log rows should be user-exportable in the product UI or only available
  through developer/support tooling for the first release.
- Whether domain restructure should be a child OpenSpec change to reduce the umbrella
  change's review surface.

# Align Cross-Client Foundations (gap-filler + spec-ledger reconciliation)

## Summary

A **gap-filler** change. It specs ONLY the concerns no pending change covers — the multi-user
sync model, the security/cryptography posture, the cross-client design-token source of truth,
the notes edit-conflict guard, the web state-machine architecture, and the docs/ledger
discipline — and reconciles the OpenSpec ledger with codebase reality so the next session
starts from truth, not drift.

It **does not re-specify** territory owned by other strict-valid changes:

- Backend, auth, realtime, per-entity cutover → `migrate-canonical-backend-to-appwrite`
  (Phase H done on branch `phase-h-hardening`; Phase 0 provisioning is NEXT and owner-gated).
- Web studio capabilities (bidirectional CRUD, tombstone delete, combo/set builders)
  → `add-web-authoring-and-lifecycle-studio`, targeted by Appwrite Phase 6.
- Flutter state-machine framework → `state-machine-crud` (ALREADY IMPLEMENTED in
  `lib/core/state_machines/` — `Machine<S,E>` sealed-class framework wired into move_detail,
  combo_detail, add screen, providers; its tasks.md shows 0/51 purely from ledger drift).

Executor: **Opus 4.8, fresh session.** This document plus `design.md` carries every decision;
no conversational context is required.

## Motivation

- A session-start audit (2026-07-06) found the spec ledger materially out of sync with the
  codebase: `state-machine-crud` 0/51-checked yet largely shipped; `add-convex-sync-backend`
  superseded but still pending; `add-discovery-graph-interface` 26/26 done but unarchived; two
  apparent duplicates of an already-archived silent-playback change. Planning on top of a
  false ledger produces wrong priorities every session.
- Four real gaps have no owning spec: who syncs (multi-user model), the crypto/threat posture,
  a web design system tied to `lib/core/design/`, and draft-clobber protection for notes under
  realtime sync. Each blocks or distorts Appwrite Phases 3–6 if left implicit.
- The repo has **no root CLAUDE.md** and duplicated roadmaps (`ROADMAP.md` +
  `docs/ROADMAP.MD` + `docs/PROGRESS.MD`), so every agent session re-derives ground truth.

## Scope

**In scope**
1. **Ledger reconciliation (Wave 1, no Appwrite needed):** verify-and-archive drifted/
   superseded/complete changes; reorder the backlog so the Appwrite spine is on top.
2. **Docs contract (Wave 1):** repo-root `CLAUDE.md` agent contract; roadmap dedupe; README
   refresh (finishing `repo-organization-and-readme-refresh` remaining tasks where they
   overlap); ledger-hygiene rule.
3. **Design tokens (Wave 1 table, Wave 3 CSS):** canonical `docs/design/TOKENS.md` table;
   CSS custom properties on web conforming to it.
4. **Multi-user sync model + security posture (constraints on Phases 3–5):** private
   per-user sync; transport + secrets hygiene; E2EE and Temporal as explicit non-goals.
5. **Notes conflict guard (Wave 2, with Appwrite Phase 4 moves cutover).**
6. **Web state machines (Wave 3, with Appwrite Phase 6):** XState v5, mirroring Flutter
   machine designs 1:1.
7. **Cross-device scenario matrix** as acceptance criteria (the "user-flow blind-spot" audit).

**Out of scope (explicit non-goals, decided 2026-07-06 after grilling)**
- **E2EE** — server-derived FSRS (Dart Appwrite Function) and web-studio rendering require
  server-readable data. Posture is transport + secrets hygiene + per-user document
  permissions.
- **Temporal / any durable-workflow engine** — idempotent LWW ops, cursors with rollback
  (Phase H), the upload spool, and Appwrite Functions already cover the need; running a
  workflow cluster contradicts the managed-start/zero-ops motivation.
- **Replacing Flutter's `Machine<S,E>`** with XState-alike or any dependency — it is shipped
  production code.
- **Shared/collaborative state** (crews, coaches, cross-user sharing) — deferred entirely.
- **Token codegen** — flagged later task; earns weight only when a third token consumer
  appears.
- **CRDTs** — re-affirmed rejected (per Appwrite master spec).

## Platform release framing

The three waves keep **iOS, Android, and web** on one release path: Wave 1 is
platform-neutral hygiene; Wave 2 lands in the Flutter clients (iOS + Android from one
codebase) alongside the Phase 4 cutover; Wave 3 brings the web studio to parity on the same
tokens and machine designs. No wave forks platform behavior.

## Capabilities (all ADDED)

- `multi-user-sync-model` — private per-user sync; owner is user #1; local-only untouched.
- `security-posture` — transport + secrets hygiene; token storage; scope minimization.
- `design-tokens` — `docs/design/TOKENS.md` as single source; Dart + CSS conformance.
- `notes-conflict-guard` — dirty-guard over record-level LWW on both clients.
- `web-state-machines` — XState v5 statecharts mirroring Flutter machine designs.
- `spec-ledger-hygiene` — root CLAUDE.md contract, roadmap dedupe, same-commit ledger rule.

## Impact

- `openspec/changes/` — archive/supersede 4–5 changes; tick `state-machine-crud` to reality.
- New: `CLAUDE.md` (repo root), `docs/design/TOKENS.md`.
- Modified: `ROADMAP.md`, `README.md`; removed after fold-in: `docs/ROADMAP.MD`,
  `docs/PROGRESS.MD`.
- Wave 2: notes editing machines in `lib/core/state_machines/` + sync apply path.
- Wave 3: `web-mirror/` gains XState v5 dep, machine modules, `tokens.css`.
- No schema changes. No user data touched. Additive-only per the brownfield constraint.

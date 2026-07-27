## Why

Breakdex has 35 OpenSpec changes, a mature sync backend, real users, and 69 unpushed commits. The engineering factory is operational but lacks session-lane discipline — every session mixes research, design, and implementation, so specs acquire implementation bias, provenance is conversational, and work is lost between sessions. At the same time, the next frontier (multi-user sync, Android distribution, production hardening) is blocked on a handful of owner-gated device proofs and a codebase layout organized by technical layer rather than product domain.

This change adapts valoric's factory model (Scholar/Teacher/Student sessions, six-record provenance system, domain-organized layout) to Breakdex's existing openspec/ and engineering-manual infrastructure, then sequences the remaining work to close the active change, restructure the codebase, add an audit trail, enable multi-user sync, ship Android testing, and prepare for distribution.

## What Changes

- **Factory adoption (pre-work, done):** FACTORY.md operating manual, DECISIONS.md ledger, READINGS.md evidence trail, session.log, CLAUDE.md session-type preamble — all created in the opening pre-work diff.
- **Phase A — Close active change:** Owner device proof (re-sign Google, clear stale ops, verify the 18 recovered videos drain to backed up). Tick remaining 7 owner-gated tasks in `fix-video-backup-truth-and-unify-account`.
- **Phase B — Domain-file restructure:** Reorganize `lib/` by product domain (moves/, combos/, backup/, sync/, auth/, kernel/, ui/) — additive over invasive, no behavior change.
- **Phase C — Action audit log:** Persistent, append-only log of every mutation and state transition. Built on existing Machine<S,E> framework + Drift. "Blackbox" recorder for debugging and support.
- **Phase D — Multi-user cloud sync:** Appwrite Phase M provisioning + soak. Per-user private sync, cross-device identity, record-level LWW + tombstones. The existing code is ready — this is the live provisioning and verification.
- **Phase E — Android + device testing:** Argent device farm, Maestro/Patrol E2E tests, Android `repro.sh`, multi-device smoke test.
- **Phase F — Distribution prep:** Vercel secrets, Lemon Squeezy variants, invite-code mint+send, web release push.

## Capabilities

### New Capabilities
- `domain-restructure`: Reorganize lib/ by product domain (moves, combos, sets, backup, sync, auth, kernel, ui). Additive, no behavior change.
- `action-audit-log`: Append-only persistent log of mutations and state transitions, keyed by entity+operation+timestamp. Queryable for debugging.
- `multi-user-sync`: Per-user private Appwrite sync with cross-device identity, LWW reconciliation, tombstone propagation.
- `android-e2e`: Android device-farm test suite with Argent, Maestro E2E flows, multi-device smoke gate.
- `distribution-web`: Vercel deploy pipeline, Lemon Squeezy offering IDs, invite-code minting and sending.

### Modified Capabilities
- *(none — all existing specs remain; this change is additive)*

## Impact

- **Codebase layout:** `lib/core/features/` → `lib/domain/{moves,combos,backup,sync,auth,kernel,ui}/`. No files deleted — additive restructuring with deprecation stubs.
- **State architecture:** Machine<S,E> gets a logging middleware — zero behavioral change, new sidecar table in Drift.
- **Sync architecture:** Existing LWW/tombstone/dirty-guard code gets live Appwrite provisioning. No new transport code.
- **Testing infrastructure:** New Android-specific `repro.sh`, argent config, Maestro flows. Existing test suites unchanged.
- **Deployment:** Vercel pipeline exists; Lemon Squeezy webhook is code-complete and gated on variant IDs.

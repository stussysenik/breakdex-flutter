# Design: Distribution Prep — Web Release Readiness

This change is self-contained (it was previously split from the archived
`engineer-workflow-and-multi-user-foundation`; that parent's design is gone, so the
decisions live here).

## Offering config: where ids live

**Decision: offering ids are owner-provisioned build-time config, overridable at runtime
via `RemoteConfig`.** Two sources, one read path:

1. **Build-time (env).** A `--dart-define` (`OFFERINGS_JSON`) supplies the canonical
   offering map at compile time. This is the default-release source of truth — it ships
   in the binary, so a released build is self-sufficient offline.
2. **Runtime override (remote).** `RemoteConfig.cohortProfiles` / a dedicated
   `offerings` JSON column can override ids per cohort without a rebuild — the "my own
   versions" mechanism (same binary, per-cohort flag profile) already proven for flags.

`OfferingsConfig.resolve()` reads remote-first, falls back to the compiled env, falls
back to **absent** (not a placeholder id). Absent = paid flows disabled. This mirrors
the existing `RemoteConfig` fallback ladder (remote → last-cached → defaults) and the
entitlement gate's fail-open posture.

**Why not hardcode?** A released build with a test-mode id would let a real user hit
a real checkout for a $0 / wrong offering. Config-not-code + absent-disable makes the
safe state the default state.

## Invite minting: admin capability

**Decision: mint is an Appwrite Function (`invites-mint`), not client-callable.** The
client-side redeem (`EntitlementService.redeem`) already exists and is the only
client-facing surface — it must stay that way, or anyone could mint codes. Minting
requires owner auth (Function execution scoped to the owner's team/role) and persists
a row carrying `code`, `tier`, `cohort`, `status`, `createdAt`, `createdBy`.

The mint Function returns the code + a traceable release record (code, tier, cohort,
timestamp) that flows directly into the release-handoff document. Redeem and mint
share the `invites`/`entitlements` schema the existing redeem already uses — no new
table, new status values only (`reserved` pre-redeem).

## Release handoff: a document, not a conversation

**Decision: a checked-in `docs/web-release-handoff.md` template, filled per release,
gated by a checklist.** The checklist gates on: (1) offering ids configured, (2) at
least one invite minted per tier being released, (3) `verify.sh` green, (4) deploy URL
recorded. Rollback path is written explicitly (Vercel Instant Rollback vs tag-rebuild
rebuild — both already documented in `docs/web-deploy.md`, referenced not duplicated).

The handoff is the owner's release-decision record. It is produced by the executor,
approved by the owner — never self-graded.

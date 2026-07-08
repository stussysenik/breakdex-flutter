# Web-First Private Release & Monetization

## Summary

Turn Breakdex from a personal production app into a **released product for the bboying
community**, web-first: bring up **Flutter Web as the application itself** (same codebase, zero
install), gate it behind **invite codes**, price it as offerings in the **$4.20–$9.99 USD** band,
and ship with **modern release hygiene** (GUIDE.md, versioned releases, config-driven update
messaging). Once the web release is tested and features stabilize, the **same product rolls out
naturally to iOS (TestFlight → App Store) and then Android** — one product, staged by platform
risk.

Owner rulings (2026-07-08 grilling):
- **Web first.** The Flutter Web build is the first released application surface; the Next.js
  studio (`add-web-authoring-and-lifecycle-studio`) remains the owner's system-of-record and
  authoring surface — they coexist, they are not rivals.
- **Invite codes = "my own versions."** A code binds a user to an entitlement tier AND a config
  cohort (per `remote-config` cohort profiles in `migrate-canonical-backend-to-appwrite`), so
  special versions ship from one binary.
- **Config-first live updates**; Shorebird code-push stays a flagged post-launch evaluation
  (Appwrite change task 7.4).
- **iOS-first after web** (users are on iOS today); Android bring-up follows stabilization.
- **DX ethos:** everything per common modern standards — this release toolchain is the repo's
  own reusable "ruby toolset" (versioning, invites, config, guide) built on the canonical stack,
  optimized for business velocity.

## Why

The product serves a real community and the owner wants outside-POV testing ("see it as an
invitee") plus revenue validation without store friction: web releases need no review, update
instantly (pairs with `remote-config`), enforce invites trivially, and take payments without the
30% store cut during validation. Stores come once the product has stabilized on web.

## Relationship to existing changes

- **Depends on** `migrate-canonical-backend-to-appwrite`: identity (Phase 3), sync (Phases 2/4),
  and `remote-config` (Phase 1R) are the substrate; invites/entitlements live in the same Appwrite
  project. Flutter Web bring-up (Phase 1 here) can start before Appwrite cutover completes.
- **Coexists with** `add-web-authoring-and-lifecycle-studio` (owner authoring studio; different
  audience — this change ships the consumer app).
- **Feeds** `harden-code-ownership-and-config-purge`: release exposes the repo to outside eyes;
  the ownership pass makes every shipped byte defensible.

## Scope

### In scope
- `flutter-web-app`: the Flutter codebase building and serving as the released web application
  (Drift on WASM/OPFS, web auth, web video playback, platform-gap surfacing).
- `monetized-invites`: invite-code redemption, entitlement tiers, offerings priced $4.20–$9.99,
  web checkout (merchant-of-record), entitlement gate in released builds.
- `release-hygiene`: GUIDE.md (install/update/remove per platform), monotonic versioning,
  release notes, deploy pipeline, staged platform rollout (web → iOS → Android).

### Out of scope
- Code-push/OTA Dart updates (Appwrite change 7.4, flagged).
- Cross-user sharing/collaboration (non-goal per repo contract).
- The Next.js studio's features (owned by its own change).
- App Store / Play production launch execution beyond readiness (final store submission is
  owner-gated at the end of Phase 5).

## Impact
- **New capabilities:** `flutter-web-app`, `monetized-invites`, `release-hygiene`.
- **Depends on:** `migrate-canonical-backend-to-appwrite` (identity, sync, remote-config).
- **New surfaces:** `web/` Flutter target, invite/entitlement collections + redeem Function,
  payments webhook Function, `GUIDE.md`, release CI.

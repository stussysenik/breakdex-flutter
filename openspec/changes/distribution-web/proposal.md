# Distribution Prep — Web Release Readiness

> **Language: Dart (Flutter) + shell (YAML/CI).** Depends on:
> `add-web-first-release-and-monetization` (pricing/offering rulings), `appwrite`
> (entitlement + remote config). Implementation in a fresh student session — never
> this one.

## Why

The web release pipeline is **wired but not verified end-to-end.** `release.yml` →
`deploy-web.yml` → Vercel is in place and self-skips cleanly when secrets are absent
(`docs/web-deploy.md`); the entitlement gate (`EntitlementGate`, a pure function of
booleans, exhaustively `switch`ed) and `RemoteConfig` (Appwrite `appConfig` singleton,
JSON columns decoded defensively) both exist. But three things are missing, and they
compound into "we cannot ship a paid web release with confidence":

1. **No owner-provisioned offering config.** The locked monetization ruling names
   **Lemon Squeezy** as merchant-of-record with offerings at **$4.20–$9.99 USD**.
   Today `lib/` has *no* Lemon Squeezy references — offering ids and price variants
   would have to be hardcoded by the executor. A paid flow must read its offering
   ids from owner-supplied config (env/remote), and stay disabled/hidden when they
   are absent, or the first test purchase hits a placeholder.

2. **No invite-code minting path.** `EntitlementService.redeem` (client-side redeem)
   exists, but the *admin* side — minting a private invite code and binding it to a
   specific entitlement tier + config cohort so the release record is traceable —
   does not. The private-release model (invite codes bind entitlement + cohort) is
   locked; minting is the missing half.

3. **No release-handoff artifact.** There is no single document that records, for a
   given release: the commit, build version, device matrix, sync proof, deploy URL,
   known risks, and rollback path. Without it, the owner's release decision rests on
   a conversation, not a record — and a rollback under incident pressure has no
   written path.

This change makes the web release **repeatable and owner-operable**: offering ids are
config-not-code, invites are mintable + traceable, and every release lands a handoff
document. It is the operational complement to `add-web-first-release-and-monetization`
(which owns the *rulings*).

## What Changes

- **Lemon Squeezy offering config.** A typed `OfferingsConfig` read from owner-supplied
  config (env at build time, overridable via remote config), with offering id + price
  variant per tier. Paid UI reads it; absent config ⇒ paid flows disabled + release
  checklist names the missing owner action. No hardcoded ids.
- **Invite-code minting.** An admin capability (Appwrite Function or owner-only API)
  that mints a code, binds it to tier + cohort, persists it, and returns a traceable
  release record. The client-side redeem already exists; this adds the mint half.
- **Release-handoff template + checklist.** A `docs/web-release-handoff.md` template
  (commit, build, matrix, sync proof, deploy URL, risks, rollback) and a checklist
  that gates the release on offering ids + entitlements being configured.

## Capabilities

1. Paid web flows read offering ids from owner-provisioned config, never hardcoded.
2. Owner can mint traceable invite codes bound to tier + cohort.
3. Every release produces a written handoff with rollback path.

## Footprint estimate

| Surface | Current → Target | Notes |
| --- | --- | --- |
| `lib/core/config/` | +1 file (`offerings_config.dart`), ~80 LOC | typed config + fallback |
| `lib/core/config/widgets/` | modify purchase flow, ~40 LOC | read config, disable when absent |
| Appwrite Functions | +1 (`invites-mint`), ~120 LOC | mint + bind + persist |
| `docs/` | +1 (`web-release-handoff.md` template), ~60 LOC | handoff artifact |
| Tests | +1 file (`offerings_config_test.dart`), ~60 LOC | config parse + fallback |

Net: ~360 LOC, +2–3 files. No new public API surface beyond the mint Function.

## Non-goals

- **Pricing/cohort *rulings*** — owned by `add-web-first-release-and-monetization`
  (Lemon Squeezy, $4.20–$9.99, web merchant-of-record). This change consumes those
  rulings, never re-derives them.
- **Vercel pipeline wiring** — already done (`release.yml` → `deploy-web.yml`,
  `web/vercel.json` SPA fallback + no-cache entries). This change verifies, never
  re-wires.
- **Client-side redeem** — already done (`EntitlementService.redeem`,
  `RedeemOutcome`). This change adds mint, not redeem.
- **iOS/Android store submission** — downstream of the locked "web-first, iOS after
  web soak" ruling; owned by the archived `breakdex-app-store-launch` halves
  (`add-media-manager` + `add-web-first-release-and-monetization`).

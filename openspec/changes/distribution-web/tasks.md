# Tasks: Distribution Prep — Web Release Readiness

> **Language: Dart (Flutter) + shell.** Depends on:
> `add-web-first-release-and-monetization` (pricing/offering rulings), `appwrite`.
> Implementation in a fresh student session — never this one.

Phases 1–2 independent; Phase 3 consumes both. MATLAB law: one step → compile → run
its test → inspect the state → next. Never commit or stage. If the spec is ambiguous,
write the question to `openspec/changes/distribution-web/NOTES.md` and stop that task
— never improvise around it. Live Lemon Squeezy, real OAuth, and production deploys are
USER-GATED: no task below touches live money, a real account, or prod. Loopback +
fixture + `--dart-define` is the complete deliverable.

- [ ] 1. **Offering config — typed + resolve ladder.** Add
      `lib/core/config/offerings_config.dart`: `OfferingsConfig` (per-tier id +
      variant), `OfferingsConfig.resolve()` (remote → env → absent), and a
      `--dart-define=OFFERINGS_JSON` build hook. Malformed input degrades to absent,
      never throws. **Gate:** `offerings_config_test.dart` — present resolves the id,
      absent disables, remote overrides env, malformed degrades to absent. Spec:
      "Offering ids are owner-provisioned, never hardcoded."

- [ ] 2. **Purchase flow reads config + disables when absent.** Wire the existing
      purchase UI to `OfferingsConfig.resolve()`; when a tier is absent, that tier's
      paid control is hidden/disabled and no checkout can start. **Gate:** widget test
      — with ids present the paid path renders; with ids absent the paid path is
      disabled and no offering id literal appears in the built tree. Spec: "When
      absent, paid flows are disabled or hidden."

- [ ] 3. **Invite-mint Function — owner-scoped + traceable.** Add Appwrite Function
      `invites-mint`: owner-auth-gated, generates N codes, binds each to tier +
      cohort, persists `status: reserved`, returns the release record. Reuse the
      `invites`/`entitlements` schema the existing redeem already uses. **Gate:**
      Function invoke test — owner mint returns N distinct traceable codes; non-owner
      invoke is rejected server-side; a minted code redeems through
      `EntitlementService.redeem` to the granted tier + cohort. Spec:
      "Admin invite-code minting bound to tier and cohort."

- [ ] 4. **Release-handoff template + checklist.** Add `docs/web-release-handoff.md`
      (commit, build, matrix, sync proof, deploy URL, risks, rollback) and a
      checklist gating on offering ids configured, ≥1 invite per tier minted,
      `verify.sh` green, and deploy URL recorded. Rollback names both Vercel paths
      from `docs/web-deploy.md`. **Gate:** the template renders a complete handoff
      for a sample release; the checklist refuses to clear when offering ids are
      absent. Spec: "Per-release handoff artifact with rollback path."

- [ ] 5. **Verify + record NOT PROVEN.** Run full `./verify.sh`; record the layers
      that still require owner/device/live-cloud checks (live Lemon Squeezy checkout,
      production deploy, real OAuth) in the handoff's NOT PROVEN section — never
      self-grade them. **Gate:** `verify.sh` exit 0; NOT PROVEN section names exactly
      what was not proven.

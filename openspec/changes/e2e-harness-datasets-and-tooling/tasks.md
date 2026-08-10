# Tasks: E2E harness, datasets, and tooling

> **Language: Dart (Flutter) + shell.** Depends on: `automation-fixture-service`,
> `appwrite`, `gdrive`, `enforce-face-law-conformance`, `android-e2e`.
> Implementation in a fresh student session — never this one.

MATLAB law: one step → compile → run its test → inspect the state → next.
Never commit or stage. If the spec is ambiguous, write the question to
`openspec/changes/e2e-harness-datasets-and-tooling/NOTES.md` and stop that task —
never improvise around it. Physical-device runs, live Appwrite/GDrive, real OAuth,
and payments webview are USER-GATED: no task below touches a live backend, a real
account, a device the owner must provide, or money. Loopback + simulator + emulator +
fixture media is the complete deliverable.

- [ ] 1. **Dataset profiles — countable and seed-stable.** Extend
      `automation_fixture_service.dart` with named profiles (`empty`, `solo`,
      `arsenal`, `combo-lab`, `sync-storm`), each a pure function of `(seed, now)`
      returning companions, each documenting exact counts (moves, combos, decks, FSRS
      cards, reviews, due-now). Replace absolute `DateTime.now()` timestamps in the
      existing stress fixture with `now - offset` so the profile is seed-stable. Add a
      `counts` map to each profile and a test that seeds then asserts every documented
      count matches a count query. **Gate:** `test/core/services/
      automation_fixture_service_test.dart` — each profile's documented counts match
      the seeded DB; two seeds of the same profile yield byte-identical export JSON.
      Spec: "Datasets are countable, deterministic, and seed-stable."

- [ ] 2. **Fixture media family — ffmpeg, deterministic, hashed.** Add
      `scripts/seed_media.sh`: generate a family of small clips from a pinned seed
      covering duration / resolution / orientation / codec / audio / motion; print
      each clip's size and sha256; re-run byte-identical. Retain the three committed
      `fixtures-*-beat.mp4` as the smoke tier. Add `test_fixtures/README.md`
      cataloguing every clip + dataset with hash and seed. Wire a media-seed hook into
      `automation_fixture_service` so a flow can request "matrix media" vs "smoke
      media". **Gate:** run `seed_media.sh` twice with the same seed and byte-compare
      every clip; confirm the smoke tier uses no `ffmpeg`. Spec: "Fixture media is a
      deterministic, varied, hashed family" + "Smoke tier stays lightweight."

- [ ] 3. **Permission matrix + pre-check tool.** Author `test_fixtures/permissions.md`
      (per surface × flow-group: required permissions + exact grant command/API, "none"
      where none). Implement `scripts/e2e_check_permissions` to read it and fail fast
      with a named fix when a needed permission is missing. **Gate:** with Photos
      revoked on a simulator, `e2e_check_permissions` exits non-zero printing the exact
      `simctl` grant command before any flow runs. Spec: "The permission matrix is
      committed and surfaced-first" + dev-tools scenario.

- [ ] 4. **Web E2E seam + Playwright harness.** Add a `WebDriver` abstraction with a
      Playwright implementation driving the released `flutter build web` bundle on
      loopback. Implement the smoke flows (launch, home renders seeded data, add-move
      sheet, review session, combo create) to run on desktop + mobile-chromium (iPad)
      viewport via the same flow definition. Select by Face-Law contract only. **Gate:**
      `scripts/e2e.sh web smoke` passes on both viewports; a pack swap does not red it.
      Spec: "Web E2E covers the released product on desktop and iPad" + "Flows select
      by the Face-Law selector contract."

- [ ] 5. **Native flow re-validation + Patrol escape hatch.** Re-validate the 46
      existing `.maestro/` flows against the current Face-Law surface (a mapping task:
      `moves-tab`→`breakdex-tab`, etc.; `flow-tab` has no successor; parked as
      `.yaml.disabled` where the gesture died). Author the net-new smoke flows against
      the Face-Law selector contract. Add `integration_test/` with Patrol only where a
      flow is un-drivable by Maestro (native permission dialog, auth WebView) — not
      speculatively. **Gate:** `scripts/e2e.sh ios smoke` and `android smoke` run the
      mapped smoke flows green on a simulator / emulator. Spec: "Critical flows are
      automated where possible" (absorbing `android-e2e` 6.3).

- [ ] 6. **The single entry point + dev tooling.** Implement `scripts/e2e.sh`
      (tier × surface, ranked web→ios→android→device, each tier a superset/gate) and
      the `scripts/e2e_*` tools (`list`, `diff`, `matrix`, `check_permissions`). Wire
      `scripts/verify_e2e.sh` into root `verify.sh` (Phase 0 + `E2E_TIER` on
      `E2E_SURFACE`, default `web smoke`). **Gate:** `verify.sh` runs the E2E gate; a
      miscounted dataset or unparseable flow fails Phase 0 with no device; the device
      matrix accumulates rows in `test_fixtures/device_matrix.jsonl`. Spec: "A single
      multi-surface E2E entry point" + "Test-management dev tools" + "Gates print what
      they did not prove."

- [ ] 7. **Phased rollout + honest NOT PROVEN.** Implement the four-phase ladder in
      `scripts/e2e.sh` (Phase 0 parse/lint → 1 web smoke → 2 device smoke → 3 full
      matrix → 4 owner device), each gating the next, each printing its `NOT PROVEN:`
      lines verbatim. Confirm Phase 4 (physical device) and the `cloud` tier
      (live Appwrite/GDrive) are explicitly NOT PROVEN in CI. Archive `android-e2e` as
      shipped-half (its smoke script retained as a referenced artifact), noting this
      change absorbed its surviving legs. **Gate:** with Phase 1 red, Phase 2 refuses
      with "gate: web smoke not green"; a green Phase 1 run prints the verbatim NOT
      PROVEN lines. Spec: "Rollout is gradual, gated, and honest."

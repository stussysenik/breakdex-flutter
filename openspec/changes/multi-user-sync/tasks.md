# Tasks: Multi-User Sync — Private Per-User Sync Proof Across Devices

> **Language: Dart (Flutter) + shell.** Depends on: `appwrite`,
> `migrate-canonical-backend-to-appwrite`, `add-first-user-production-provisioning`.
> Implementation in a fresh student session — never this one.

This change **proves** the locked private-per-user model; it does not build new sync
implementation. Per the factory's "no agent-driven device runs" bar, every task needing
two physical devices, live Appwrite, or real OAuth is **OWNER-GATED** — the owner runs it
in a dedicated session; the agent delivers the *document + loopback tests*, never the
device run. Ledger rule: tick in the same commit that lands the work. Binary truth: no
tick without terminal-verified evidence (analyze/test output).

- [ ] 1. **Isolation proof matrix (document).** Author `docs/sync-isolation-proof.md`:
      the three cases (shared-device user switch; second-device hydration incl. unsynced
      local state + tombstones; dirty-guard under cross-device edit), exact steps, expected
      result, and a fill-in-later `Actual result` field per case. Tag each case
      OWNER-GATED or loopback-testable. **Gate:** document enumerates all three cases with
      steps + expected + NOT PROVEN split. Spec: "Private per-user cloud space is proven,
      not assumed."

- [ ] 2. **Dirty-guard loopback regression test.** Add
      `test/core/sync/sync_isolation_regression_test.dart`: the dirty-guard decision holds
      an inbound realtime update against a locally-dirty record (never clobbers the
      in-progress edit). **Gate:** test is red when the dirty-guard is removed, green when
      present (red-first); `flutter analyze` clean. Spec: "Dirty-guard holds inbound
      updates against in-progress edits."

- [ ] 3. **Isolation-filter loopback regression test.** In the same file: a sync-pull read
      for a signed-in `userId` filters to that `userId` (an unfiltered read would cross).
      **Gate:** test green; `flutter analyze` clean. Spec: "Server-side isolation is
      exercised by a loopback test."

- [ ] 4. **NOT PROVEN ledger.** In `docs/sync-isolation-proof.md`, record exactly which
      legs are loopback-proven vs. OWNER-GATED (two devices / live cloud / real OAuth) and
      the honest split — a green document never implies more than it tested. **Gate:** every
      OWNER-GATED case is named; nothing is self-graded. Spec: "NOT PROVEN ledger is
      honest."

- [ ] 5. **Verify + advance.** Run full `./verify.sh`; confirm the proof document is
      complete and the regression tests green. **Gate:** `verify.sh` exit 0; document +
      tests land in the same commit.

# Tasks — align-cross-client-foundations

Executor: Opus 4.8, fresh session. Read `proposal.md` + `design.md` first; decisions there
are settled. Tick each box in the SAME commit that lands the work (D7.3 — this change
introduces that rule; model it).

## Wave 1 — Ledger + docs + tokens (no Appwrite; branch off main after phase-h merges)

### 1. Ledger reconciliation (D8)
- [ ] 1.1 Audit `state-machine-crud/tasks.md` (51 items) against `lib/core/state_machines/`
      and consuming screens; tick everything shipped; list residual open items at the top of
      that tasks.md under "## Residual (verified 2026-07-06 audit)"
- [ ] 1.2 Archive `add-convex-sync-backend` with a supersession note pointing at
      `migrate-canonical-backend-to-appwrite` (use `openspec archive` tooling)
- [ ] 1.3 Archive `add-discovery-graph-interface` (26/26 done)
- [ ] 1.4 Verify `add-quiet-playback-and-senior-drill-ui` and
      `add-silent-video-mode-and-accessible-drill-launcher` against shipped silent-playback
      code; archive as duplicates of the 2026-06-16 archived change, or write a 3-line
      re-scope note if any requirement is genuinely unshipped
- [ ] 1.5 Rewrite `ROADMAP.md` backlog section in D8 priority order (Appwrite spine on top;
      flag — do not decide — the `evolve-web-mirror-to-crud-platform` vs studio supersession)

### 2. Docs contract (D7)
- [ ] 2.1 Create repo-root `CLAUDE.md`: canonical stack rulings (Appwrite; Next 15 + XState
      v5; `Machine<S,E>`; TOKENS.md; LWW + dirty-guard; non-goals E2EE/Temporal/CRDTs),
      pointer to ROADMAP.md, and the same-commit ledger rule
- [ ] 2.2 Fold `docs/ROADMAP.MD` + `docs/PROGRESS.MD` content worth keeping into root
      `ROADMAP.md`; delete both files; fix any inbound links
- [x] 2.3 Refresh `README.md` architecture/status sections to current truth (Appwrite
      direction, web-mirror status, state-machine framework); reused remaining
      `repo-organization-and-readme-refresh` tasks where they overlap and ticked them there

### 3. Design tokens — canonical table (D5)
- [x] 3.1 Create `docs/design/TOKENS.md`: one table per token group (colors, spacing 8pt/4pt,
      typography/Inter, depth) with columns: token, value, Dart constant
      (`lib/core/design/*`), CSS custom property (planned), consumers
- [x] 3.2 Verify every Dart constant in `lib/core/design/` appears in the table (no orphans
      either direction); all 88 constants from 5 source files are covered

### GATE 1 (D9): `openspec validate --strict --no-interactive` green for every touched
### change; `flutter analyze` zero; 3 spot-checked doc claims match code. Do not proceed red.

## Wave 2 — Notes conflict guard (with Appwrite Phase 4 moves cutover)

- [ ] 4.1 RED: write a failing test — move detail machine in editing/dirty state receives an
      inbound sync apply for the same record; assert the draft survives (currently clobbers)
- [ ] 4.2 Implement the dirty-guard: sync apply path consults the record's machine state;
      inbound update for a dirty record is held (latest-wins queue of one) and applied on
      save/discard transition
- [ ] 4.3 Extend guard to combo detail notes and any other free-text editing machines
- [ ] 4.4 GREEN: 4.1 test passes; add a second test for held-update-applied-after-save;
      full `flutter test` green

### GATE 2 (D9): red→green evidence captured in the commit message; suite green.

## Wave 3 — Web tokens + machines (with Appwrite Phase 6 studio substrate)

- [ ] 5.1 Add `web-mirror/src/styles/tokens.css`: CSS custom properties conforming 1:1 to
      TOKENS.md; update TOKENS.md CSS column from "planned" to actual
- [ ] 5.2 Add XState v5 to `web-mirror`; port the move-detail machine design (states/events/
      guards from the Flutter machine) as the first statechart; document the mirroring
      convention in `web-mirror/README.md`
- [ ] 5.3 Model-test the web machine against the same transition table as the Flutter test
      (same scenarios, same expected states)
- [ ] 5.4 Implement the web-side dirty-guard using the same held-inbound rule (D6) on the
      studio's realtime subscription path
- [ ] 5.5 Web session security per D3: verify Appwrite web session uses httpOnly cookies;
      no tokens in localStorage; document in CLAUDE.md security section

### GATE 3 (D9): machine model tests green both runtimes; tokens.css ↔ TOKENS.md diff clean.

## V. Cross-device scenario matrix (acceptance criteria — walk each with evidence)

- [ ] V.1 Local-only user (never signed in): full CRUD works offline; zero sync traffic
- [ ] V.2 First sign-in on a device with existing local data: legacy records claimed under
      the new account (Appwrite spec's uid mapping); nothing orphaned or duplicated
- [ ] V.3 Edit notes on phone while web studio has the same move open: phone draft never
      clobbered mid-edit; web sees the saved result via realtime after save
- [ ] V.4 Offline edit on phone → reconnect: LWW reconcile converges; no data loss either side
- [ ] V.5 Token/session expiry mid-edit: draft preserved locally; re-auth resumes sync
      without losing the pending write
- [ ] V.6 Second user signs in on a fresh install: sees ONLY their own space; owner's data
      unreachable (per-user permission check)

## Validation
- [x] W.1 `openspec validate align-cross-client-foundations --strict --no-interactive` green
- [ ] W.2 Each gate's evidence (test output, diffs) referenced in commit messages

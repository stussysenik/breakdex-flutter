# Tasks — Marathon Reliability & Device Diagnostics

Ledger rule: tick each box in the same commit that lands the work.
Parallelism: Phases 1–3 are independent of each other; Phase 4 consumes all three.

## Phase 1: Stability foundation

- [ ] 1.1 Disposal audit across the 9 controller-owning shared widgets (pressable,
  celebration_overlay, combo_step_line, notes_section, app_segmented_control, beat_grid,
  video_player_widget, metadata_video_picker_sheet, loading_state_widget); fix leaks
  in place. (Overlaps `redesign-visual-first-experience` 1.2 — whichever lands first ticks
  both ledgers in its commit.)
- [ ] 1.2 Sweep loading states: every spinner resolves to content, error+retry, or escape;
  extend `loading_state_widget.dart` with the retry affordance and adopt at call sites.
- [ ] 1.3 Flow-state protection: background failures during an active review report
  passively (status surface), never modally.
- [ ] 1.4 Soak driver: scripted repeat of browse → play → review → add → sync (Maestro loop
  or Patrol harness) with a documented cycle count ≈ 8h; memory plateau assertion via
  platform tooling; runbook in the repo.

## Phase 2: Startup budgets

- [ ] 2.1 Add startup trace marks (first frame, library interactive); record per release
  build on the reference device + web.
- [ ] 2.2 Defer sync-engine/provider init off the first-frame path; library renders from
  Drift before network work; offline cold start proves it.
- [ ] 2.3 Budgets asserted: mobile ≤ 2.5s, web ≤ 5s to interactive; measured numbers land in
  the release notes.

## Phase 3: Device diagnostics

- [ ] 3.1 Check runner: a `DiagnosticCheck` seam (id, run() → pass/degraded/fail + one-line
  diagnosis + measured value), deterministic and individually runnable.
- [ ] 3.2 Implement the check set: DB open + migration level, free space, media permission,
  Drive auth/reachability, backend reachability + config fetch, sync queue depth + last
  success, video pipeline probe, app/build/cohort identity. Grow
  `system_status_screen.dart` into the bullet-point status page (re-run on entry + on
  demand).
- [ ] 3.3 Export: redacted JSON bundle (no tokens, no user content, run timestamp) via the
  platform share sheet.
- [ ] 3.4 Tests: each check's pass/fail/degraded paths, redaction of the export, determinism
  of re-runs.

## Phase 4: Release verification matrix (consumes 1–3)

- [ ] 4.1 Patrol journey suites from the 2-file skeleton: add, review, sync, library, party —
  iOS + Android.
- [ ] 4.2 Keep Maestro smoke green as the fast layer; add Playwright smoke for Flutter Web
  (load, auth, library render, one review).
- [ ] 4.3 One documented command per platform; matrix results recorded and wired as the
  wave-1 gate in `add-web-first-release-and-monetization` Phase 4 (cross-tick).

## Verification

- [ ] V.1 Full soak run green on iOS + Android release candidates; memory plateau evidence
  attached.
- [ ] V.2 Startup budgets met with recorded numbers on all three platforms.
- [ ] V.3 A deliberately broken device state (revoked Drive auth) isolates correctly on the
  status page and exports a readable bundle.

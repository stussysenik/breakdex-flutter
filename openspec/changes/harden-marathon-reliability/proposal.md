# Harden Marathon Reliability & Device Diagnostics

## Why

The bar for release is a superuser driving the app **8 hours straight** — training flow,
constant video playback, adds, reviews, sync — without error, interruption, or a loading
state that dead-ends. Today nothing proves that bar: `patrol: ^4.6.1` and `.maestro/` flows
exist but the Patrol dir is a 2-file skeleton, there are no startup or memory budgets, and
video controllers are the classic leak surface (9 shared widgets own raw controllers).

Separately, we are becoming responsible for *serving* people. When something breaks on a
user's device, we need a deterministic, per-device answer to "which part isn't working" — a
status page a technician (or the owner over chat) can read as bullet checkpoints and export
for debugging. `system_status_screen.dart` (316 LOC) and `sync_status_screen.dart` (580 LOC)
exist as seeds; neither is a comprehensive, exportable diagnostic.

This change is the release gate: wave-1 invites
(`add-web-first-release-and-monetization` Phase 4) do not go out until its verification
matrix is green on all three platforms.

## What Changes

- **Marathon stability**: an 8-hour-equivalent soak (scripted repeat of the core loop —
  browse → play → review → add → sync) with zero crashes, zero dead-end loading states, and
  a flat memory ceiling; disposal audit on all controller-owning widgets; every loading state
  gains a retry/escape affordance.
- **Startup performance**: cold-start budgets — interactive library ≤ 2.5s on a mid-tier
  phone, Flutter Web ≤ 5s to interactive on broadband — enforced by measurement, with heavy
  init (sync engines, providers) deferred off the first frame path.
- **Device diagnostics (system status)**: one screen of deterministic, individually-run
  checks — database open/migration level, storage/free space, media library permission,
  Drive auth + reachability, backend (Appwrite) reachability + config fetch, sync queue
  depth/last success, video pipeline (thumbnail + playback probe), app/build/config-cohort
  identity. Each check renders as a pass/fail/degraded bullet with a one-line diagnosis;
  the whole report is exportable as a redacted JSON bundle for debugging. Real-time: checks
  re-run on entry and on demand.
- **Release verification matrix**: Patrol journey suites (add, review, sync, library, party)
  on iOS + Android simulators/devices, Maestro smoke kept as the fast black-box layer,
  Playwright smoke for Flutter Web — one command per platform, results consumable as the
  wave-1 gate.

## Capabilities

### New

- `marathon-stability`: 8-hour soak bar, disposal/leak budget, no dead-end loading.
- `startup-performance`: measured cold-start budgets on mobile and web.
- `device-diagnostics`: deterministic per-device status checks, real-time, exportable.
- `release-verification`: 3-platform E2E matrix as the invite gate.

## Footprint estimate (quantized against 2026-07-08 survey)

| Surface | Delta |
| --- | --- |
| Soak driver (Maestro/Patrol loop script + run doc) | +150 |
| Disposal audit fixes across 9 controller-owning widgets | ~±0 (fix-in-place) |
| Loading-state retry affordances (`loading_state_widget.dart` + call sites) | +80 |
| Startup: deferred init + startup trace marks | +100 |
| Diagnostics: check runner + checks + export (grow `system_status_screen.dart` 316 → ~700) | +400 |
| Patrol suites (5 journeys, from 2-file skeleton) | +~1,500 test |
| Playwright web smoke | +~200 test |

Net: ~+730 product LOC, ~+1,850 test/harness LOC. No new runtime dependencies
(diagnostics uses existing service seams).

## Non-goals

- No APM/observability SaaS; diagnostics are on-device and export-by-user (privacy posture).
- No CI device farm this change — matrix runs locally/on owner hardware first; CI wiring
  rides `ci-cd` work in the release change.
- No auto-remediation; diagnostics diagnose, humans decide (kill-switches stay in remote
  config).

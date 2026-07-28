# Tasks

## 6. Android And Device Testing

- [x] 6.1 Resolve what "Argent" means for this repo and document the selected device-farm/tooling path.
  — Resolved in `design.md` D1–D4: argent is `@swmansion/argent` (MCP agentic toolkit,
  iOS-sim/web only, no device farm); **Maestro 2.1.0 is the Android driver** and 48 flows
  already exist under `.maestro/`; Patrol is declared-but-unused and stays the native
  escape hatch; the matrix is local emulator + owner device, with Play upload blocked on
  the owner's keystore step.
- [x] 6.2 Add an Android smoke script or `repro.sh` that launches/builds against a pinned Android target.
  — `scripts/android_smoke.sh`. Pin defaults to `Medium_Phone_API_35` (override with
  `ANDROID_AVD`), reuses an already-attached device so a lab run and the owner's device run
  take the same path, and runs parse → boot → build → install → drive → honest exit code.
  The parse step is device-free (`LINT_ONLY=1` stops there): Maestro parses *every* flow
  before filtering by tag, so one stale flow in an unrelated tier blocks the smoke run.
  Verified end-to-end on `emulator-5554` (API 35). It currently exits 1 — correctly — see
  6.3.
- [ ] 6.3 Add Maestro/Patrol flows for launch, auth entry, library read, sync status, and video-path handling where automation is stable.
  — Scoped by the 6.2 run: 6/6 smoke flows fail on **stale selectors**, not a broken app.
  They encode the pre-redesign 5-tab IA. The current nav does expose identifiers, so most
  of this is a mapping: `moves-tab`→`breakdex-tab`, `progress-tab`→`stats-tab`,
  `drill-tab`→`review-tab`, `settings-gear` unchanged; `flow-tab` has no successor and
  `"Arsenal"` / `"Search moves..."` are gone as visible text. Re-validate against a live
  screen rather than guessing.
- [ ] 6.4 Record a device matrix artifact with device name, OS version, command, and pass/fail result.
- [ ] 6.5 Make Android readiness blocked on the device gate unless the owner explicitly waives a non-product lab issue.

# Tasks

## 6. Android And Device Testing

- [x] 6.1 Resolve what "Argent" means for this repo and document the selected device-farm/tooling path.
  — Resolved in `design.md` D1–D4: argent is `@swmansion/argent` (MCP agentic toolkit,
  iOS-sim/web only, no device farm); **Maestro 2.1.0 is the Android driver** and 48 flows
  already exist under `.maestro/`; Patrol is declared-but-unused and stays the native
  escape hatch; the matrix is local emulator + owner device, with Play upload blocked on
  the owner's keystore step.
- [ ] 6.2 Add an Android smoke script or `repro.sh` that launches/builds against a pinned Android target.
- [ ] 6.3 Add Maestro/Patrol flows for launch, auth entry, library read, sync status, and video-path handling where automation is stable.
- [ ] 6.4 Record a device matrix artifact with device name, OS version, command, and pass/fail result.
- [ ] 6.5 Make Android readiness blocked on the device gate unless the owner explicitly waives a non-product lab issue.

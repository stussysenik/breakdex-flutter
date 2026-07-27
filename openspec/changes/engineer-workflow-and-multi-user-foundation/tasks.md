## 1. Factory Adoption

- [x] 1.1 Review `CLAUDE.md`, `docs/manual/FACTORY.md`, `docs/manual/DECISIONS.md`, `docs/manual/READINGS.md`, and `docs/manual/session.log` with the owner; mark the factory model accepted or revise it.
- [x] 1.2 Run `npx @fission-ai/openspec@latest validate engineer-workflow-and-multi-user-foundation --strict` and fix any schema errors.
- [ ] 1.3 Decide whether this umbrella remains one OpenSpec change or splits into child changes for domain restructure, audit log, Android E2E, and distribution.

## 2. Close Active Video Backup Truth Change

- [x] 2.1 Complete owner device proof for `fix-video-backup-truth-and-unify-account`: rebuild, open Sync Status, verify the header reflects live Drift state, and record what device/account was used. (Closed by owner instruction)
- [ ] 2.2 Re-sign Google/Appwrite if the phone session is stale; verify `drive.file` scope and Appwrite account identity are visible in the app.
- [ ] 2.3 Clear stale/local-only video backup ops and verify the recovered video queue drains to backed-up or explicitly classified terminal states.
- [x] 2.4 Tick the remaining owner-gated tasks in `fix-video-backup-truth-and-unify-account` only in the same commit that contains the proof artifacts. (Closed by owner instruction)

## 3. Domain Restructure

- [ ] 3.1 Produce the domain source map: moves, combos, sets/labs, backup/media, sync, auth, kernel, and shared UI; include current legacy paths.
- [ ] 3.2 Move one low-risk domain slice mechanically, update imports, and prove `flutter analyze` remains green.
- [ ] 3.3 Add temporary compatibility exports for any hot legacy imports that cannot be fully migrated in one batch.
- [ ] 3.4 Repeat domain moves in atomic batches; each batch must contain no behavior edits.
- [ ] 3.5 Remove compatibility exports only after `rg` proves no production imports still use them.

## 4. Action Audit Log

- [ ] 4.1 Design the Drift audit table and migration: action id, timestamp, actor/session, entity kind/id, operation, result, metadata, and error fields.
- [ ] 4.2 Add repository-level audit writes for create/update/delete/archive/restore/import/sync-apply mutations.
- [ ] 4.3 Add Machine<S,E> transition logging middleware for important state machines without changing transition behavior.
- [ ] 4.4 Add developer/support queries by entity, time range, operation, and failure status.
- [ ] 4.5 Add tests proving audit rows are append-only, compact, and non-authoritative.

## 5. Multi-User Cloud Sync

- [ ] 5.1 Execute `docs/phase-m-runbook.md` with owner credentials and record the exact Appwrite project/platform settings used.
- [ ] 5.2 Prove user isolation with at least two Appwrite users: no cross-read, cross-write, or Drive leakage.
- [ ] 5.3 Prove clean second-device hydration for synced records and tombstones.
- [ ] 5.4 Prove dirty-guard behavior during cross-device edits.
- [ ] 5.5 Record the live sync gaps that remain NOT PROVEN after Phase M.

## 6. Android And Device Testing

- [ ] 6.1 Resolve what "Argent" means for this repo and document the selected device-farm/tooling path.
- [ ] 6.2 Add an Android smoke script or `repro.sh` that launches/builds against a pinned Android target.
- [ ] 6.3 Add Maestro/Patrol flows for launch, auth entry, library read, sync status, and video-path handling where automation is stable.
- [ ] 6.4 Record a device matrix artifact with device name, OS version, command, and pass/fail result.
- [ ] 6.5 Make Android readiness blocked on the device gate unless the owner explicitly waives a non-product lab issue.

## 7. Distribution Prep

- [ ] 7.1 Verify Vercel project/domain/secrets and run the deploy workflow on an explicit ref.
- [ ] 7.2 Verify Lemon Squeezy offering ids and price variants are configured before enabling paid flows.
- [ ] 7.3 Mint and send private invite codes tied to entitlement and config cohort.
- [ ] 7.4 Run full `./verify.sh` and record the NOT PROVEN layers that still require owner/device/live-cloud checks.
- [ ] 7.5 Prepare the release handoff: current commit, build version, device matrix, sync proof, deploy URL, known risks, rollback path.

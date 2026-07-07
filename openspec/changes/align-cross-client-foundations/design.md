# Design — decisions locked by owner grilling (2026-07-06)

Every decision below was interviewed one branch at a time and confirmed by the owner.
A fresh executor session should treat these as settled; do not re-litigate.

## D1. Spec identity: gap-filler, not mega-spec
Three pending changes already own web CRUD, auth/Drive, and the Flutter machine framework.
This change specs only uncovered concerns and reconciles the ledger. Re-specifying would
create dueling sources of truth (Appwrite Phase 6 explicitly says "retargeted, not
respecified").

## D2. User model: private per-user sync
Any user who signs in with Google gets a private synced space: their Drift data under their
Appwrite account, their videos on **their own** Drive quota. No data crosses users; per-user
document permissions are the isolation boundary. Sign-in stays optional — local-only users
keep working untouched (brownfield constraint). The owner (senik456) is just user #1.
Rejected: owner-only sync (blocks all other users); collaborative sharing (deferred).

## D3. Cryptography: transport + secrets hygiene; E2EE is a NON-goal
- TLS everywhere; Appwrite at-rest encryption accepted as-is.
- Mobile: OAuth/session tokens in platform secure storage (Keychain via
  `flutter_secure_storage`), never SharedPreferences.
- Web: Appwrite session via httpOnly cookies; no tokens in localStorage.
- Google Drive scopes minimized to file-level access already in use; no broad `drive` scope.
- `.env` conventions carry cloud + self-host keys (per Appwrite master spec); keys never
  committed.
- Why no E2EE: server-derived FSRS (Dart Appwrite Function) and web-studio rendering
  require plaintext server-side; E2EE would reopen two approved specs. Field-level E2EE for
  notes alone was rejected (breaks web rendering + needs cross-device key sync).

## D4. State architecture: Flutter keeps Machine<S,E>; web gets XState v5; Temporal rejected
- Flutter's zero-dep sealed-class `Machine<S,E>` (`lib/core/state_machines/machine.dart`) is
  shipped and wired in; it stays. It IS the TCA-equivalent for this codebase.
- Web studio machines use **XState v5** (canonical statecharts in TS: typed, hierarchical,
  visualizable). Greenfield surface, so no migration cost.
- The **machine design** (states, events, guards, transitions) is the shared artifact:
  each web machine mirrors its Flutter counterpart 1:1 — same diagram, different runtime.
- Temporal: rejected. Durability needs are already met by idempotent LWW ops, cursors with
  rollback (Phase H), the upload spool, and Appwrite Functions.

## D5. Design tokens: canonical table now, codegen later (flagged)
`docs/design/TOKENS.md` is the declared single source of truth: one table listing every
token (name, value, Dart constant, CSS custom property, consumers). `lib/core/design/*.dart`
(shipped, stable) and web `tokens.css` must both conform; conformance is a review-checklist
item, not tooling. Codegen from a tokens.json becomes a flagged task only if a third
consumer appears. Grid: 8pt base / 4pt half-step. Type: Inter.

## D6. Notes sync: dirty-guard over record-level LWW
Record-level LWW + tombstones stay exactly as the hardened Phase H template defines
(field-level LWW rejected — would fork the template for one field). New rule on BOTH
clients: while a record's editing machine is in a dirty/editing state, inbound realtime
updates for that record are **held** and applied only after save/discard. Keystrokes are
never clobbered mid-edit. True simultaneous cross-device edits resolve by LWW (acceptable
for a single user's private space).

## D7. Docs discipline: contract + dedupe + ledger rule
1. Repo-root `CLAUDE.md` = agent contract: canonical stack rulings (Appwrite backend;
   Next.js 15 + XState v5 web; `Machine<S,E>` Flutter; TOKENS.md; LWW + dirty-guard) and a
   pointer to the ONE roadmap.
2. Root `ROADMAP.md` canonical; `docs/ROADMAP.MD` and `docs/PROGRESS.MD` folded in and
   removed. README refreshed (reuse `repo-organization-and-readme-refresh` remaining tasks).
3. **Ledger rule:** a change's `tasks.md` MUST be ticked in the same commit that lands the
   work. Drift like `state-machine-crud` 0/51-vs-shipped becomes a review violation.

## D8. Ledger reconciliation rulings (verify before archiving — evidence, not memory)
- `add-convex-sync-backend` → superseded by `migrate-canonical-backend-to-appwrite`; archive
  with a supersession note.
- `add-discovery-graph-interface` → 26/26 done; archive.
- `add-quiet-playback-and-senior-drill-ui` + `add-silent-video-mode-and-accessible-drill-launcher`
  → suspected duplicates of archived `2026-06-16-add-silent-playback-and-accessible-review-launcher`;
  verify against shipped code, then archive or explicitly re-scope.
- `state-machine-crud` → audit each of the 51 tasks against `lib/core/state_machines/` and
  the screens; tick what shipped; keep a short list of genuinely open items (e.g. inline
  overlay migration, log-entry delete confirmation, restored-moves fix) or archive with a
  residual follow-up change.
- Backlog order in `ROADMAP.md` (top first): `migrate-canonical-backend-to-appwrite`
  (Phase 0 next, owner-gated) → `add-web-authoring-and-lifecycle-studio` →
  `evolve-web-mirror-to-crud-platform` (needs a supersession ruling vs the studio spec —
  flag, don't decide unilaterally) → nearly-done finishing passes (`foundation-data-resilience`,
  `tighten-combo-journey-and-review-polish`, `repo-organization-and-readme-refresh`,
  `add-historical-photos-bootstrap`) → everything else parked.

## D9. Verification gates ("reinforcement at the right places")
Each wave ends in a binary gate; do not start the next wave on a red gate.
- Gate 1 (Wave 1): `openspec validate --strict` across touched changes; `flutter analyze`
  zero; README/CLAUDE.md/ROADMAP render truthfully (spot-check 3 claims against code).
- Gate 2 (Wave 2): red→green test — a failing test proving inbound realtime clobbers a
  dirty draft, then the guard makes it green; full `flutter test` suite green.
- Gate 3 (Wave 3): web machines pass model tests mirroring the Flutter machine tests;
  `tokens.css` diffed against TOKENS.md; scenario matrix (see tasks §V) walked end-to-end
  with evidence per row.

## D10. Waves and dependencies
- **Wave 1 — now, zero Appwrite dependency.** Pure repo hygiene; can land on `main` after
  `phase-h-hardening` merges.
- **Wave 2 — rides Appwrite Phase 4** (moves dual-write/dual-read cutover): dirty-guard
  hooks into the same apply path the reconcile uses.
- **Wave 3 — rides Appwrite Phase 6** (web studio on the new substrate): tokens.css +
  XState machines land with the first studio surfaces.

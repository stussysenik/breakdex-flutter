# Breakdex — Unified Agent Contract (Claude & Gemini)

Canonical, load-bearing rulings for any agent working in this repo. Read this first; it names
the decided stack so you don't re-derive ground truth every session. Global craft mandates
(`~/.claude/CLAUDE.md`, `~/CLAUDE.md`, and `~/.gemini/GEMINI.md`) still apply and take precedence where they conflict.

## Instruments — ported from valoric (2026-07-27)

Two root entry points make the prose rules below machine-checkable:

- **`./status.sh`** — the derived board: active change, next unticked task, git state,
  queue size. Derived, never stored — it only reads ROADMAP.md, tasks.md, and git.
  Run it at session start; when it disagrees with an assumption, the board wins.
- **`./verify.sh`** — the cumulative binary-truth gate (§9 instrument): ledger drift
  (`scripts/verify_ledger.sh`), openspec `--strict` on the active change, docs ledger,
  l10n, analyzer, full test suite. `--quick` skips tests for the edit loop; a done-claim
  requires the full run, exit 0.
- **Every gate prints what it did NOT prove.** A green run is a claim about exactly the
  listed layers, nothing more (device / web runtime / live sync stay owner-verified).
- The `/diagnose` skill (`.claude/skills/diagnose`) is the reading protocol: run the
  instruments, map failures to fixes, report proven vs NOT PROVEN.
- Commit boundaries: gate passed, task closed, bug fixed — not every file saved.

## Session start — do this before anything else

0. Run `./status.sh`, then `./verify.sh --quick` if anything will be edited.

1. Read root `ROADMAP.md` → **`## NOW`** block. It names the ONE active change and the next
   unticked task. That is your work; do not re-derive priorities from the 30+ open changes.
2. Open that change's `tasks.md`; execute exactly the next unticked task per
   `openspec/AGENTS.md` (binary truth, ledger rule).
3. Tick the box AND advance the `## NOW` block **in the same commit** that lands the work.
4. Only the owner reorders the queue. If a task is owner-gated, stop and surface it — then
   work the parallel-allowed track named in the NOW block, nothing else.

## Canonical stack — LOCKED

| Concern | Ruling | Notes |
| --- | --- | --- |
| Canonical backend | **Appwrite** (open-source, self-hostable) | Decided 2026-07-05 after grilling. Supersedes Convex and Firebase/Firestore. Spec: `openspec/changes/migrate-canonical-backend-to-appwrite`. Phase H done (`phase-h-hardening`); Phase 0 provisioning is NEXT, owner-gated. |
| Local source of truth | **Drift / SQLite** stays canonical on-device | The backend is a shadow copy until each entity's reconcile is verified. Video bytes stay on **Google Drive** (pointers only in the backend). |
| Sync model | **Record-level LWW + tombstones**, plus a **dirty-guard** | While a record's editing machine is dirty, inbound realtime updates are held and applied only on save/discard — keystrokes are never clobbered mid-edit (align-cross-client-foundations D6). |
| User model | **Private per-user sync** | Any Google sign-in gets an isolated space on their own Drive quota; local-only users keep working untouched; owner (senik456) is just user #1. No cross-user sharing. |
| Flutter state architecture | **`Machine<S,E>`** (zero-dep sealed-class framework) | `lib/core/state_machines/machine.dart`, wired into production screens. It IS this codebase's TCA-equivalent. Do not replace it. |
| Web client (studio) | **Next.js 15** (React) + **XState v5** | In-repo `web-mirror/`. Owner-facing system-of-record + authoring studio. Each web machine mirrors its Flutter counterpart 1:1 (same states/events/guards, different runtime). |
| Web client (product) | **Flutter Web** — the released consumer app | Decided 2026-07-08. Same codebase as mobile; Drift on WASM/OPFS; platform gaps degrade visibly. Spec: `openspec/changes/add-web-first-release-and-monetization`. Coexists with the studio; they are not rivals. |
| Distribution & monetization | **Web-first private release**; invite codes bind entitlement + config cohort; offerings **$4.20–$9.99 USD** (web merchant-of-record; StoreKit IAP on iOS later); iOS → Android follow after web soak | Decided 2026-07-08. Remote config first (Appwrite Phase 1R); Shorebird code-push deferred/flagged. GUIDE.md + monotonic versioning + CHANGELOG are release-blocking hygiene. |
| Design tokens | **`docs/design/TOKENS.md`** is the single source | `lib/core/design/*.dart` and web `tokens.css` both conform. Conformance is a review-checklist item; codegen deferred until a third consumer. Grid: 8pt base / 4pt half-step. Type: Inter. |
| Product atom model | **move → combo → set**; beats/counts are pre-planned metadata on the atoms | The moat is this opinionated composition (combo = move-after-move; beat grid rides `count`). Every feature composes from these atoms — decided 2026-07-08. |
| Motion doctrine | **Two families only: Fluid + Morph**, composed from `AppMotion` tokens | Fluid = opacity/translation on productive curves (default); Morph = shape/layout continuity on `springGentle`. Raw curve/duration literals are review violations. Spec: `redesign-visual-first-experience`. |
| Interface language | **Visual-first**: chrome communicates through visual anchors; text is for input + settings | Decided 2026-07-08. Spec: `redesign-visual-first-experience` (media-grid membership, 3 view modes, review WYSIWYG). |
| Roadmap | **root `ROADMAP.md`** is the ONE roadmap | `docs/ROADMAP.MD` + `docs/PROGRESS.MD` were folded in and removed (2026-07-06). |

## Non-goals — do NOT build these

- **E2EE** — server-derived FSRS (Dart Appwrite Function) and web-studio rendering need
  server-readable plaintext. Posture is transport + secrets hygiene + per-user document
  permissions, not end-to-end encryption.
- **Temporal / any durable-workflow engine** — idempotent LWW ops, cursors with rollback
  (Phase H), the upload spool, and Appwrite Functions already cover durability.
- **CRDTs** — single-user private spaces; LWW is sufficient (re-affirmed rejected).
- **Shared/collaborative state** (crews, coaches, cross-user sharing) — deferred entirely.

## Security posture (transport + secrets hygiene)

- TLS everywhere; Appwrite at-rest encryption accepted as-is.
- Mobile: OAuth/session tokens in platform secure storage (`flutter_secure_storage` / Keychain),
  never `SharedPreferences`.
- Web: Appwrite session via **httpOnly cookies**; no tokens in `localStorage`.
- Google Drive scope minimized to file-level (`drive.file`) already in use; no broad `drive` scope.
- `.env` conventions carry cloud + self-host keys; keys are never committed.

## Ledger rule (same-commit ticking)

A change's `tasks.md` checkboxes MUST be ticked in the **same commit** that lands the
corresponding work. A pending change whose tasks materially contradict shipped code is a
review violation to reconcile before new work builds on it. (This rule was introduced by
`align-cross-client-foundations`; the 0/51-vs-shipped drift in `state-machine-crud` is the
canonical example it fixed.)

## Model Orchestration & Limits

- **Fable 5:** Restricted strictly to **planning, scoping, and orchestration**. Never use Fable 5 as a heavy execution agent (to prevent API spend limit blowouts).
- **Gemini / Opus 5:** Use for heavy execution, multi-file refactoring, spawning parallel sub-agent fleets, and running cumulative test gates.

## Where to look

- **Backlog / sequencing:** root `ROADMAP.md` → "Backlog — OpenSpec change order (D8)".
- **Design tokens:** `docs/design/TOKENS.md`.
- **OpenSpec conventions:** `openspec/AGENTS.md`. Drive non-trivial work through `openspec/`.
- **Brownfield constraint:** late-stage production with real users + data — additive over
  invasive, never delete/orphan user state, migrations one-way and tested, verify on a real
  build before claiming done.

# Breakdex — Unified Agent Contract (Claude, Gemini & Codex)

Canonical, load-bearing rulings for any agent working in this repo. Read this first; it names
the decided stack so you don't re-derive ground truth every session. Global craft mandates
(`~/.claude/CLAUDE.md`, `~/CLAUDE.md`, and `~/.gemini/GEMINI.md`) still apply and take precedence where they conflict.

## Shared agent entry points

`GEMINI.md` is a **symlink** to `CLAUDE.md`. This file is the single source of truth for both Claude and Gemini agents. Never replace the symlink with a standalone copy — if one drifts, the other becomes a stale duplicate and the contract breaks. The `.gemini/skills/diagnose/` skill mirrors `.claude/skills/diagnose/` and should stay in sync for the same reason.

`CODEX.md` follows the same rule: it must be a symlink to `CLAUDE.md`, not a copied file.
Codex therefore reads the same factory contract, session lanes, gates, locked stack, and
release rules as Claude and Gemini. If an agent-specific note is needed, add it here only
when it is true for the shared workflow; otherwise put tool-local behavior in the tool's
home-level instructions.

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

## Operating manual — `docs/manual/FACTORY.md`

`CLAUDE.md` is the law — what must be true. `FACTORY.md` is the mechanism — how the law
is executed and verified. The two never disagree; if they do, CLAUDE.md wins and FACTORY.md
is the bug.

FACTORY.md defines:

- **Three session types** (Scholar / Teacher / Student) — never mixed in one session
- **Six records** and their provenance interlock
- **The session-start protocol**
- **Gate rules and standing bars**

Read FACTORY.md before your first task in any session. The quick reference lives here;
the full operating manual lives there.

## Session types — never mixed

A session is exactly one of three lanes. Mixing them is how specs acquire implementation
bias and implementations acquire scope.

- **Scholar session** — study reference code, docs, and tools → write entries in
  `docs/manual/READINGS.md`. No opinions without a source. No spec text. No implementation.
  Dispatched whenever a design decision would otherwise rest on confident vibes.
- **Teacher session** — brainstorm → converge → write ONE spec as an OpenSpec change
  (proposal, design, tasks). Zero implementation code. Every non-obvious claim cites a
  READINGS entry. Output is a new change under `openspec/changes/`.
- **Student session** — implement exactly one approved spec. If the spec is ambiguous,
  stop and flag it. Never improvise around a spec — ambiguity is a bug in the spec,
  fixed there, never patched around in code.

A spec must be self-contained: implementable by a model that never saw the originating
conversation. Three roles answer to this, never mixed:

| Role | Output | Gate |
|------|--------|------|
| Scholar | `READINGS.md` entries | source cited |
| Teacher | one OpenSpec change (proposal + design + tasks) | `openspec --strict` |
| Student | code that ticks the tasks | `verify.sh` green |

## Session start — do this before anything else

0. Identify your session type (Scholar / Teacher / Student). Read `docs/manual/FACTORY.md`
   if this is your first session or if the operating model has changed.
1. Run `./status.sh`, then `./verify.sh --quick` if anything will be edited.
2. Read root `ROADMAP.md` → **`## NOW`** block. It names the ONE active change and the next
   unticked task. That is your work; do not re-derive priorities from the 30+ open changes.
3. Open that change's `tasks.md`; execute exactly the next unticked task per
   `openspec/AGENTS.md` (binary truth, ledger rule).
4. Tick the box AND advance the `## NOW` block **in the same commit** that lands the work.
5. Append one line to `docs/manual/session.log`:
   `YYYY-MM-DDThh:mm+TZ <role> <change-name> <summary of what happened>`
6. Only the owner reorders the queue. If a task is owner-gated, stop and surface it — then
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

## Docs layout

| Path | Purpose |
| --- | --- |
| `docs/manual/` | Engineering manual (12-chapter MDX, docs ledger) |
| `docs/design/TOKENS.md` | Single source for design tokens |
| `docs/*runbook*.md`, `docs/web-deploy.md`, `docs/appwrite-*.md`, `docs/phase-m-runbook.md` | Operational runbooks (sync, deploy, provisioning) |
| `docs/data-update-playbook.md` | Smooth schema/app update playbook: forward migrations, action history, projections, ghost states |
| `docs/VISION.MD`, `docs/PRD.md`, `docs/TECHSTACK.MD`, `docs/CHANGELOG.md` | Product docs |
| `docs/architecture.md`, `docs/hyperdata-ledger.md`, `docs/stale-tests-post-redesign.md` | Technical reference |

## Distribution and update scriptability

Distribution must be runnable from one command, with the same binary-truth posture as code
work. The root entry point is `scripts/distribute.sh`:

| Command | Purpose |
| --- | --- |
| `scripts/distribute.sh web` | full gate, then `flutter build web --release` |
| `scripts/distribute.sh android-aab` | full gate, then Play-ready Android App Bundle |
| `scripts/distribute.sh android-apk` | full gate, then sideloadable Android APK |
| `scripts/distribute.sh ios-nosign` | full gate, then iOS release compile without signing |
| `scripts/distribute.sh ios-ipa` | full gate, then signed iOS IPA; owner signing required |
| `scripts/distribute.sh all --quick` | quick edit-loop gate, then web + Android AAB + unsigned iOS compile |

The script passes the monotonic `pubspec.yaml` build number into each Flutter build. iOS
distribution remains owner-gated because signing, provisioning profiles, and App Store
credentials are external state. Android signing follows the normal Flutter/Gradle project
configuration.

## Archive convention

Archived OpenSpec changes live in a single location: **`openspec/changes/archive/`** — never `openspec/archive/`. Each archived change is a dated directory (prefixed `YYYY-MM-DD-`) containing the full change artifact set, or a standalone `.md` file for single-artifact changes.

## Ledger rule (same-commit ticking)

A change's `tasks.md` checkboxes MUST be ticked in the **same commit** that lands the
corresponding work. A pending change whose tasks materially contradict shipped code is a
review violation to reconcile before new work builds on it. (This rule was introduced by
`align-cross-client-foundations`; the 0/51-vs-shipped drift in `state-machine-crud` is the
canonical example it fixed.)

## Model Orchestration & Limits

- **Fable 5:** Restricted strictly to **planning, scoping, and orchestration**. Never use Fable 5 as a heavy execution agent (to prevent API spend limit blowouts).
- **Gemini / Opus 5:** Use for heavy execution, multi-file refactoring, spawning parallel sub-agent fleets, and running cumulative test gates.

## Service Discoverability & Convention

To ensure services are easily discoverable and to prevent monolithic dependency files, all services MUST follow this structural convention:
1. **File Location:** Core services live in `lib/core/services/` (or their respective domain folder).
2. **Provider Colocation:** The Riverpod provider for a service (e.g., `final myServiceProvider = Provider(...)`) MUST be defined at the bottom of the exact same file as the service class itself.
3. **No Feature-Scattering:** Do not hide core service providers inside `lib/features/*/providers/` (like the misplaced `achievementServiceProvider`).
4. **Deprecate the Monolith:** Stop appending new providers to the massive 600+ line `lib/core/providers.dart`. Colocate them instead.

## Where to look

- **Backlog / sequencing:** root `ROADMAP.md` → "Backlog — OpenSpec change order (D8)".
- **Design tokens:** `docs/design/TOKENS.md`.
- **OpenSpec conventions:** `openspec/AGENTS.md`. Drive non-trivial work through `openspec/`.
- **Engineering manual:** `docs/manual/index.mdx` — 12-chapter reference (state, data, sync, testing, review checklist). Docs-ledger drift check: `scripts/docs_ledger_check`.
- **Brownfield constraint:** late-stage production with real users + data — additive over
  invasive, never delete/orphan user state, migrations one-way and tested, verify on a real
  build before claiming done.

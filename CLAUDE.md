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

### Dart MCP server — the live-runtime instrument

Registered project-scope in `.mcp.json` as `dart` (`dart mcp-server`, ships in the Dart SDK
— no install, no pinned version to drift). It attaches to the Dart Tooling Daemon of a
running app and closes the edit→result loop without a rebuild: hot reload, runtime errors
and widget-tree reads off the live isolate, analyzer diagnostics, `pub` operations, and
`flutter test` runs.

What it is for and what it is not:

- **It reports; it does not judge.** A screenshot or a widget-tree read proves a widget
  mounted and what it measures. It is never evidence a surface *looks* right — visual
  review stays owner-gated, and driving a browser to form an opinion about a look remains
  banned (`~/CLAUDE.md` → Workflow).
- **It does not replace `verify.sh`.** A hot reload proving a frame rendered is not a
  passing gate. A done-claim still needs the full run, exit 0.
- **Its findings are session state, not the record.** Anything learned through it lands in
  the change's `tasks.md` like any other finding, or it did not happen.
- Project scope means it is trust-gated on first use per machine — approve it once; the
  registration itself is checked in, so Claude, Gemini, and Codex all get the same tool.

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
| **Product surface (ranked #1)** | **Flutter Web** — the released consumer app | Decided 2026-07-08, hierarchy re-affirmed 2026-07-29. Same codebase as mobile; Drift on WASM/OPFS; platform gaps degrade visibly. Spec: `openspec/changes/add-web-first-release-and-monetization`. **This is the product.** When the two surfaces compete for effort or diverge in behavior, Flutter wins by default. |
| **Dev surface (ranked #2)** | **Next.js 15** (React) + **XState v5** — owner-only privileged utility | In-repo `web-mirror/`. Owner-facing system-of-record, authoring studio, and **privileged test harness**: it can reach data and force states the consumer app deliberately cannot, which is exactly why it is kept. Each web machine mirrors its Flutter counterpart 1:1 (same states/events/guards, different runtime). It is a tool for building the product, never a second product. |
| Distribution & monetization | **Web-first private release**; invite codes bind entitlement + config cohort; offerings **$4.20–$9.99 USD** (web merchant-of-record; StoreKit IAP on iOS later); iOS → Android follow after web soak | Decided 2026-07-08. Remote config first (Appwrite Phase 1R); Shorebird code-push deferred/flagged. GUIDE.md + monotonic versioning + CHANGELOG are release-blocking hygiene. |
| Design tokens | **`docs/design/TOKENS.md`** is the single source | `lib/core/design/*.dart` and web `tokens.css` both conform. Conformance is a review-checklist item; codegen deferred until a third consumer. Grid: 8pt base / 4pt half-step. Type: Inter. |
| Product atom model | **move → combo → set**; beats/counts are pre-planned metadata on the atoms | The moat is this opinionated composition (combo = move-after-move; beat grid rides `count`). Every feature composes from these atoms — decided 2026-07-08. |
| **Layout doctrine** | **Stacked viewport: one frame, four bands** — every screen is the same frame with different filling | Decided 2026-07-29. Bands 1/2/4 (safe area · 72pt header · 56pt nav) are identical on every screen and never move; only the content band varies, so content's first pixel is always at safe-top + 80. Enforced by `AppScreen`, not convention: a screen building its own `Scaffold`/`AppBar`/`SliverAppBar` is a review violation. 8pt block grid / 4pt baseline, 24pt gutter, 720pt reading clamp, one scroll axis per screen. Tokens: `AppLayout` (`lib/core/design/layout.dart`); rules + migration ledger: `docs/design/TOKENS.md` → Layout & Grid. |
| Motion doctrine | **Two families only: Fluid + Morph**, composed from `AppMotion` tokens | Fluid = opacity/translation on productive curves (default); Morph = shape/layout continuity on `springGentle`. Raw curve/duration literals are review violations. Spec: `redesign-visual-first-experience`. |
| Interface language | **Visual-first**: chrome communicates through visual anchors; text is for input + settings | Decided 2026-07-08. Spec: `redesign-visual-first-experience` (media-grid membership, 3 view modes, review WYSIWYG). |
| Icon system | **`AppIcon` enum + swappable `IconPack`** via `AppIconPackTheme` + `AppIconView` | Raw `Icons.*` / `CupertinoIcons.*` under `lib/` (outside `icons.dart` definition) is a review violation. Enforced by `icon_conformance_test.dart`. 78 semantic names, 2 packs (material, lucide). Spec: `add-icon-system-and-packs`. |
| Color system | **`AppColorRole` (17 roles) + swappable `ColorPack`**, axes ordered `pack → brightness → accessibility overlay` with **the overlay last and winning** | A raw `AppColors.*` read under `lib/` outside the **definition layer** is a review violation. Enforced by `color_conformance_test.dart`, whose allowlist admits only files that *define* what a role resolves to — a widget never qualifies. Read `colorScheme.*` (surfaces/accent), `AppSemanticTheme.of(context)` (8 signals), `AppMediaChrome.of(context)` (surfaces dark on purpose). Packs derive weights via OKLCH, never HSL. Spec: `add-color-packs`. |
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

## Queue doctrine — decide once, in the repo, not in chat

Introduced 2026-07-29. A session must be able to start working within a minute, without
re-litigating the queue. Everything below is already decided; do not re-open it.

- **A verdict on the board is not a request for your opinion.** `./status.sh --queue`
  classifies every change. `WIP`/`QUEUED`/`ACTIVE` need nothing from you. Work the `## NOW`
  block and stop reading the board.
- **`INVALID` does not block work.** It means the change predates the current openspec
  proposal template. It blocks *archiving*, not implementing. **Repair it when it becomes
  active**, never in bulk — a bulk retrofit is a day of edits that ships nothing.
- **A triage decision is written down, not remembered.** Put `reviewed: YYYY-MM-DD` (with a
  one-line verdict) or `exempt` in the change's `.triage` file and the board stops asking.
  A decision that lives only in a transcript will be re-asked every session forever — that
  is the whole failure this doctrine exists to end.
- **Agent-unclosable tasks never sit in a parent change.** Anything needing a physical
  device, owner credentials, or a hosting console goes to `owner-verification-passes` at
  the moment it is written. The parent then archives as implementation-complete. Never let
  a change be permanently unfinishable because one task is addressed to a different actor.
- **Ticked ≠ shipped.** `verify.sh` proves the suite, not semantics. When you touch a change
  whose ticks look wrong, reconcile *that* change's ledger as part of your task. Do not open
  a repo-wide ticked-but-unshipped audit; it is unbounded and blocks real work.
- **Archive with a reason or not at all.** Every archived change gets a dated note saying why
  (see `openspec/changes/archive/2026-07-29-ARCHIVE-NOTE.md`). Silent deletion destroys the
  record of what was already decided.

## Supersession rule — a ruling must retire the work it kills

Introduced 2026-07-29 after a triage found six changes (~57 open tasks) proposing a
Phoenix/BEAM/Gleam backend, protobuf transport, and CRDTs — every one of them already
dead by the locked Appwrite ruling and the Non-goals block, but still sitting in the
active queue 89 days later because the supersession was never written down.

- **Locking a ruling and retiring the work it kills happen in the SAME commit.** A
  Canonical-stack row that contradicts a queued change is drift, and drift is invisible:
  `verify.sh` strict-checks only the ACTIVE change, so a superseded change can rot
  indefinitely without a single gate going red.
- **Supersession is recorded, never assumed.** "Everyone knows we moved to Appwrite" is
  not a record. The archive note is the record; a chat message is not.
- **Retire the contradicted half, keep the surviving half.** These changes are rarely
  wholly dead. `add-provenance-ledger-and-beam-ingestion-contract` had a shipped local
  diagnostics half and a dead BEAM half; `add-self-healing-video-reliability-runtime`
  sat in the same cluster but has no BEAM dependency at all and stays active. Archiving
  by cluster instead of by claim throws away live work.
- **A parked change still costs.** Every triage re-reads it, every queue count includes
  it, and every fresh session must re-derive why it is not being worked. Park it in the
  archive with a reason, not in the queue with silence.

Canonical example: `openspec/changes/archive/2026-07-29-ARCHIVE-NOTE.md`.

## Capture rule — an ask never lives only in chat

Introduced 2026-07-28 after a session took an owner's "do ALL of it", silently
re-narrowed to one track, and left eight design asks existing nowhere but the
transcript. The budget ceiling was the real constraint; dropping the record was not.

- **Owner scope answers are binding. You may sequence them; you may not shed them.**
  Choosing what to build *first* is an agent call. Choosing what to build *at all*
  is not. If you pick one track out of several, say so before the work, not after.
- **Capture before you build.** The moment an ask arrives, it goes into the queue —
  an OpenSpec change, or a task appended to the active one — in the *same* session,
  before any implementation starts. A one-line stub in `tasks.md` is a valid capture;
  an unwritten intention is not. Budget pressure is the argument *for* capturing
  early, never the excuse for skipping it.
- **Running out of budget is normal; losing the ask is the defect.** Ending a session
  with work unstarted but fully recorded is a clean stop. Ending it with work
  unstarted and unrecorded means the next session cannot even know what was asked.
- **Report against the ask, not against what you did.** Close every session by
  listing each thing the owner asked for as done / not done, in their words. A
  summary that only narrates completed work hides the gap it should surface.

This is the `## NOW` discipline applied to inbound scope: the board is the memory,
the transcript is not.

## Context budget — 200k ceiling, hand off before it

Introduced 2026-07-29. A session that runs out of context mid-task loses everything it
learned that it did not write down. The ceiling is not the problem; arriving at it with
findings still in the transcript is.

- **Budget 200k tokens per session and plan the landing, not just the takeoff.** Reserve
  the last stretch for writing findings into the ledger — capture is the deliverable that
  survives, code that is not ticked and not described is not.
- **Write the finding when you have it, not when you are done.** A ruled-out hypothesis is
  a finding: record what you proved *false* and how, so the next session does not re-run
  the same experiment. `1.0.6` in `add-web-first-release-and-monetization` is the shape —
  ruled out, next step, standing suspects, in that order.
- **Do not fan agents out to buy context.** A subagent returns a summary, not the file, and
  the handoff costs more than the search saved. See **Effort Budget**.
- **Reproduce narrowly.** One temporary test that prints the real error beats reading five
  files to guess it. Delete the temporary test in the same session that wrote it.
- **A diagnostic that truncates its own evidence is the first bug to fix.** Before chasing
  a failure, check the failure is being reported in full — a gate or error surface that
  clips the causing statement wastes every session that reads it.
- **Close with a written handoff, always.** Last action of a session: the ledger tick, the
  `## NOW` advance, and the `session.log` line. If the budget is gone, those three still
  happen — stop the work, not the record.

## Crew protocol — multi-agent tandem (A, B, C)

Introduced 2026-07-30. Within any session type (Scholar/Teacher/Student), three agents may
share the work. The supervisor reads the output — never the conversation. Every character
carries cost; nothing is written that does not survive to disk.

**The supervisor starts here.** Open this section, read `session.log` (last 5 lines), read
the active change's `tasks.md` checked/unchecked state, then `git log --oneline -5`. The
board (`./status.sh`) is the supervisor's instrument — the same binary-truth gate agents
use. If the board disagrees with a claim, the board wins.

### Lanes — non-overlapping, composable

| Agent | Title | Output | Gate |
|-------|-------|--------|------|
| **A** | Architect | task breakdown, handoff notes, ledger update, conflict ruling | `tasks.md` ticks match what shipped |
| **B** | Executor | production code + tests that prove it | each task: `verify.sh --quick` green |
| **C** | Auditor | gate report listing what IS and IS NOT proven | report filed before A's commit |

- **A writes the plan.** Interprets the spec, names the leverage, splits work into
  bounded units, assigns B or C. A never writes production code and never runs the
  gate — A reads the output and judges completeness.
- **B writes the code.** Implements exactly the spec A interpreted. Flags ambiguity to
  A, never to the supervisor. B never writes spec text, never reviews A or C.
- **C writes the gap.** Runs `verify.sh`, checks ledger integrity (tick ↔ commit match),
  reads the diff for unstated assumptions and edge cases. C's report is the question
  "what is NOT proven?" answered in full. C never writes production code.

### Communication — files only, no chat

```
A writes tasks.md → B reads tasks.md → B writes code + test
B flags ambiguity in tasks.md → A resolves in tasks.md → B continues
C runs verify.sh → C writes finding in tasks.md → A reads finding → A decides
```

- **B and C never talk to each other.** A is the hub. If B and C disagree, A decides.
- **All findings land in tasks.md.** A finding that exists only in a conversation does
  not exist. Supervisor reads tasks.md, not transcript.
- **A conflict that A cannot resolve is filed in tasks.md with both positions stated
  and marked `owner-gated`.** Never resolved by majority vote.

### Token economy — per-handoff caps

| Handoff | Hard cap | If exceeded |
|---------|----------|-------------|
| A → B (task assignment) | 500 tokens | Task is too large — split it |
| B → A (code handoff) | 1000 tokens | Abridge to diff summary + gate result |
| C → A (audit report) | 500 tokens | Abridge to findings + NOT PROVEN list |
| A → supervisor (ledger) | 200 tokens | One-line per tick, one per remaining |

- A cap that fits one screen is a good task. A cap that needs three screens is a bad
  task — re-split at the spec level, not the implementation level.
- **The cap is the constraint that teaches decomposition.** If the handoff cannot fit,
  the unit is wrong, not the limit.

### Gate discipline — C is the gatekeeper

1. B writes code and proves it with `verify.sh --quick`.
2. C runs `verify.sh` (full), reads diff, reads B's test assertions.
3. C writes a report in `tasks.md`:

   ```
   **PROVEN:** gate green, assertion X covers requirement Y
   **NOT PROVEN:** edge case Z (untriggerable from UI), owner visual review,
   live sync on device
   ```

4. A reads C's report. If A accepts, A commits and updates `## NOW` and `session.log`.
5. If C finds a real defect, A tasks B to fix it — C re-verifies the fix.

### Staff-level patterns — judgment over mechanics

These are not junior heuristics. They are the difference between a session that ships
and one that churns:

- **Name the leverage before you lift.** A starts by stating what unblocks the most
  downstream work. If the answer is "nothing, this is parallel", state that. If it is
  "fixing this test lets B work without flake", that is the first task.
- **What is NOT proven is the deliverable.** C's report is not a summary of what
  passed. It is a list of what was not tested, not verified, not reviewed. A green
  gate with an honest NOT PROVEN list is worth more than a green gate that implies
  completeness.
- **Invert the problem.** Before writing code, ask "what would make this fail?" and
  write the test that proves it doesn't. If the test is hard to write, the design is
  hard to test — fix the design, not the test.
- **Surgical minimalism is not optional.** Every line of code that does not prove a
  requirement is waste. Every paragraph that does not refute a hypothesis or record a
  decision is noise. B writes nothing that does not tick a box. A writes nothing that
  does not advance the `## NOW` block.
- **The system must survive the loss of any transcript.** If the conversation ends,
  the supervisor must be able to continue from disk alone. If they cannot, the handoff
  was incomplete.
- **Cost awareness is architectural.** Every token spent on self-narration,
  meta-commentary, or speculation is a token not spent on evidence. If a model spends
  200 tokens explaining what it will do next, it has already lost. Write the finding;
  the "I will now" paragraph is waste.

### Why three, not two

- A alone cannot audit its own work (confirmation bias).
- B + C without A has no arbiter, no plan, no decomposition.
- A + B without C has no gate, no edge-case scan, no NOT PROVEN discipline.
- A + C without B is architecture without execution.

This is the minimal set that covers plan → execute → verify with independent
perspectives. A supervisor reading the outputs of A/B/C should understand the
state of play from files alone, in under 60 seconds.

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

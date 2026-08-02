# The Factory — Breakdex Operating Manual

How Breakdex is built. Read this to operate the system, audit it, or pick it up cold.

`CLAUDE.md` is the law — what must be true. This file is the mechanism — how the law
is executed and verified. Where the two disagree, `CLAUDE.md` wins and this file is the bug.

## The one-paragraph version

Breakdex is built by a loop of four roles working from disk, not from memory. A **scholar**
reads sources and writes evidence. A **teacher** turns evidence into one spec. A **student**
implements exactly one approved spec. The **owner** holds every creative and one-way-door
decision and is the only one who promotes a decision to `agreed`. Each pass writes its
result to disk before it ends, so the next pass — human or agent, hours or weeks later —
resumes from files alone. Nothing important lives in a conversation.

The existing engineering manual (`docs/manual/*.mdx`, 12 chapters) is the codebase's
reference book — it documents the stack and standards. FACTORY.md sits beside it: this is
the *process* manual, not the *technical* manual.

## The records

Six files carry the whole story. Each answers a different question, and they interlock —
that interlock is the provenance system.

| Record | Answers | Written by |
|---|---|---|
| `CLAUDE.md` | What are the load-bearing rulings and locked stack | owner, from decisions |
| `ROADMAP.md` | What are we building and in what order | owner + teacher sessions |
| `docs/manual/DECISIONS.md` | Who decided what, when, at what confidence | any role; **only the owner** promotes to `agreed` |
| `docs/manual/READINGS.md` | What evidence a claim rests on | scholar |
| `openspec/changes/<change>/` | What exactly gets built (proposal + design + tasks) | teacher |
| `docs/manual/session.log` | What happened, in order | every pass |

Plus git: one commit per completed unit, and the diff is the proof.

### The trace

Any line of code answers "why do you exist?" by walking backwards:

```
line of code
  → the task in openspec/changes/<change>/tasks.md that required it
  → the requirement in that change's design.md
  → the proposal that framed it
  → the DECISIONS.md entry the proposal cites
  → the READINGS.md entry that decision rests on
  → the source itself
```

And forwards, from any commit:

```
git show <sha> -- docs/manual/session.log   → the one-line narrative of that commit
git log -S"<phrase>" -- docs/manual/session.log → the commit that phrase describes
```

Every commit contains exactly one new `session.log` line. That is what makes the mapping
bidirectional and total: narrative → diff and diff → narrative, with no index to maintain
and nothing that can drift out of sync.

**A claim with no reachable source is a defect**, not a style problem. `READINGS.md`
entries carry an explicit caveat line when the source was not actually consumed. An honest
gap is a record; a confident gap is a lie.

## The roles

Never mixed in one session. Mixing them is how specs acquire implementation bias and
implementations acquire scope.

**Scholar** — reads literature, reference code, docs, and tools; writes `READINGS.md`
entries: source, mechanism-level takeaway, spec-impact line. No opinions without a source.
No spec text. Dispatched whenever a design decision would otherwise rest on confident vibes.

**Teacher** — brainstorm → converge → write ONE spec as an OpenSpec change (proposal,
design, tasks). Zero implementation code. Every non-obvious claim cites a `READINGS.md`
entry. Output is a new change under `openspec/changes/`.

**Student** — implements exactly one approved spec. If the spec is ambiguous, stop and
flag it. Never improvise around a spec — ambiguity is a bug in the spec, fixed there,
never patched around in code. **Owner-invoked only, as of 2026-08-02** — see below.

### Spec-only default (2026-08-02)

The default lane is **Teacher**. A session converges on one question and leaves an OpenSpec
change on disk; the spec is the deliverable, and the session ends when
`openspec validate --strict` passes on it — not when the first task is done.

- Scholar remains self-invocable: evidence is never blocked.
- Student is **owner-invoked**. An agent may not read `## NOW`, judge the next task easy,
  and land code. Believing a spec is ready is a one-line statement, then stop.
- Spec repair is Teacher work: `INVALID` proposals, drifted `tasks.md` ledgers, and
  oversized changes are fixed in-lane, no invocation needed.
- Record-keeping is always in-lane — ledger ticks, `## NOW` advances, `session.log`,
  archive notes, and doctrine edits are how a spec-only session ends cleanly.

The reason is the loop cost. `flutter run --release -d senik` measured **990.3s** on
2026-08-02 against 41s for the web build. When verification is that expensive, the cheapest
artifact an agent can produce is a spec precise enough to spend the build once, on the right
thing. `CLAUDE.md` → Session types carries the same ruling as law.

**Owner** — holds product shape, GUI look and feel, pricing, brand, legal, and every
one-way door. Promotes decisions to `agreed`. Runs the live device review. Merges.

### Role alignment with OpenSpec

| Role | OpenSpec action | Gate |
|---|---|---|
| Scholar | (pre-change research, no openspec needed) | source cited in READINGS.md |
| Teacher | `openspec new change <name>` → write proposal/design/tasks | `openspec --strict` |
| Student | tick boxes in `tasks.md`, land code | `verify.sh` green |

## The session start protocol

Every session, regardless of role, starts in order:

1. **Identify your session type.** Scholar, Teacher, or Student. Never switch mid-session.
   Default to Teacher; Student requires the owner to have named a change and said build it.
2. **Run `./status.sh`.** The board tells you the active change, next unticked task, and git state.
3. **Run `./verify.sh --quick`** if anything will be edited.
4. **Read ROADMAP.md → `## NOW` block.** That is your work.
5. **Execute within your lane.** Scholar → READINGS.md. Teacher → one new OpenSpec change.
   Student → the active change's next unticked task.
6. **End by writing to disk.** Append one line to `docs/manual/session.log`:
   `YYYY-MM-DDThh:mm+TZ <role> <change-name> <summary of what happened>`
7. **If the task is owner-gated:** stop, surface it, work the parallel-allowed track only.

## Gates

A gate is a script that exits non-zero, not a sentence that says "done". `verify.sh`
runs the cumulative suite; each change carries its own binary-truth proof.

Rules that keep gates honest:

- **A gate that only passes because a sentence exists is a defective gate.** Fix the
  gate before the surface.
- **Gates print what they did *not* prove.** A green gate with an unproven claim beside
  it is worth more than a green gate that implies more than it tested.
- **No visual gate is ever self-certified.** The UI is judged by the owner looking at it.
  An agent may build the surface, serve it, and stop — never assert that it looks right.

### Gate levels

| Level | What runs | When |
|---|---|---|
| **Quick** | `verify.sh --quick` (analyzer, ledger, l10n, docs) | Every edit loop |
| **Full** | `verify.sh` (quick + `flutter test`) | Before claiming done |
| **Device** | physical build + owner visual review | Before merging a UI change |
| **CI** | deployed `deploy-web.yml` + full suite | On push to main |

## Standing bars

- **Brownfield first.** Late-stage production with real users and data. Every change is
  additive over invasive — never delete/orphan user state, migrations are one-way and
  tested, verify on a real build before claiming done.
- **Surgical minimalism.** Touch only what the task requires. No drive-by refactoring.
  Every line justified or absent — no placeholders, no "temporary" code.
- **Same-commit ledger.** A change's `tasks.md` checkboxes are ticked in the same commit
  that lands the corresponding work. A pending change whose tasks materially contradict
  shipped code is a review violation.
- **Binary truth.** A claim of success requires a terminal-verified proof — `repro.sh`
  exit 0, or `verify.sh` green. No claim of success without a terminal-verified proof.
- **Determinism.** Meaning comes from specification and compositional semantics. The LLM
  proposes; the spec disposes. A spec must be self-contained: implementable by a model

### Sitting registry

Owner-gated work is grouped by **sitting** — a single owner review session clears a column
rather than context-switching per task. The registry is closed; adding a sitting is an owner
decision. Current sittings:

| Sitting | Purpose | Example tasks |
|---|---|---|
| `DEVICE` | Requires physical device or simulator | iOS/Android builds, camera access, haptics |
| `REVIEW` | Visual/UX judgment call | Design sittings, preview reviews |
| `DECIDE` | External state or credentials | OAuth clients, signing keys, deployments |
| `SCHOLAR` | Research/evidence gathering | Reading source, auditing code |

Tasks in `owner-verification-passes` carry their sitting in brackets, e.g. `[DEVICE]`.
Run `./status.sh --sittings` to view owner-gated items grouped by sitting.
  that never saw the originating conversation.
- **Face Law.** Hold a screenshot beside Figma, Linear, and DaVinci Resolve. If it reads
  as a web page, it has failed — regardless of green gates. The six rules are in
  `CLAUDE.md` → Canonical stack; each is answerable yes/no on a diff, and adjectives
  ("clean", "minimal") are not admitted because they are not answerable. Spec:
  `enforce-face-law-conformance`.
- **Professional tool, not a hobbyist toy.** The bar is what a working practitioner would
  keep open all day. "It's early" is not a defense: early is when the face is set, and
  every surface shipped below the bar is one a later surface will be built to match.

## Screen consistency — the stacked-papers doctrine

Every screen in breakdex is one sheet of paper in an identical frame. Stack them on a
light table and the margins, header, nav, and safe areas align perfectly — only the
content band differs. This is not a design aspiration; it is a hard-lint rule enforced
by conformance tests.

### The mechanical basis

Flutter's layout pipeline is constraints-down / sizes-up (see READINGS.md → Flutter
rendering pipeline). The stacked viewport (CLAUDE.md → Layout doctrine) exploits this:
`AppScreen` is the parent that reads the viewport and proposes constraints to four
bands. The content band receives `BoxConstraints` with `minHeight` and `maxHeight`
derived from the frame — it never reads `MediaQuery` itself. This is the parent-child
constraint contract:

```
AppScreen (reads viewport, proposes constraints)
  ├── Band 1: SafeArea (system chrome)
  ├── Band 2: Header (72pt, fixed)
  ├── Band 3: Content (receives constraints, picks size)
  └── Band 4: Nav (56pt, fixed)
```

A screen that builds its own `Scaffold`, reads `MediaQuery.of(context).size`, or
hardcodes a pixel value is violating the constraint contract — it is a paper that
refuses to fit the frame.

### The hard-lint rules

These are review violations, not style suggestions. The conformance test that will
enforce them mechanically is specced, not yet written
(`enforce-face-law-conformance` 2.1 → `test/core/design/layout_conformance_test.dart`);
until it lands these rules are review-enforced, and 26 feature files still build a raw
`Scaffold`:

1. **One frame, one reader.** Only `AppScreen` reads the viewport. Content widgets
   receive constraints from their parent. `MediaQuery.of(context)` in a content
   widget is a defect unless the widget IS a band (header, nav).

2. **Constraints go down, size goes up.** A parent proposes `BoxConstraints`; a child
   picks a `Size` within them. A child that queries its own size to lay out its
   children (intrinsic sizing) is O(n²) and a review violation in hot paths.

3. **Content is interchangeable paper.** If you remove the content band from any
   screen and replace it with another screen's content band, the frame (header,
   nav, safe area) must be pixel-identical. This is the stacking test.

4. **Mobile-first means constraint-first.** The layout is authored for the smallest
   target (390pt logical width) and scales UP by receiving wider constraints —
   not by reading the viewport and branching on width. Breakpoints are constraint
   values, not `MediaQuery` queries. A `LayoutBuilder` that branches on
   `constraints.maxWidth` is correct; a `MediaQuery.of(context).size.width` branch
   is not.

5. **8pt block grid, 4pt baseline.** Every vertical dimension is a multiple of 8pt
   (blocks) or 4pt (half-steps). Every horizontal gutter is 24pt. The content band's
   first pixel is at safe-top + 80 (72pt header + 8pt breathing room). These are
   derived token values from `AppLayout`, not hand-picked paddings.

6. **One scroll axis per screen.** A screen has exactly one scrollable axis. Nested
   scrollables (a `ListView` inside a `SingleChildScrollView`) are a defect — they
   break the constraint contract because the inner scrollable receives unbounded
   constraints and cannot participate in the parent's layout.

7. **720pt reading clamp.** Content wider than 720pt is centered with symmetric
   margins. The clamp is enforced by the frame, not by individual screens.

### The amplification principle

Consistency amplifies like light through a lens: each screen that conforms to the
frame makes the next screen easier to build, because the frame's constraints are
already decided. The cost of a new screen is ONLY its content band — the header,
nav, safe area, grid, and scroll axis are free. This is how a factory condenses
work: the frame is built once, tested once, and every screen inherits it.

The inverse is also true: each screen that violates the frame makes the next screen
harder, because the violator's ad-hoc layout becomes a precedent that future screens
must match or explain why they differ. Drift compounds.

### Conformance testing

Specified shape (`enforce-face-law-conformance` 2.1, unwritten as of 2026-07-30):
`test/core/design/layout_conformance_test.dart` walks every registered screen route,
builds it in a test harness, and asserts:

- The widget tree contains exactly one `AppScreen` ancestor
- No `Scaffold` exists below `AppScreen` (the frame IS the scaffold)
- No `MediaQuery.of(context).size` call exists in content-band widgets
- The content band's first rendered pixel is at safe-top + 80 ± 4pt

A screen that fails any assertion is RED before it reaches review. The test is the
lint; the lint is the doctrine; the doctrine is the frame.

## The agentic-agnostic factory

The factory is model-agnostic: it produces the same output regardless of which LLM
executes a session. The model proposes text; the grammar decides whether it survives.

### Context condensation

A session that reads files (not history) starts with the context the files contain,
not the context the conversation accumulated. The condensation target:

| Budget | Mechanism |
|---|---|
| 200k ceiling | Hard limit per session; land at a checkbox, never mid-edit |
| 150k effective | Records ARE the context — no re-derivation from transcript |
| 100k target | Primeable bundles (`scripts/docs_bundle`) for cheap inference |

The only stochastic process is individual character generation — token sampling.
Everything else is deterministic: file I/O, script execution, gate results, ledger
ticks. The factory's records (ROADMAP.md, openspec/, verify.sh, session.log) are
the state machine; the model is the transition function, replaceable without loss.

### Discrete stochastic processes

The build loop is a sequence of discrete steps, each with a binary outcome:

```
read file → parse (succeeds or fails)
  → interpret spec (deterministic from file content)
  → generate code (stochastic: token sampling)
  → compile (succeeds or fails)
  → test (succeeds or fails)
  → gate (succeeds or fails)
  → tick ledger (deterministic: checkbox + commit)
```

The stochastic step (generate code) is bounded by the spec (what to build), the
manual (how to build it), and the gate (whether it works). The model's creativity
is constrained to the space between spec and gate — and that space shrinks as the
manual grows more precise. This is the condensation mechanism: each reading entry,
each standing bar, each conformance test removes one degree of freedom from the
stochastic step, so the next session needs fewer tokens to reach the same result.

### Handoff caps

| Handoff | Token cap | If exceeded |
|---|---|---|
| Spec → implementation | 500 | Task is too large — split it |
| Implementation → review | 1000 | Abridge to diff summary + gate result |
| Audit → decision | 500 | Abridge to findings + NOT PROVEN list |
| Session → record | 200 | One line per tick, one per remaining |

A cap that fits one screen is a good task. A cap that needs three screens is a bad
task — re-split at the spec level, not the implementation level.

## The unattended loop (overnight)

```sh
git checkout -b night/$(date +%F)
```

One headless process per unit — fresh context every time, disk is the only memory.
The runner stops on: blocked state, two consecutive units with no commit, two
consecutive failures, or the unit cap.

The runner refuses to start outside a `night/*` branch. `main` is never written to by
the loop, nothing is pushed, and merging stays the owner's act.

## Failure modes this system is built against

| Failure | The mechanism that prevents it |
|---|---|
| Work lost when a session ends | Every unit is resumable from disk alone |
| A decision quietly reversed | `DECISIONS.md` status + binding veto, owner-only promotion |
| A confident claim with no source | `READINGS.md` citation requirement + explicit caveat lines |
| A spec that only its author can implement | Specs must be self-contained; ambiguity is a spec bug |
| A green board that doesn't match reality | `status.sh` reads from canonical sources; gates print their own gaps |
| A large diff nobody can review | One commit per unit, one `session.log` line per commit |
| An agent asserting the UI looks right | No visual gate is self-certifiable |
| A migration that orphans user data | Brownfield constraint — additive over invasive, migrations one-way and tested |
| Screens that drift from the frame | Stacked-papers doctrine; gate specced as `test/core/design/layout_conformance_test.dart` (`enforce-face-law-conformance` 2.1), review-enforced until it lands |
| A model-dependent build process | Agentic-agnostic factory — records are the state machine, the model is replaceable |

## Where the other roles attach

| Role | Home | Unlocked when |
|---|---|---|
| Product designer | `openspec/changes/*/design.md` | now |
| Design system | `docs/design/TOKENS.md` + `lib/core/design/*.dart` | now |
| Forward-deployed | `docs/` | first external user on their own device |
| Growth | `docs/PRD.md`, `docs/VISION.MD`, `docs/CHANGELOG.md` | pricing is `agreed` and there is something chargeable |

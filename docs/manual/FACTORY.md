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
never patched around in code.

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
  that never saw the originating conversation.

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

## Where the other roles attach

| Role | Home | Unlocked when |
|---|---|---|
| Product designer | `openspec/changes/*/design.md` | now |
| Design system | `docs/design/TOKENS.md` + `lib/core/design/*.dart` | now |
| Forward-deployed | `docs/` | first external user on their own device |
| Growth | `docs/PRD.md`, `docs/VISION.MD`, `docs/CHANGELOG.md` | pricing is `agreed` and there is something chargeable |

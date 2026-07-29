# Design — Intent Index and Business Manual

## The objective being optimized

Every instrument in this repo so far answers *what is true*. `status.sh` answers "what is
the queue head". `verify.sh` answers "what is proven". `docs_ledger_check` answers "which
chapters are stale". None answers **"what has already been decided about the thing I am
about to touch"** — and that is the question whose absence produces an escalation.

State it as the quantity to minimize:

> **Escalations per session, subject to every decision citing a written ruling.**

Both halves are load-bearing. Minimizing escalations alone produces a confident agent that
invents rulings. Requiring citations alone produces an agent that asks constantly because
nothing is findable. The pair is the objective: *decide autonomously exactly as far as the
written record reaches, and no further.*

This reframes the two doctrines already in `CLAUDE.md`. The Capture rule ("an ask never
lives only in chat") and the Supersession rule ("a ruling must retire the work it kills")
are both **write-side** disciplines — they govern getting decisions into the repo. Neither
has a **read-side** counterpart. An unfindable ruling and an unwritten ruling are
operationally identical: both produce an escalation. This change builds the read side.

## D1 — The index is derived, never stored

Same ruling as `status.sh`, for the same reason. A stored index is a sixth record that can
disagree with the five real ones, and disagreement in a navigational record is worse than
in a content record: it routes an agent confidently to the wrong ruling.

Cost: a full parse on every invocation. At ~50 documents with frontmatter-and-headings-only
parsing this is tens of milliseconds — the same order as `docs_ledger_check`, which already
walks the manual on every CI run. Measure before optimizing; do not add a cache
speculatively.

**Rejected:** a committed `INDEX.md`. It would need its own freshness gate, which is a gate
guarding a navigational aid to the gates. Recursive and not worth it.

## D2 — Match semantics: path vs keyword heuristic

`--match <arg>` must distinguish a path glob from a keyword search without a second flag.

- If the argument starts with `lib/`, `docs/`, `scripts/`, `openspec/`, `test/`, or
  `web-mirror/` — **path prefix**. Match against each document's `watches:` list using the
  same glob-matching logic as `docs_ledger_check`. A document matches if any watch glob
  covers the argument.
- Otherwise — **keyword**. Match against `title:`, `name:`, `domain:`, and any `tags:` or
  `keywords:` in frontmatter, case-insensitive substring.

Properties:
- `--match lib/core/sync/sync_backend.dart` → returns the sync chapter whose `watches:`
  includes `lib/core/sync/**`, plus any spec or proposal watching the same path.
- `--match retention` → returns chapter 14 (Growth Model) whose title or tags mention
  "retention".
- `--match zzznotathing` → exits 0 with an empty set and names the record classes searched.

If the corpus grows enough that a file named `retention` lives under `docs/`, the path
heuristic wins — the argument would need explicit disambiguation (`--path` / `--keyword`
flags) in a later change.

## D3 — Index output format

Default: JSON array of objects, one per document, with source path, title, domain, status,
watch count, and match reason (if `--match` was used). `--tsv`: tab-separated columns for
shell piping (`awk`, `cut`, `column -t`).

`./status.sh --docs` renders results in `status.sh`'s own table format (same two-space indent
as the board), so the session sees:

```
=== Docs Index ===
  keyword: retention
  14-growth-model.mdx     product   draft   growth model, retention levers
  READINGS.md             —         4 entries match domain:product
```

## D4 — A business chapter must watch code, or it does not ship

This is the constraint that makes the business half survivable. The engineering manual does
not rot because every chapter names code it is truth about, and `docs_ledger_check` fails CI
when that code moves without the chapter moving. Business prose has no such anchor by
default — which is precisely why `docs/VISION.MD` and `docs/PRD.md` have drifted from the
shipped product without a single gate going red.

A business chapter's `watches:` list must point at the decision surface in code that
implements it:

| Chapter | Watches |
| --- | --- |
| Positioning & wedge | atom-model source (`lib/core/models/`), onboarding route |
| Growth & activation | instrumentation events, onboarding + first-run surfaces |
| GTM, pricing & packaging | pricing/offering config, invite-code + entitlement logic |
| Forward-deployed | invite/cohort surfaces, diagnostics export, support seams |
| Metrics contract | event-name definitions and their emit sites |

A chapter that can name no such surface is describing an aspiration, not a ruling, and
belongs in `READINGS.md` (Scholar reading) or a change proposal (Teacher intent) — not in
the manual. The manual is for what is true.

**Consequence to accept:** the growth and metrics chapters may be thin at first, because the
instrumentation they would watch is itself thin. That is honest: the chapter's thinness is a
visible measurement of the product gap, rather than rich prose describing a funnel that
nothing emits events for.

## D5 — Five product chapters rather than one

A single "Product & Business" chapter would exceed every sensible atomic-reading size (the
engineering manual's chapters average ~200 lines). Each of the five topics has distinct
readers, distinct `watches:` targets, and distinct update cadences:

- **Positioning** (13) — changes when the competitive landscape or beachhead shifts (~quarterly).
  Watches: `docs/VISION.MD`, `docs/PRD.md`, product copy files.
- **Growth Model** (14) — changes when a retention experiment lands or the user journey shifts.
  Watches: analytics events, experiment flags, the onboarding flow.
- **GTM & Pricing** (15) — changes with each pricing cohort or platform launch.
  Watches: remote config schemas, distribution tooling.
- **Forward-Deployed** (16) — changes when the release process or owner-gating rules change.
  Watches: `scripts/distribute.sh`, `scripts/verify_ledger.sh`, `CLAUDE.md` session rules.
- **Metrics** (17) — changes when a metric is defined or deprecated.
  Watches: diagnostics services, analytics DAOs, reporting scripts.

Five chapters also makes the `domain:` split clean: `product`, `product`, `gtm`, `business`,
`business` — each consumed by a different role (PM, growth engineer, release manager,
on-call agent, data engineer).

## D6 — The decision-warrant rule: what it can and cannot check

The rule has three clauses. They are not equally enforceable:

1. **"Escalate only when no ruling binds"** — *not mechanically checkable.* Judgment. Made
   cheap and correct by the index rather than by a gate.
2. **"A decision cites its ruling"** — *checkable by convention, gated by review.* A session
   log line records the warrant.
3. **"An ask never ends the session uncaptured"** — *already checkable,* already the Capture
   rule. This change adds no machinery here.

Do not build a linter that greps session logs for citation strings. It would be trivially
satisfiable and measure compliance theater. The honest mechanism is: (a) make resolution one
command, (b) require the warrant in the session log, (c) let review catch violations.

**The dogfood test is the real gate.** Take a decision that would have been an escalation
and require that `--docs` resolves it to a ruling without opening a file. Scenarios fail
when the index cannot resolve an intent that the team claims it should.

## D7 — Domain field on READINGS.md

Current READINGS.md template gains:

```markdown
- **Domain:** engineering | product | design | gtm | business
```

The field serves two masters:
1. `scripts/docs_index --match` filters readings by domain, so Scholar captures are
   findable by domain.
2. Teacher sessions writing product specs can ask "what readings informed this?" and
   filter by domain rather than scanning every entry.

Optional — an entry without `domain:` defaults to `engineering` for indexing purposes.

The lane, the format, the gate, and the Teacher hand-off all stay identical. This extends
the Scholar lane; it does not build a second factory.

## D8 — Relationship to existing documentation

| Doc | How this change relates |
| --- | --- |
| `docs/manual/index.mdx` | Reading-order table gains "Product & Business" section with chapters 13–17. |
| `scripts/docs_bundle` | Gains `--domain` flag. `--domain product` bundles only product chapters + standards preamble. `--all` continues to include everything. |
| `scripts/docs_ledger_check` | Unchanged. Business chapters carry `watches:`/`verified:`, so the existing drift check covers them automatically. |
| `./status.sh` | Gains `--docs` flag. Thin dispatch to `scripts/docs_index`. Does NOT change the board output. |
| `openspec/AGENTS.md` | Unchanged. Teacher/student split already expects the manual; product chapters are just more chapters. |
| `docs/VISION.MD`, `docs/PRD.md` | Indexed by the product chapters (chapter 13 links them, absorbs no content). Same absorb-or-index discipline. |

## D9 — Root README.md content model

The root README is NOT a duplicate of `docs/manual/index.mdx`. Its entire content is:

1. **Project name + one-line elevator pitch**
2. **Quick links:** manual → `docs/manual/index.mdx`, roadmap → `ROADMAP.md`, agent contract
   → `CLAUDE.md`, design tokens → `docs/design/TOKENS.md`
3. **First-time reader guidance:** "If you are an agent, start at `CLAUDE.md` → `## Session
   start`. If you are a human, read the [manual](./docs/manual/index.mdx)."
4. **Build/run/test one-liners:** `flutter run`, `flutter test`, `./verify.sh`
5. **Instrument signpost:** `./status.sh --docs <keyword|path>` is the way to resolve an
   intent to its rulings

No roadmap summary, no architecture diagram, no session history. The README signposts; it
never duplicates.

## D10 — Recorded ruling: no Ruby, no Lisp, no external DSL

Recorded here because it has been raised twice and, per the Queue doctrine, a decision that
lives only in a transcript is re-asked forever. This change is dogfooding its own rule.

The admired reference points — Stripe's memo-and-API-documentation discipline, Airbnb's
`.md`-driven RFC process — are **writing cultures**. That both companies are Ruby shops is
correlation, not mechanism. The transferable asset is: the document is the unit of work, it
is reviewed like code, and it is the artifact decisions are made in. That ports to this repo
unchanged; the runtime does not need to come with it.

Against adopting one anyway:
- A second toolchain is invisible to `verify.sh`. The single cumulative gate seeing
  everything is this factory's actual differentiator; splitting it is a direct loss.
- Ruby's DSL strength (`instance_eval`, `method_missing`, blocks-as-config) buys syntax that
  reads like English at the cost of nothing checking it — the exact failure the layout
  doctrine corrected three weeks prior.
- Lisp's real claim is homoiconicity, and the valuable half is already held: data-oriented
  design plus a sealed-class `Machine<S,E>` interpreter is "code as data" *with* a type
  checker. Full macro power trades the compiler's ability to say no, which is a bad trade in
  a brownfield app with live user data.

**Where the instinct is right:** the atom model (move → combo → set, beats as metadata) is a
genuine domain algebra and is under-expressed as scattered Dart models. Formalizing it as a
sealed `Atom` type with one composition operator and one interpreter is real work — an
*internal* DSL, in Dart. That is a separate change; it is named here so the idea is captured
rather than lost, per the Capture rule. See the `add-atom-model-algebra` stub change.

## D11 — What fails CI versus what only reports

Adding a hard gate to `verify.sh` that every intent resolves would be unsatisfiable — the
space of intents is unbounded — and an unsatisfiable gate gets disabled, taking the
satisfiable parts with it.

| Condition | Behavior |
| --- | --- |
| A chapter's `watches:` glob matches no file on disk | **fail** (dead pointer, same class as ledger drift) |
| A business chapter has an empty `watches:` list | **fail** (D4) |
| `docs_index` cannot parse a record's frontmatter | **fail** (malformed record) |
| A named intent in the dogfood scenario resolves to nothing | **fail** (D6's real gate) |
| An `openspec/changes/*` proposal has no indexable keywords | **report** (Queue doctrine: repair when active) |
| Overall coverage percentage | **report** — printed, never thresholded |

Consistent with the standing bar: every gate prints what it did **not** prove. The index
prints its coverage so a green run is never mistaken for "every intent resolves."

## D12 — What is not decided here

- **Implementation language for `docs_index`.** Bash vs Dart. Precedent: `docs_bundle` is
  bash, `docs_ledger_check` is Node. The commit lands whichever makes the YAML-frontmatter
  parsing simplest. The design records the precedent; the implementation chooses.
- **Exact chapter outlines for chapters 13–17.** The spec deltas define each chapter's
  mandatory coverage areas; the line-level prose is authored in Phase 3.
- **Whether `--match` gains explicit `--path`/`--keyword` flags.** The heuristic (D2) is
  sufficient at current scale. Add explicit flags only when a false heuristic path is
  observed in a real session.

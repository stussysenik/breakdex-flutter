# Design — intent-resolution layer

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
disagree with the five real ones, and disagreement in a *navigational* record is worse than
in a content record: it routes an agent confidently to the wrong ruling.

Cost: a full parse on every invocation. At 420 files with frontmatter-and-headings-only
parsing this is tens of milliseconds — the same order as `docs_ledger_check`, which already
walks the manual on every CI run. Measure before optimizing; do not add a cache
speculatively (§1, right-sized performance).

**Rejected:** a committed `INDEX.md`. It would need its own freshness gate, which is a gate
guarding a navigational aid to the gates. Recursive and not worth it.

## D2 — One index, two lookup directions

The `watches:` frontmatter already encodes a **chapter → code globs** relation. Every
question an agent actually asks runs the other way.

- **path → rulings** is a pure inversion of existing data. Zero new authoring burden; it
  works the day the script lands. This is the cheap half and it should ship first.
- **keyword → rulings** needs a keyword source. Derive it, do not hand-maintain it: chapter
  `title` + `name`, `### Requirement:` headings in `openspec/specs/*/spec.md`, and change
  ids. A hand-curated keyword list is a seventh record that rots.

Matching is substring-and-token, case-insensitive, ranked by record class: **manual chapter
> promoted spec > active change > archived change**. A promoted spec in `openspec/specs/`
outranks a change proposing to alter it, because the spec is what is true now and the
proposal is what someone wants. Archived changes rank last but are *not* excluded — they
carry the supersession notes, which are frequently the actual answer to "why is this not
how it looks."

**Consequence to accept:** keyword lookup returns a ranked list, not an answer. The agent
still reads. The instrument's job is to collapse "grep 420 files" into "read 3 records".

## D3 — A business chapter must watch code, or it does not ship

This is the constraint that makes the business half survivable, and it is the one most
likely to be argued away later, so the reasoning is recorded here.

The engineering manual does not rot because every chapter names code it is truth about, and
`docs_ledger_check` fails CI when that code moves without the chapter moving. Business prose
has no such anchor by default — which is precisely why `docs/VISION.MD` and `docs/PRD.md`
have drifted from the shipped product without a single gate going red.

So: **a business chapter's `watches:` list points at the decision surface in code that
implements it.**

| Chapter | Watches |
| --- | --- |
| Positioning & wedge | the atom-model source (`lib/core/models/`), onboarding route |
| Growth & activation | instrumentation events, onboarding + first-run surfaces |
| GTM, pricing & packaging | pricing/offering config, invite-code + entitlement logic |
| Forward-deployed | invite/cohort surfaces, diagnostics export, support seams |
| Metrics contract | the event-name definitions and their emit sites |

A chapter that can name no such surface is describing an aspiration, not a ruling, and
belongs in `READINGS.md` (a Scholar source) or a change proposal (a Teacher intent) — not in
the manual. **The manual is for what is true.**

**Consequence to accept:** the growth and metrics chapters may be thin at first, because the
instrumentation they would watch is itself thin. That is honest and it is the point: the
chapter's thinness is a visible measurement of the product gap, rather than rich prose
describing a funnel that nothing emits events for.

## D4 — What the decision-warrant rule can and cannot check

The rule has three clauses. They are not equally enforceable, and pretending otherwise would
repeat the mistake the layout doctrine already corrected (prose lost; `AppScreen` held).

1. **"Escalate only when no ruling binds"** — *not mechanically checkable.* Judgment. It is
   made *cheap and correct* by the index rather than enforced by a gate.
2. **"A decision cites its ruling"** — *checkable by convention, gated by review.* A session
   log line records the warrant. Cheap and worth doing.
3. **"An ask never ends the session uncaptured"** — *already checkable*, and already the
   Capture rule. This change adds no new machinery here.

Do not build a linter that greps session logs for citation strings. It would be trivially
satisfiable and would measure compliance theater rather than the objective. The honest
mechanism is (a) make resolution one command, (b) require the warrant in the session log,
(c) let review catch violations. State plainly in the spec that clause 1 is unenforced.

**The dogfood test is the real gate.** Take a decision that would have been an escalation —
"should the settings icon pack ship before or after the web deploy?" — and require that
`--docs` resolves it to a ruling without opening a file by hand. That is a scenario, and
scenarios can fail.

## D5 — Extend the Scholar lane; do not build a second factory

The owner's framing was condensing the daily output of ~100 staff (designers, growth, GTM,
forward-deployed) into a small clean codebase. The instinct is to build a place for each
role. That would be four new record types, four new drift gates, and four new things a
session must read before starting.

The existing lane already does this job. Scholar → `READINGS.md` ("no opinions without a
source") → Teacher → spec → Student → code **is** the condensation pipeline. A competitor
teardown, a pricing experiment, a customer call, and a design crit are all Scholar readings:
each has a source, a mechanism-level takeaway, and a spec-impact line. The format needs no
change.

The only defect is that `READINGS.md` is engineering-shaped by convention, so nobody files a
GTM source there. One field fixes it: `domain: eng | product | design | gtm | ops`. The lane,
the format, the gate, and the Teacher hand-off all stay identical, and `--docs` can filter by
domain for free.

**Rejected:** per-role manuals, a `docs/business/` tree parallel to `docs/manual/`, and a
"dailies" log. All three add records without adding resolvable rulings — they grow the pile
this change exists to make navigable.

## D6 — Recorded ruling: no Ruby, no Lisp, no external DSL

Recorded here specifically because it has now been raised twice in one session and, per the
Queue doctrine, a decision that lives only in a transcript is re-asked forever. This *is* the
change dogfooding its own rule.

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
  design (§2) plus a sealed-class `Machine<S,E>` interpreter is "code as data" *with* a type
  checker. Full macro power trades the compiler's ability to say no, which is a bad trade in
  a brownfield app with live user data.

**Where the instinct is right:** the atom model (move → combo → set, beats as metadata) is a
genuine domain algebra and is under-expressed as scattered Dart models. Formalizing it as a
sealed `Atom` type with one composition operator and one interpreter is real work — an
*internal* DSL, in Dart. That is a separate change; it is named here so the idea is captured
rather than lost, per the Capture rule.

## D7 — What fails CI versus what only reports

Adding a hard gate to `verify.sh` that every intent resolves would be unsatisfiable — the
space of intents is unbounded — and an unsatisfiable gate gets disabled, taking the
satisfiable parts with it.

| Condition | Behavior |
| --- | --- |
| A manual chapter's `watches:` glob matches no file on disk | **fail** (dead pointer, same class as ledger drift) |
| A business chapter has an empty `watches:` list | **fail** (D3) |
| `docs_index` cannot parse a record's frontmatter | **fail** (malformed record) |
| A named intent in the dogfood scenario set resolves to nothing | **fail** (D4's real gate) |
| An `openspec/changes/*` proposal has no indexable keywords | **report** (Queue doctrine: repair when active, never in bulk) |
| Overall coverage percentage | **report** — printed, never thresholded |

Consistent with the standing bar: every gate prints what it did **not** prove. The index
prints its coverage so a green run is never mistaken for "every intent resolves."

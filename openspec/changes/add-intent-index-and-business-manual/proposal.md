# Intent Index and Business Manual

## Why

This repo has 420 markdown records (148 outside `openspec/`, 272 inside), a 13-chapter MDX
engineering manual with a machine-checked freshness ledger, and two derived instruments
(`status.sh`, `verify.sh`). It has no root `README.md`, and on 2026-07-29 the owner reported
being unable to find the engineering manual at all. The manual was not missing. It was
unreachable.

The factory's throughput is bounded by how many decisions an agent must escalate to the owner.
A session that can resolve "what has already been ruled about this?" decides and keeps working.
A session that cannot, asks — and every ask costs a round trip, re-opens a settled question,
and risks a contradiction. The Queue doctrine already names this failure ("a decision that
lives only in a transcript will be re-asked every session forever"), and the Supersession rule
names its worst form (six changes, ~57 tasks, dead for 89 days because a locked ruling never
retired the work it killed). Both rules describe the disease. Neither gives an agent an
instrument.

**The objective to minimize: escalations per session, subject to every decision citing a
written ruling.** Both halves are load-bearing — minimizing escalations alone produces a
confident agent that invents rulings; requiring citations alone produces one that asks
constantly because nothing is findable.

The gap is unevenly distributed:

- **Engineering intents resolve.** "What owns `lib/core/sync/`?" is answerable because every
  manual chapter carries a `watches:` glob list and `docs_ledger_check` keeps it honest.
- **Product, GTM, design-rationale, growth, and ops intents resolve to nothing.** The
  merchant-of-record ruling and the $4.20–$9.99 offering band live in a table row in
  `CLAUDE.md`. Positioning lives in `docs/VISION.MD`, unledgered. Growth lives nowhere.

Three structural discovery failures:

1. **No path-based reverse lookup.** A session touching `lib/core/sync/` must already know
   that chapter 4 is the relevant one, or grep the manual's frontmatter for the glob. The
   `watches:` field is designed for this but invisible unless you know what you are looking for.
2. **No keyword index.** A session that needs "pricing model" or "retention" has nowhere to start.
3. **No product/business half.** Positioning, growth, GTM, forward-deployed, and metrics have
   no canonical home. They exist as scattered decisions in `ROADMAP.md`, `CLAUDE.md`,
   `docs/VISION.MD`, `docs/PRD.md`, and the session log — each authoritative about its own
   slice, none composing into a readable reference.

## What Changes

Four parts, one spine: make every standing ruling resolvable from an intent, then make
deciding-from-a-ruling the recorded default.

### 1. Intent index tool — `scripts/docs_index` + `./status.sh --docs`

A derived index, never stored, in the same idiom as `status.sh`. Reads frontmatter across
`docs/manual/*.mdx`, `openspec/specs/*/spec.md`, `openspec/changes/*/proposal.md`, and root
records. Answers two directions:

- **path → rulings**: reverse `watches:` lookup. `--docs lib/core/sync/` returns manual ch04
  plus the sync specs.
- **keyword → rulings**: `--docs pricing` returns the GTM chapter plus
  `add-web-first-release-and-monetization`.

Output: JSON (default) or TSV (`--tsv`). Integrates into `./status.sh --docs <arg>`.

### 2. Business half of `docs/manual/`

Five new chapters, same frontmatter contract, `watches:` globs, and `docs_ledger_check`
coverage as the engineering half. A business chapter whose `watches:` list is empty does not
ship.

| # | Chapter | Domain | Covers |
| --- | --- | --- | --- |
| 13 | Product Positioning | `product` | Atom model as market position, beachhead vs expansion, visual-first as differentiator, competitive landscape |
| 14 | Growth Model | `product` | User journey, retention levers, viral loops, practice-fidelity feedback loop |
| 15 | GTM & Pricing | `gtm` | Web-first release, invite-code cohort, $4.20–$9.99 tiers, merchant-of-record strategy |
| 16 | Forward-Deployed | `business` | Owner-driven decisions, release gate, session authority, brownfield invariants |
| 17 | Metrics & Observability | `business` | Key business metrics, diagnostics infra, the board as health signal, gaps |

### 3. Decision-warrant rule

The behavior this change exists to reward, written down and made checkable. An agent that
finds a binding ruling decides and cites it; one that finds none escalates. Plus a `domain:`
field on `READINGS.md` entries (`eng | product | design | gtm | ops`) so the existing Scholar
lane absorbs product and market sources without a second pipeline.

### 4. Root signpost and integration

A root `README.md` — the one signpost naming what the repo is, the three instruments, the two
manuals, and `--docs` as the way in. A `--domain` filter on `scripts/docs_bundle` for
domain-specific priming.

## Capabilities

| Capability | What it covers |
| --- | --- |
| `intent-index` | Derived frontmatter index (`scripts/docs_index` + `./status.sh --docs`), two lookup directions, output flags, coverage gate |
| `decision-warrant` | Decide-don't-ask rule framework in `CLAUDE.md`, escalation boundary, `domain:` on readings, the atom-model stub |
| `developer-docs` | MODIFIED — manual extends to a business half under the same authoring contract; chapters name their decision surface |
| `docs-ledger` | MODIFIED — freshness and drift check cover business chapters; domain field, dead-glob check, empty-watches fail |
| `product-manual` | Five new chapters authored from existing rulings, not from invention; gaps named rather than filled with prose |

## Footprint estimate

| Surface | Current | Target | Δ |
| --- | --- | --- | --- |
| `scripts/docs_index` | — | ~200 LOC (Node, sibling to `docs_ledger_check`) | +200 |
| `status.sh` | 118 LOC | ~150 LOC | +32 |
| `verify.sh` | 86 LOC | ~92 LOC | +6 |
| `README.md` | — | ~40 lines | +40 |
| `docs/manual/*.mdx` | 13 files / 2,204 lines | 18 files / ~3,100 lines | +5 files / ~900 lines |
| `docs/manual/READINGS.md` | format block | +`domain:` field | +8 lines |
| `CLAUDE.md` | — | +decision-warrant section | +22 lines |
| `scripts/docs_ledger_check` | 124 LOC | ~142 LOC | +18 |
| `scripts/docs_bundle` | 130 LOC | ~140 LOC | +10 |

Total ≈ **1,240 lines**, ~75% prose. Executable code is ~270 LOC. No `lib/` files change;
no Flutter surface is touched.

## Non-goals

- **No new runtime or language.** The register this borrows from (Stripe's memo-and-API-docs
  discipline, Airbnb's `.md`-driven RFC process) is a writing culture, not Ruby. A second
  toolchain would be invisible to `verify.sh`.
- **No documentation site, static-site generator, or MDX rendering pipeline.** Chapters stay
  meaningful as plain text; the index is a terminal instrument.
- **No search engine.** `docs_index` matches against frontmatter fields, not full-text bodies.
  Full-text grep over `docs/` already works (`rg`); this does not replace it.
- **No stored index.** The index is derived on every invocation. A cached index is a sixth
  record that can disagree with the other five.
- **No repo-wide retrofit of the 272 change documents.** The index reads what frontmatter
  exists and reports coverage; records are repaired when they become active (Queue doctrine).
- **No new session lane.** Product and market sources ride the existing Scholar lane via
  `domain:`. Adding a parallel factory for the business half is the failure this avoids.
- **No pricing implementation.** Chapter 15 documents the *rationale*. The actual payment
  integration is owned by `add-web-first-release-and-monetization`.
- **No rewrite of `docs/VISION.MD` or `docs/PRD.md`.** Those remain canonical. The manual
  indexes and contextualises them (absorb-or-index discipline).
- **Not `web-mirror/` coverage.** The dev surface is exempt, consistent with existing rules.

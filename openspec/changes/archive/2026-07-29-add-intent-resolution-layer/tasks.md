# Tasks — intent-resolution layer

**Phase dependencies.** Phases 1, 2, and 3 are independent and may fan out across sessions.
Phase 4 consumes Phase 1 (chapters are authored against the index's coverage report).
Phase 5 consumes Phase 4. Phase 6 consumes all.

**Ledger rule.** Every box ticks in the same commit that lands its work, and the ROADMAP
`## NOW` block advances in that same commit. Binary truth: no tick without terminal output.

**Scope note.** No file under `lib/` changes in this change. If a task appears to require a
Flutter edit, that is a bug in this spec — stop and flag it rather than improvising.

---

## Phase 1 — The index instrument (path → rulings)

The cheap half: it inverts data that already exists and works the day it lands.

- [ ] 1.1 Write `scripts/docs_index` (Node, sibling idiom to `scripts/docs_ledger_check`).
      Parse YAML frontmatter from `docs/manual/*.mdx`; build the record set with file path,
      `title`, `name`, `watches`, `status`, `verified`, and `domain` when present.
      **Verify:** `scripts/docs_index --dump` lists all 13 current chapters with parsed globs.
- [ ] 1.2 Implement reverse `watches:` lookup: a path or glob argument returns every record
      whose globs match, each with its matching glob. Derived per invocation; nothing cached
      or committed (design D1).
      **Verify:** `scripts/docs_index lib/core/sync/` returns chapter 04; `lib/core/state_machines/`
      returns chapter 02. Terminal output pasted in the commit body.
- [ ] 1.3 Add dead-glob detection: exit non-zero naming any chapter whose `watches:` glob
      matches no file on disk.
      **Verify:** red/green — introduce a bogus glob in a scratch copy, confirm exit 1 and the
      chapter is named; remove it, confirm exit 0.
- [ ] 1.4 Add `--docs <query>` to `status.sh`, delegating to `scripts/docs_index`, and name the
      verb in the standing board output. Board stays read-only; no queue reordering.
      **Verify:** `./status.sh --docs lib/core/sync/` matches 1.2's output; `./status.sh` with
      no args still prints the board unchanged.
- [ ] 1.5 Wire the dead-glob and parse-failure gates into `verify.sh`, printing the
      `openspec/changes/*` coverage percentage as a **report, not a threshold**, and stating
      what the run did not prove (design D7).
      **Verify:** `./verify.sh --quick` green with the new gate; its output names the
      not-proven line.

## Phase 2 — Keyword direction and the root signpost

- [ ] 2.1 Extend `scripts/docs_index` with keyword lookup over derived sources only: chapter
      `title`/`name`, `### Requirement:` headings in `openspec/specs/*/spec.md`, and change
      ids from `openspec/changes/*/proposal.md`. No hand-curated keyword list (design D2).
      **Verify:** `--docs pricing` returns the monetization change; `--docs tombstone` returns
      the sync chapter and sync specs.
- [ ] 2.2 Implement record-class ranking: manual chapter > promoted spec > active change >
      archived change. Archived changes are ranked last but never excluded — they carry the
      supersession notes.
      **Verify:** `--docs appwrite` ranks the sync chapter above the migration change above the
      2026-07-29 BEAM archive note.
- [ ] 2.3 Implement the explicit-miss path: zero matches reports the record classes searched,
      so "nothing is ruled" is distinguishable from "the index did not look there".
      **Verify:** `--docs zzzznotathing` exits 0 with the searched-classes list.
- [ ] 2.4 Write root `README.md`: what the repo is, the three instruments, both manual halves,
      the session-start protocol entry. Pointers only — every normative statement is a link to
      the record that owns it.
      **Verify:** grep the README for normative verbs (`SHALL`, `MUST`, `never`) — each hit is
      inside a link label or is removed.

## Phase 3 — The decision-warrant rule (independent of 1–2)

- [ ] 3.1 Add the decision-warrant section to `CLAUDE.md`: decide when a ruling binds, cite the
      ruling before the work, escalate only when none binds. State plainly that sequencing a
      delivered scope is a session call and changing scope is not (Capture rule unchanged).
      **Verify:** section cross-links the Capture rule and Queue doctrine; `openspec validate`
      unaffected.
- [ ] 3.2 In the same section, declare which clauses are enforced and which are not (design
      D4) — explicitly that the escalate-only-when-unruled clause rests on judgment made cheap
      by `--docs`, not on a gate, and that no tooling greps session logs for citations.
- [ ] 3.3 Extend the `docs/manual/session.log` line format to carry the warranting record for
      any decided-not-escalated call, and update `FACTORY.md`'s session-start protocol to match.
      **Verify:** `FACTORY.md` and `CLAUDE.md` step 5 agree on the format; no third statement of
      it exists (grep for the old format string).
- [ ] 3.4 Add `domain: eng | product | design | gtm | ops` to the `READINGS.md` entry format
      block. Entry format, Scholar lane, and Teacher hand-off otherwise unchanged; no new lane.
      **Verify:** existing entries backfilled to `domain: eng`; `--docs` filters by domain.
- [ ] 3.5 **Capture only** (per D6, so the idea stops living in this transcript): create a stub
      change `add-atom-model-algebra` proposing the sealed `Atom` type with one composition
      operator and one interpreter, as an internal Dart DSL. One-line stub is a valid capture;
      do not design it here.
      **Verify:** the change directory exists and is named in the ROADMAP backlog.

## Phase 4 — The business half of the manual (consumes Phase 1)

Author by **consolidating rulings that already exist and are scattered**, not by inventing
product strategy. Each chapter names its gaps rather than filling them with prose (design D3).
Sources: `CLAUDE.md` canonical-stack table, `docs/VISION.MD`, `docs/PRD.md`,
`add-web-first-release-and-monetization`, `READINGS.md`.

- [ ] 4.1 `13-positioning.mdx` — the wedge: who this is for, why breaking, why the atom model
      rather than a generic SRS. `watches:` the atom-model source and the onboarding route.
      **Verify:** every claim links to `docs/VISION.MD`, the atom-model chapter, or a reading;
      claims with no source are cut, not softened.
- [ ] 4.2 `14-growth-and-activation.mdx` — the activation path and what is instrumented today.
      `watches:` the instrumentation emit sites and first-run surfaces. Name the uninstrumented
      remainder as a gap.
      **Verify:** every documented event exists in code; grep proves it.
- [ ] 4.3 `15-gtm-pricing-packaging.mdx` — consolidates the offering band ($4.20–$9.99), the
      web merchant-of-record ruling, StoreKit-later, invite codes binding entitlement + config
      cohort, and the web→iOS→Android rollout. `watches:` pricing/offering config and
      entitlement logic.
      **Verify:** `--docs pricing` returns this chapter first; the `CLAUDE.md` table row links
      here rather than restating (absorb-or-index).
- [ ] 4.4 `16-forward-deployed.mdx` — what an invited wave-1 user experiences end to end:
      invite → install → first combo → sync → support/diagnostics. `watches:` invite/cohort
      surfaces and the diagnostics export.
      **Verify:** each step names a real route or service; steps with no implementation are
      marked as gaps.
- [ ] 4.5 `17-metrics-contract.mdx` — the event-name definitions, what each means, and what
      "working" is numerically. `watches:` the event definitions and their emit sites.
      **Verify:** the chapter's event list and the code's emitted names match exactly; a
      mismatch fails the task, not the chapter.
- [ ] 4.6 Update `docs/manual/index.mdx`: two-half reading order, business chapters in the
      table, and a line on when to read which half.
      **Verify:** every chapter file has a row; count matches `ls docs/manual/*.mdx`.

## Phase 5 — Ledger the business half (consumes Phase 4)

- [ ] 5.1 Extend `scripts/docs_ledger_check` to walk both halves and to require `domain:` on
      business chapters.
      **Verify:** red/green — drop `domain:` from one business chapter, confirm exit 1.
- [ ] 5.2 Add the empty-`watches:` failure for business chapters (design D3 is enforced here,
      not by review).
      **Verify:** red/green — empty a business chapter's `watches:`, confirm exit 1 naming it.
- [ ] 5.3 Set every new chapter's `status:`/`verified:` honestly — `draft` until its claims are
      checked against code at that commit. Do not mark `verified` to make a gate pass.
      **Verify:** `./verify.sh` green; the docs-ledger output lists the true status of all 18
      chapters.

## Phase 6 — Dogfood validation (consumes all)

The change is not done because the scripts run. It is done when a decision that would have
been an escalation resolves without one.

- [ ] 6.1 Build the dogfood scenario set: at least five intents that previously required an
      owner ask, at least two of them business-side (e.g. "which offering tier does an invite
      code grant?", "does the icon-pack work ship before the web deploy?"). Store as a fixture
      the index gate reads.
      **Verify:** the fixture file exists and each entry names the expected warranting record.
- [ ] 6.2 Gate the scenario set in `verify.sh`: any listed intent resolving to zero records
      fails (design D7).
      **Verify:** red/green — add an unresolvable intent, confirm exit 1; remove it, exit 0.
- [ ] 6.3 Run one real session end-to-end using only `./status.sh --docs` to resolve its
      rulings, and record in `session.log` how many escalations it required and which intents
      forced them.
      **Verify:** the log line exists; unresolved intents become tasks in this change or a new
      one — never a chat message (Capture rule).
- [ ] 6.4 Reconcile: fold the Phase 6.3 findings back into the chapters or the index, then
      state in the change's completion note exactly what this change did **not** prove
      (unbounded intent space, no device/browser verification, no runtime behavior).

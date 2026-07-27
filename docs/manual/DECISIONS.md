# Breakdex — Decision Ledger

Every non-trivial decision lives here: status `proposed | contested | agreed`, who holds
it, and the evidence it rests on. **Only the owner promotes to `agreed`.** Veto is binding.

## Format

```markdown
### YYYY-MM-DD: Decision title

- **Status:** proposed | contested | agreed
- **Holder:** owner
- **Confidence:** 0.0–1.0
- **Evidence:** READINGS.md entries or design docs that support this
- **Alternatives considered:** what else was evaluated and why not chosen
- **Ruling:** the decision itself, in one paragraph
```

---

## Active decisions

### 2026-07-27: Adopt valoric factory model (Scholar/Teacher/Student)

- **Status:** agreed
- **Holder:** owner
- **Confidence:** 0.9
- **Evidence:** direct adaptation of the valoric project's FACTORY.md and CLAUDE.md workflow
- **Alternatives considered:** continue with undifferentiated agent sessions (status quo) —
  no provenance trace, no session-lane discipline, work lost between sessions
- **Ruling:** breakdex adopts three session types (Scholar/Teacher/Student), the six-record
  provenance system, FACTORY.md as operating manual, and domain-oriented directory structure.
  Existing openspec changes and engineering manual stay; they compose with the new discipline.

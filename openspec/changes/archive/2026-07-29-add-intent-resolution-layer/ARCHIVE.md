# Archive note — add-intent-resolution-layer

**Archived:** 2026-07-29
**Superseded by:** `add-intent-index-and-business-manual`

## Why

Two proposals for the same intent (make every standing ruling resolvable from an intent)
were created in the same session under different names:

| Change | What it contained |
| --- | --- |
| `add-intent-resolution-layer` (this one) | 4 specs (intent-resolution, decision-warrant, developer-docs, docs-ledger), stronger philosophical framing (objective function), DSL ruling, dogfood validation |
| `add-intent-index-and-business-manual` | 2 specs (docs-index, product-manual), more concrete tool design (JSON/TSV flags, path heuristic), detailed chapter outlines |

Rather than maintaining two changes, they were merged into `add-intent-index-and-business-manual`
(the better name — more descriptive of what actually ships). The merged change carries:

- All 5 spec files (intent-index, decision-warrant, developer-docs, docs-ledger, product-manual)
- The objective-function framing from resolution-layer
- The concrete tool design from business-manual (D2 path heuristic, D3 output format)
- The DSL ruling (D10) and the CI gate philosophy (D11)
- The decision-warrant rule (Phase 2)
- The dogfood validation (Phase 6)
- `impl_notes` on every task making each Claude Code–ready

## All keepers

- The DSL-design space (sealed `Atom` type, internal Dart DSL) lives as the stub change
  `add-atom-model-algebra` (Phase 2.3).
- The sealed-class software-factory pattern discussion from the 2026-07-29 session is NOT
  captured in any OpenSpec change — it is architectural exploration that needs a dedicated
  Teacher session.

# design-tokens

## ADDED Requirements

### Requirement: Single canonical token table
`docs/design/TOKENS.md` SHALL be the single source of truth for design tokens: one table per
group (colors, spacing on the 8pt/4pt grid, typography/Inter, depth) listing token name,
value, Dart constant in `lib/core/design/`, CSS custom property, and consumers. Both the
Dart token files and the web `tokens.css` SHALL conform to the table; conformance is a
mandatory review-checklist item. Codegen is deferred until a third consumer exists.

#### Scenario: Token change starts at the table
- **WHEN** any design token value changes
- **THEN** the commit updates TOKENS.md and every listed consumer together, and review
  rejects a token edit that touches only one side

#### Scenario: No orphan tokens
- **WHEN** the table is audited against `lib/core/design/*.dart` and `tokens.css`
- **THEN** every constant appears in the table and every table row resolves to real
  constants in each shipped consumer

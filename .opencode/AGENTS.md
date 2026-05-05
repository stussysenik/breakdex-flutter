# Breakdex Flutter - Agent Instructions

## Tool Usage Rules
- **File search**: Always use `fff` MCP tools (`ffgrep`, `fffind`) instead of built-in grep/glob.
- **Code structure**: Use `ast_grep` MCP for AST-based pattern search and structural refactoring.
- **Complex reasoning**: Use `sequential_thinking` MCP before any non-trivial edit, debug, or architectural decision.

## Flutter Guidelines
- Use the `Flutter` agent skill for Flutter-specific best practices (state management, widget rebuilds, async patterns).
- Flutter/Dart project - never apply web/TS patterns unless adapting for a Flutter-specific use case.
- Test with `flutter test` before declaring work complete.
- Use `flutter analyze` for static analysis.

## Code Conventions
- Follow existing project patterns, naming, and architecture.
- No drive-by refactoring; touch only what the task requires.
- Keep diffs minimal and focused.

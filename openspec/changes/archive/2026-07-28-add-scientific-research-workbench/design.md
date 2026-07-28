# Add Scientific Research Workbench — Design

## Workbench Layout

The workbench lives under `scientific/`:

- `scientific/python/` for AI orchestration, tracing, and numerical analysis
- `scientific/julia/` for reproducible numerical verification
- `scientific/lisp/` for symbolic/NLP experiments
- `scientific/fixtures/` for cross-language sample inputs

This keeps scientific tooling isolated from the Flutter app while remaining versioned alongside it.

## Python Lane

Python should use a normal project file and lockfile so dependency resolution is explicit. The baseline stack is:

- DSPy
- LangChain
- LangSmith
- NumPy / SciPy / Pandas
- Pytest

The first concrete tool is an export validator CLI that loads a Breakdex JSON export and reports stable counts, missing-video references, and archive distribution. LangSmith support is environment-driven and optional.

## Julia Lane

Julia is the primary numerical verification lane. It should have its own `Project.toml` and a script that validates the same shared export fixture as the Python lane. The goal is parity on counts and a trusted non-Python numerical check.

## Lisp Lane

The Lisp lane is intentionally light for the first slice: a package definition, a smoke entry point, and a small symbolic rule example. This verifies the runtime and gives later NLP/symbolic work a committed home.

## Root Integration

Root `package.json` scripts should provide:

- Python sync/test
- Julia instantiate/smoke
- Lisp smoke
- One combined doctor/bootstrap lane

## Validation

Run:

- Python tests in the scientific workspace
- Julia smoke/fixture validation
- Lisp smoke script

This is a tooling/workbench change, so Flutter tests are unaffected.

# Add Scientific Research Workbench

## Summary

Add a repo-local scientific computing workbench so Breakdex can validate review logic, exported data, and future NLP/research workflows outside the Flutter runtime. The workbench should standardize Python, Julia, and Common Lisp entry points, with Julia available as the primary numerical verification lane and Python hosting DSPy, LangChain, and LangSmith.

## Motivation

The app currently has no stable research surface for deeper validation or cross-platform experimentation. That makes review-loop analysis, exported-data checks, and future AI/NLP work ad hoc and difficult to reproduce. A dedicated workbench provides one place to run numerical validation, trace AI experiments, and build symbolic tools without polluting the Flutter app itself.

## Scope

### In scope
- Repo-local `scientific/` directory with Python, Julia, and Lisp sub-workspaces
- Python environment standardized with DSPy, LangChain, LangSmith, and scientific packages
- Julia environment for numerical/export validation and reproducible `Project.toml`
- Common Lisp lane for symbolic/NLP experiments with a working smoke script
- Root scripts and docs so the workbench can be bootstrapped from the repo
- Cross-language sample export validation on a shared fixture

### Out of scope
- Bundling or automating MATLAB, which is not available on this machine
- Wiring the Flutter runtime directly to DSPy/LangChain/LangSmith
- Shipping production AI features from this workbench in the same change

## Capabilities

1. `scientific-python-lane` — reproducible Python research environment with DSPy, LangChain, LangSmith, and numerical tooling
2. `scientific-julia-lane` — Julia-first numerical verification over Breakdex export fixtures
3. `scientific-lisp-lane` — symbolic/NLP experimentation surface with a verified Lisp entry point
4. `scientific-bootstrap` — root scripts and documentation for repeatable setup

## Dependencies

- Local Python 3.12
- Local Julia 1.12.x
- Local SBCL / CLISP
- Existing JSON export model produced by Breakdex backup/export flows

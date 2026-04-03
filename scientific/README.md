# Scientific Workbench

This repo now includes a dedicated scientific computing and research workbench
separate from the Flutter app runtime.

## Layout

- `scientific/python/`
  Python research environment with DSPy, LangChain, LangSmith, and scientific
  analysis utilities.
- `scientific/julia/`
  Julia-first numerical verification lane.
- `scientific/lisp/`
  Common Lisp symbolic/NLP experiment lane.
- `scientific/fixtures/`
  Shared cross-language fixtures.

## Pinned Environments

- `scientific/python/uv.lock`
  Pinned Python dependencies for reproducible DSPy/LangChain/LangSmith runs.
- `scientific/julia/Manifest.toml`
  Pinned Julia dependency graph for numerical validation.

## Why This Exists

The Flutter app is the product runtime. This workbench is the analysis runtime.
Use it for:

- review-loop validation
- exported-data inspection
- AI tracing and research experiments
- symbolic/NLP prototyping

## Bootstrapping

From the repo root:

```bash
npm run science:python:sync
npm run science:python:test
npm run science:julia:instantiate
npm run science:julia:validate
npm run science:lisp:smoke
```

Or run the full lane:

```bash
npm run science:doctor
```

You can also work directly inside `scientific/python`, `scientific/julia`, or
`scientific/lisp` if you want each research lane to stay isolated.

## Environment Variables

Create your own local environment file and export keys before using the AI lane.
Expected keys include:

- `OPENAI_API_KEY`
- `LANGSMITH_API_KEY`
- `LANGSMITH_TRACING`
- `LANGSMITH_PROJECT`
- `NIM_API_KEY`

See [env.example](./env.example).

## Notes

- Julia is the verified numerical lane on this machine because Julia 1.12 is
  installed locally.
- MATLAB is intentionally out of scope for now because there is no local
  MATLAB runtime to standardize against.

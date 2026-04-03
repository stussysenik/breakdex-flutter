#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[science] python: $(python3 --version)"
echo "[science] julia: $(julia --version)"
echo "[science] sbcl: $(sbcl --version)"

(
  cd "$ROOT_DIR/scientific/python"
  uv sync
  uv run pytest
)

julia --project="$ROOT_DIR/scientific/julia" -e 'using Pkg; Pkg.instantiate()'
julia --project="$ROOT_DIR/scientific/julia" \
  "$ROOT_DIR/scientific/julia/scripts/validate_export.jl" \
  "$ROOT_DIR/scientific/fixtures/sample_export.json"

sbcl --script "$ROOT_DIR/scientific/lisp/smoke.lisp"

#!/usr/bin/env bash
# Fails if the committed gen-l10n output is stale relative to the ARB sources.
# Phase 5.1 gate: generated localizations (lib/l10n/gen) must be committed and current.
set -euo pipefail

flutter gen-l10n >/dev/null

if ! git diff --quiet -- lib/l10n/gen; then
  echo "❌ lib/l10n/gen is out of date. Run 'flutter gen-l10n' and commit the result:" >&2
  git --no-pager diff --stat -- lib/l10n/gen >&2
  exit 1
fi

echo "✅ lib/l10n/gen is up to date."

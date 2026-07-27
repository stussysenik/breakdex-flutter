#!/bin/bash
# verify.sh — cumulative binary-truth gate (CLAUDE.md §9).
#
#   ./verify.sh          # everything, including the full flutter test suite
#   ./verify.sh --quick  # skips flutter test (the slow gate) — pre-commit loop
#
# Every gate prints what it did not prove; the footer collects the rest.
set -u
cd "$(dirname "$0")" || exit 1

QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1

echo "========================================"
echo " Breakdex verify.sh — cumulative"
echo "========================================"
echo

PASS=1

# Ledger — runs first: a queue pointing at the wrong work is cheaper to find
# than a failing suite.
sh scripts/verify_ledger.sh || PASS=0
echo

# OpenSpec — the ACTIVE change validates strictly. The other open changes are
# not gated here (many are future work; see the footer).
ACTIVE=$(sed -n '/^## NOW/,/^## /p' ROADMAP.md \
  | grep -m1 -o '\*\*Change (active[^`]*`[a-z0-9-]*`' \
  | grep -o '`[a-z0-9-]*`' | tr -d '`')
OPENSPEC=$(command -v openspec || echo "$HOME/.npm-global/bin/openspec")
if [ -n "$ACTIVE" ] && [ -x "$OPENSPEC" ]; then
  echo "=== OpenSpec Gate (active change) ==="
  "$OPENSPEC" validate "$ACTIVE" --strict && echo "  ok    $ACTIVE --strict" \
    || { echo "  FAIL  $ACTIVE --strict"; PASS=0; }
  echo
fi

# Docs ledger — verified manual chapters vs their watched paths.
echo "=== Docs Ledger Gate ==="
node scripts/docs_ledger_check || PASS=0
echo

# L10n — committed gen-l10n output current with ARB sources.
echo "=== L10n Gate ==="
bash scripts/check_l10n.sh || PASS=0
echo

# Analyzer — errors and warnings fail; infos are reported, not gated
# (repo standard: "0 errors, pre-existing infos untouched").
echo "=== Analyzer Gate ==="
AOUT=$(flutter analyze 2>&1)
ERRS=$(printf '%s\n' "$AOUT" | grep -c '^ *error •')
WARNS=$(printf '%s\n' "$AOUT" | grep -c '^ *warning •')
INFOS=$(printf '%s\n' "$AOUT" | grep -c '^ *info •')
if [ "$ERRS" -eq 0 ] && [ "$WARNS" -eq 0 ]; then
  echo "  ok    flutter analyze: 0 errors, 0 warnings ($INFOS infos, not gated)"
else
  printf '%s\n' "$AOUT" | grep -E '^ *(error|warning) •'
  echo "  FAIL  flutter analyze: $ERRS error(s), $WARNS warning(s)"
  PASS=0
fi
echo

# Tests — the slow gate. Quarantined/stale tests are ledgered in
# docs/stale-tests-post-redesign.md, not silently skipped here.
if [ "$QUICK" -eq 0 ]; then
  echo "=== Test Gate ==="
  flutter test && echo "  ok    flutter test" || { echo "  FAIL  flutter test"; PASS=0; }
  echo
else
  echo "=== Test Gate — SKIPPED (--quick) ==="
  echo
fi

echo "========================================"
echo "NOT PROVEN by this run: device behavior (owner's dedicated session), the"
echo "  web build (flutter build web — CI gate), live Appwrite sync (Phase M"
echo "  runbook), the non-active openspec changes' strict validity, and that a"
echo "  ticked box matches shipped code semantically."
if [ "$PASS" -eq 1 ]; then
  [ "$QUICK" -eq 1 ] && echo "ALL GATES PASSED (quick — tests not run)" || echo "ALL GATES PASSED"
else
  echo "SOME GATES FAILED"
  exit 1
fi

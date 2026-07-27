#!/bin/sh
# verify_ledger.sh — the NOW-block ↔ tasks.md contract, gated.
#
# CLAUDE.md's ledger rule (tick in the same commit as the work; NOW names the
# one active change) was prose until now. A convention that is only written
# down is a convention that decays; this makes the drift exit non-zero.
#
# Prints what it did not prove. Run from anywhere; paths resolve to the root.
cd "$(dirname "$0")/.." || exit 1

FAIL=0
say() { printf '  FAIL  %s\n' "$1"; FAIL=1; }
ok()  { printf '  ok    %s\n' "$1"; }

echo "=== Ledger Gate ==="

# 1 — The NOW block exists and names exactly one active change.
ACTIVE=$(sed -n '/^## NOW/,/^## /p' ROADMAP.md \
  | grep -m1 -o '\*\*Change (active[^`]*`[a-z0-9-]*`' \
  | grep -o '`[a-z0-9-]*`' | tr -d '`')
if [ -z "$ACTIVE" ]; then
  say "ROADMAP.md NOW block names no active change (pattern: **Change (active…):** \`name\`)"
else
  ok "NOW names an active change: $ACTIVE"
fi

# 2 — The named change is real and has a ledger.
if [ -n "$ACTIVE" ]; then
  if [ ! -d "openspec/changes/$ACTIVE" ]; then
    say "active change directory missing: openspec/changes/$ACTIVE"
  elif [ ! -f "openspec/changes/$ACTIVE/tasks.md" ]; then
    say "active change has no tasks.md ledger"
  else
    ok "change directory and tasks.md exist"

    # 3 — A fully-ticked ledger under an unadvanced NOW block is drift:
    # the work is done but the queue head still points at it.
    OPEN=$(grep -c '^\- \[ \]' "openspec/changes/$ACTIVE/tasks.md" || true)
    DONE=$(grep -c '^\- \[x\]' "openspec/changes/$ACTIVE/tasks.md" || true)
    if [ "$OPEN" -eq 0 ]; then
      say "all $DONE tasks ticked but NOW still points here — advance the NOW block or archive the change"
    else
      ok "ledger live: $DONE ticked, $OPEN open"
    fi
  fi
fi

echo
echo "NOT PROVEN by this gate: that a ticked box matches shipped code semantically"
echo "  (the same-commit rule is enforced by review, not by this script), and the"
echo "  state of the other open changes' ledgers."
exit $FAIL

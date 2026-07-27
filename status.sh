#!/bin/sh
# status.sh — the derived board.
#
# The board is derived, never stored: the active change comes from ROADMAP.md's
# NOW block, task counts from that change's tasks.md, and the tree's state from
# git. A board written twice is a board that drifts — this one only reads.
cd "$(dirname "$0")" || exit 1

ACTIVE=$(sed -n '/^## NOW/,/^## /p' ROADMAP.md \
  | grep -m1 -o '\*\*Change (active[^`]*`[a-z0-9-]*`' \
  | grep -o '`[a-z0-9-]*`' | tr -d '`')
TASKS="openspec/changes/$ACTIVE/tasks.md"

echo "=== Breakdex board ==="
echo
echo "NOW:      ${ACTIVE:-<no active change parsed from ROADMAP.md>}"
if [ -f "$TASKS" ]; then
  DONE=$(grep -c '^\- \[x\]' "$TASKS" || true)
  OPEN=$(grep -c '^\- \[ \]' "$TASKS" || true)
  echo "TASKS:    $DONE done / $OPEN open"
  NEXT=$(grep -m1 '^\- \[ \]' "$TASKS" | cut -c7-96)
  [ -n "$NEXT" ] && echo "NEXT:     $NEXT" || echo "NEXT:     none open — advance the NOW block"
else
  [ -n "$ACTIVE" ] && echo "TASKS:    $TASKS MISSING"
fi
echo
BRANCH=$(git rev-parse --abbrev-ref HEAD)
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
AHEAD=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo '?')
echo "GIT:      $BRANCH — $DIRTY dirty file(s), $AHEAD unpushed commit(s)"
CHANGES=$(ls -d openspec/changes/*/ | grep -cv '/archive/')
echo "QUEUE:    $CHANGES open changes (order: ROADMAP.md D8 backlog)"
echo
echo "Gates: ./verify.sh (--quick skips flutter test). Board is read-only."

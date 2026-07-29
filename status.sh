#!/bin/sh
# status.sh — the derived board.
#
#   ./status.sh          # the head of the queue: active change, next task, git
#   ./status.sh --queue  # triage every open change: archive-ready / wip / stale / broken
#
# The board is derived, never stored: the active change comes from ROADMAP.md's
# NOW block, task counts from that change's tasks.md, and the tree's state from
# git. A board written twice is a board that drifts — this one only reads.
cd "$(dirname "$0")" || exit 1

ACTIVE=$(sed -n '/^## NOW/,/^## /p' ROADMAP.md \
  | grep -m1 -o '\*\*Change (active[^`]*`[a-z0-9-]*`' \
  | grep -o '`[a-z0-9-]*`' | tr -d '`')
TASKS="openspec/changes/$ACTIVE/tasks.md"

# --queue — triage the whole queue, not just its head. Every classification is
# derived: ticks from tasks.md, age from git, structure from `openspec validate`.
# The point is that a change cannot rot quietly: 39 open changes with no board
# is a backlog, and a backlog is where specs go to drift from shipped code.
if [ "${1:-}" = "--queue" ]; then
  OPENSPEC=$(command -v openspec || echo "$HOME/.npm-global/bin/openspec")
  NOW_EPOCH=$(date +%s)
  echo "=== Breakdex queue triage ==="
  echo
  printf '%-52s %-8s %-5s %s\n' "CHANGE" "TICKS" "AGE" "VERDICT"
  for dir in openspec/changes/*/; do
    id=$(basename "$dir")
    [ "$id" = "archive" ] && continue

    t="$dir/tasks.md"
    if [ -f "$t" ]; then
      d=$(grep -c '^ *- \[x\]' "$t" 2>/dev/null | tr -d ' \n'); d=${d:-0}
      o=$(grep -c '^ *- \[ \]' "$t" 2>/dev/null | tr -d ' \n'); o=${o:-0}
    else
      d=0; o=0
    fi
    total=$((d + o))

    # A change with no git history is NEW (just authored, not yet committed), not
    # ancient. Reading an absent timestamp as 999d reported brand-new work as the
    # stalest thing in the queue.
    last=$(git log -1 --format=%at -- "$dir" 2>/dev/null)
    days=$([ -n "$last" ] && echo $(((NOW_EPOCH - last) / 86400)) || echo 0)

    # `.triage` lets a decision persist instead of being re-asked every session:
    #   exempt          — never report as stale (owner-gated durable checklists)
    #   reviewed: DATE  — staleness counts from the review, not the last code touch
    triage_exempt=0
    if [ -f "$dir/.triage" ]; then
      grep -qi '^exempt' "$dir/.triage" && triage_exempt=1
      rv=$(sed -n 's/^reviewed: *\([0-9-]*\).*/\1/p' "$dir/.triage" | head -1)
      if [ -n "$rv" ]; then
        rt=$(date -j -f "%Y-%m-%d" "$rv" +%s 2>/dev/null || date -d "$rv" +%s 2>/dev/null)
        [ -n "$rt" ] && days=$(((NOW_EPOCH - rt) / 86400))
      fi
    fi

    # Structure first: a change that will not validate cannot be archived, and a
    # change with no tasks was never planned — both are louder than staleness.
    if [ ! -f "$dir/proposal.md" ]; then
      verdict="BROKEN    not an openspec change (no proposal.md)"
    elif [ "$total" -eq 0 ]; then
      verdict="BROKEN    no tasks.md — never planned into executable work"
    elif ! "$OPENSPEC" validate "$id" --strict >/dev/null 2>&1; then
      # All work done but the artifact will not validate: archiving is blocked on
      # repair, so say so rather than filing it with the merely-invalid.
      if [ "$o" -eq 0 ]; then
        verdict="ARCHIVE?  all ticked but fails --strict — repair, then archive"
      else
        # Does NOT block working the change — only archiving it. Repair on
        # activation (the standing rule), not in bulk.
        verdict="INVALID   old template; workable now, repair before archiving"
      fi
    elif [ "$id" = "$ACTIVE" ]; then
      verdict="ACTIVE    the NOW block points here"
    elif [ "$o" -eq 0 ]; then
      verdict="ARCHIVE   all tasks ticked — run openspec archive"
    elif [ "$triage_exempt" -eq 1 ]; then
      verdict="OWNER     owner-gated checklist — exempt from staleness by .triage"
    elif [ "$days" -gt 30 ]; then
      verdict="STALE     untouched ${days}d — confirm it is still wanted"
    elif [ "$d" -eq 0 ]; then
      verdict="QUEUED    not started"
    else
      verdict="WIP       in flight"
    fi
    printf '%-52s %3s/%-4s %-5s %s\n' "$id" "$d" "$total" "${days}d" "$verdict"
  done
  echo
  echo "Verdicts are structural, not semantic: a ticked box is not proof the code"
  echo "shipped, and STALE is a prompt to decide, never an instruction to delete."
  echo "A decision persists: write \`reviewed: YYYY-MM-DD\` (or \`exempt\`) into the"
  echo "change's .triage file and the board stops re-asking. Decide once."
  exit 0
fi

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

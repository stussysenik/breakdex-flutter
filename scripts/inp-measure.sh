#!/bin/bash
# INP Latency Measurement via FlowDeck Session
# Measures time-to-tree-change after tap interactions.
# Budget: 200ms for in-page transitions, 500ms for sheet presentations.
#
# Usage: bash scripts/inp-measure.sh [--udid <SIMULATOR_UDID>]
#
# Requires: flowdeck CLI installed and simulator booted with Breakdex.

set -euo pipefail

# ── Configuration ───────────────────────────────────────────────────

BUDGET_TRANSITION_MS=200
BUDGET_SHEET_MS=500
APP_BUNDLE="com.breakdex.breakdex"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
UDID=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --udid) UDID="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Auto-detect UDID if not provided
if [[ -z "$UDID" ]]; then
  UDID=$(flowdeck simulator list --booted --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
devices = data if isinstance(data, list) else data.get('devices', [])
if devices:
    print(devices[0].get('udid', devices[0].get('id', '')))
" 2>/dev/null || true)

  if [[ -z "$UDID" ]]; then
    echo -e "${RED}Error: No booted simulator found. Boot one first:${NC}"
    echo "  flowdeck simulator boot <UDID>"
    exit 1
  fi
  echo -e "${YELLOW}Auto-detected simulator: ${UDID}${NC}"
fi

# ── Helpers ─────────────────────────────────────────────────────────

RESULTS=()
FAILURES=0

# Get current time in milliseconds (macOS compatible)
now_ms() {
  python3 -c "import time; print(int(time.time() * 1000))"
}

# Get the mtime of latest-tree.json in ms
tree_mtime_ms() {
  local tree_path
  tree_path=$(flowdeck ui simulator session info --udid "$UDID" --json 2>/dev/null | \
    python3 -c "import sys, json; print(json.load(sys.stdin).get('treePath', ''))" 2>/dev/null || true)

  if [[ -z "$tree_path" || ! -f "$tree_path" ]]; then
    echo "0"
    return
  fi

  python3 -c "
import os, sys
stat = os.stat('$tree_path')
print(int(stat.st_mtime * 1000))
"
}

# Measure a single interaction: tap → wait for tree change → report delta
# Arguments: $1=label, $2=tap_target, $3=budget_ms, $4=tap_type (text|point|id)
measure_interaction() {
  local label="$1"
  local target="$2"
  local budget="$3"
  local tap_type="${4:-text}"

  local before_mtime
  before_mtime=$(tree_mtime_ms)

  local start
  start=$(now_ms)

  # Perform the tap
  case "$tap_type" in
    point)
      flowdeck ui simulator tap --udid "$UDID" --point "$target" >/dev/null 2>&1
      ;;
    id)
      flowdeck ui simulator tap --udid "$UDID" --id "$target" >/dev/null 2>&1
      ;;
    *)
      flowdeck ui simulator tap --udid "$UDID" --text "$target" >/dev/null 2>&1
      ;;
  esac

  # Poll for tree change (max 2 seconds)
  local elapsed=0
  local max_wait=2000
  while [[ $elapsed -lt $max_wait ]]; do
    local current_mtime
    current_mtime=$(tree_mtime_ms)
    if [[ "$current_mtime" != "$before_mtime" && "$current_mtime" != "0" ]]; then
      break
    fi
    sleep 0.02
    elapsed=$(( $(now_ms) - start ))
  done

  local delta=$(( $(now_ms) - start ))

  # Record result
  local status="PASS"
  if [[ $delta -gt $budget ]]; then
    status="FAIL"
    FAILURES=$((FAILURES + 1))
  fi

  RESULTS+=("{\"label\":\"$label\",\"delta_ms\":$delta,\"budget_ms\":$budget,\"status\":\"$status\"}")

  if [[ "$status" == "PASS" ]]; then
    echo -e "  ${GREEN}PASS${NC} ${label}: ${delta}ms (budget: ${budget}ms)"
  else
    echo -e "  ${RED}FAIL${NC} ${label}: ${delta}ms (budget: ${budget}ms)"
  fi
}

# ── Session Setup ───────────────────────────────────────────────────

echo ""
echo "INP Latency Measurement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Simulator: $UDID"
echo "App: $APP_BUNDLE"
echo ""

# Start FlowDeck UI session
echo "Starting FlowDeck session..."
flowdeck ui simulator session start --udid "$UDID" >/dev/null 2>&1 || true
sleep 1

# ── Measurements ────────────────────────────────────────────────────

echo ""
echo "Tab Switches"
echo "────────────────────────────────────────────────────────────"
measure_interaction "Arsenal → Review"   "146,809"  "$BUDGET_TRANSITION_MS"  "point"
sleep 0.3
measure_interaction "Review → Stats"     "245,809"  "$BUDGET_TRANSITION_MS"  "point"
sleep 0.3
measure_interaction "Stats → Settings"   "344,809"  "$BUDGET_TRANSITION_MS"  "point"
sleep 0.3
measure_interaction "Settings → Arsenal" "49,809"   "$BUDGET_TRANSITION_MS"  "point"
sleep 0.3

echo ""
echo "Segment Toggles"
echo "────────────────────────────────────────────────────────────"
measure_interaction "List → Gallery"     "Gallery"  "$BUDGET_TRANSITION_MS"  "text"
sleep 0.3
measure_interaction "Gallery → List"     "List"     "$BUDGET_TRANSITION_MS"  "text"
sleep 0.3
measure_interaction "Moves → Combos"     "Combos"   "$BUDGET_TRANSITION_MS"  "text"
sleep 0.3
measure_interaction "Combos → Moves"     "Moves"    "$BUDGET_TRANSITION_MS"  "text"
sleep 0.3

echo ""
echo "Sheet Presentations"
echo "────────────────────────────────────────────────────────────"
measure_interaction "FAB → Video Picker" "Add new move" "$BUDGET_SHEET_MS"  "id"

# ── Report ──────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Output JSON report
REPORT_DIR="e2e-screenshots"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/inp-report.json"

echo "[" > "$REPORT_FILE"
for i in "${!RESULTS[@]}"; do
  if [[ $i -gt 0 ]]; then
    echo "," >> "$REPORT_FILE"
  fi
  echo "  ${RESULTS[$i]}" >> "$REPORT_FILE"
done
echo "]" >> "$REPORT_FILE"

echo "Report written to: $REPORT_FILE"
echo ""

if [[ $FAILURES -gt 0 ]]; then
  echo -e "${RED}$FAILURES interaction(s) exceeded budget${NC}"
  exit 1
else
  echo -e "${GREEN}All interactions within budget${NC}"
  exit 0
fi

#!/usr/bin/env bash
# breakdex-flutter → engineering & design replacement-cost bill.
#
# What it answers: "If a client hired a senior Flutter + design team to build
# this from scratch today, what would it bill?" — i.e. the asset's replacement
# value, which is what 'makes it back'. NOT what was spent to build it (the
# actual build was AI-accelerated and cost far less).
#
# Everything measurable is computed live from the tree, so re-running re-syncs.
# The judgment calls (rate card, complexity weights, productivity) are the
# variables up top — change a number, re-run, get a new price. The script prints
# a Low / Base / High range by varying the two most uncertain inputs, so you see
# the sensitivity instead of one false-precision number.
#
# Usage:  ./scripts/bill.sh        # full bill
#         ./scripts/bill.sh --csv  # machine-readable, no prose

set -euo pipefail
cd "$(dirname "$0")/.."
[ -d .git ] || { echo "error: run from repo root"; exit 1; }

CSV=false
[[ "${1:-}" == "--csv" ]] && CSV=true

# =============================================================================
# RATE CARD — the judgment calls. Adjust to re-price.
# =============================================================================
RATE_BASE=200          # $/hr, senior Flutter+design hybrid, US staff contract
RATE_LOW=150
RATE_HIGH=250
HRS_PER_DAY=6          # realistic billable hrs/day (rest is design/review/docs)

# Complexity weights: effort multiplier at W=1.0. Hard logic costs more per LOC.
W_CORE=1.5     # db, sync, state machines, services, models, providers
W_FEATURE=1.0  # standard feature UI + logic
W_WIDGET=0.7   # design system, shared widgets (reusable, polished)
W_TEST=0.45    # tests — necessary, lower per-LOC effort
W_GEN=0        # generated code (l10n) — non-billable

# Productivity: effective shipped LOC / day at W=1.0 (senior, quality, incl.
# design+test+review). Varied for the Low/Base/High range.
PROD_LOW=400; PROD_BASE=300; PROD_HIGH=200   # optimistic → pessimistic

# =============================================================================
# MEASURE — live from the tree.
# =============================================================================
# Classify a lib subdirectory path into a weight bucket.
classify() {
  case "$1" in
    lib/core/database|lib/core/services|lib/core/sync|lib/core/state_machines|\
lib/core/models|lib/core/providers|lib/core/data|lib/core/platform|\
lib/core/config|lib/core/utils|lib/core/navigation|lib/core/domain|\
lib/core/web)                       echo CORE ;;
    lib/core/design|lib/shared)      echo WIDGET ;;
    lib/features|lib/dev)            echo FEATURE ;;
    lib/l10n/gen)                    echo GEN ;;
    *)                               echo OTHER ;;
  esac
}

measure_bucket() {
  local target="$1" n=0 loc=0 dir b
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    b=$(classify "$dir")
    [ "$b" = "$target" ] || continue
    local files; files=$(find "$dir" -maxdepth 10 -name '*.dart' 2>/dev/null)
    [ -z "$files" ] && continue
    n=$((n + $(printf '%s\n' "$files" | grep -c .)))
    loc=$((loc + $(printf '%s\n' "$files" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')))
  done < <(find lib -type d 2>/dev/null)
  echo "$n $loc"
}

read -r N_CORE LOC_CORE   <<< "$(measure_bucket CORE)"
read -r N_FEAT LOC_FEAT   <<< "$(measure_bucket FEATURE)"
read -r N_WLOC LOC_WIDGET <<< "$(measure_bucket WIDGET)"
read -r N_GEN LOC_GEN     <<< "$(measure_bucket GEN)"

# tests + l10n hand-written (l10n/gen is GEN; l10n/ root is hand-written)
N_TEST=$(find test -name '*.dart' 2>/dev/null | wc -l | tr -d ' ')
LOC_TEST=$(find test -name '*.dart' 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
N_L10N=$(find lib/l10n -maxdepth 1 -name '*.dart' 2>/dev/null | wc -l | tr -d ' ')
LOC_L10N=$(find lib/l10n -maxdepth 1 -name '*.dart' 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
LOC_CORE=${LOC_CORE:-0}; LOC_FEAT=${LOC_FEAT:-0}; LOC_WIDGET=${LOC_WIDGET:-0}
LOC_GEN=${LOC_GEN:-0}; LOC_TEST=${LOC_TEST:-0}; LOC_L10N=${LOC_L10N:-0}
LOC_LIB=$((LOC_CORE + LOC_FEAT + LOC_WIDGET + LOC_GEN + LOC_L10N))
LOC_TOTAL=$((LOC_LIB + LOC_TEST))
N_TOTAL=$((N_CORE + N_FEAT + N_WLOC + N_GEN + N_L10N + N_TEST))

# git timeline
COMMITS=$(git rev-list --count HEAD)
ACTIVE_DAYS=$(git log --format='%ad' --date=short 2>/dev/null | sort -u | wc -l | tr -d ' ')
# Capture git output into vars, then extract the first line via parameter
# expansion — avoids `git log | head` SIGPIPE under pipefail.
ALL_TS=$(git log --reverse --format='%at')
IFS= read -r FIRST_TS <<< "$ALL_TS" ; FIRST_TS=${FIRST_TS:-$(date +%s)}
SPAN_DAYS=$(( ($(date +%s) - FIRST_TS) / 86400 ))
# git log is reverse-chronological: first line of --reverse = oldest (FIRST),
# first line without --reverse = newest (LAST). read grabs just line 1.
ALL_DATES=$(git log --reverse --format='%as')
IFS= read -r FIRST <<< "$ALL_DATES"
ALL_DATES_LATE=$(git log --format='%as')
IFS= read -r LAST <<< "$ALL_DATES_LATE"
DOCS=$(find docs openspec -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

# =============================================================================
# PRICE — effort = weighted_LOC / productivity; cost = days × hrs × rate.
# =============================================================================
weighted_loc() {
  # shellcheck disable=SC2153
  awk "BEGIN{printf \"%d\", ($LOC_CORE*$W_CORE + $LOC_FEAT*$W_FEATURE + $LOC_WIDGET*$W_WIDGET + $LOC_TEST*$W_TEST + $LOC_L10N*$W_FEATURE)}"
}

bill() {
  local prod=$1 rate=$2
  local wloc; wloc=$(weighted_loc)
  local days; days=$(awk "BEGIN{printf \"%.0f\", $wloc/$prod}")
  [ "$days" -lt 1 ] && days=1
  local hrs=$((days * HRS_PER_DAY))
  local cost; cost=$(awk "BEGIN{printf \"%.0f\", $hrs*$rate}")
  echo "$wloc $days $hrs $cost"
}

read -r WL DAYS_L HRS_L COST_L <<< "$(bill $PROD_LOW  $RATE_LOW)"
read -r WB DAYS_B HRS_B COST_B <<< "$(bill $PROD_BASE $RATE_BASE)"
read -r WH DAYS_H HRS_H COST_H <<< "$(bill $PROD_HIGH $RATE_HIGH)"

fmt(){ awk "BEGIN{printf \"\$%'.0f\", $1}"; }

# =============================================================================
# OUTPUT
# =============================================================================
if $CSV; then
  echo "metric,value"
  echo "loc_core,$LOC_CORE"; echo "loc_feature,$LOC_FEAT"
  echo "loc_widget,$LOC_WIDGET"; echo "loc_test,$LOC_TEST"
  echo "loc_total,$LOC_TOTAL"; echo "files_total,$N_TOTAL"
  echo "commits,$COMMITS"; echo "active_days,$ACTIVE_DAYS"
  echo "span_days,$SPAN_DAYS"; echo "docs,$DOCS"
  echo "cost_low,$COST_L"; echo "cost_base,$COST_B"; echo "cost_high,$COST_H"
  exit 0
fi

cat <<EOF

  BREAKDEX FLUTTER — engineering & design replacement bill
  ─────────────────────────────────────────────────────────
  measured  $(date +%Y-%m-%d)          span $FIRST → $LAST ($SPAN_DAYS d, $ACTIVE_DAYS active)
  commits   $COMMITS          docs/specs $DOCS          files $N_TOTAL

  Lines of code
  ┌────────────────┬────────┬───────┐
  │ core (db/sync/ │ $(printf '%6d' $LOC_CORE) │ $(printf '%4d' $N_CORE) f │  ×$W_CORE
  │  svc/fsm/model)│        │       │
  │ features       │ $(printf '%6d' $LOC_FEAT) │ $(printf '%4d' $N_FEAT) f │  ×$W_FEATURE
  │ design/widgets │ $(printf '%6d' $LOC_WIDGET) │ $(printf '%4d' $N_WLOC) f │  ×$W_WIDGET
  │ tests          │ $(printf '%6d' $LOC_TEST) │ $(printf '%4d' $N_TEST) f │  ×$W_TEST
  │ l10n (hand)    │ $(printf '%6d' $LOC_L10N) │ $(printf '%4d' $N_L10N) f │
  │ l10n (gen)     │ $(printf '%6d' $LOC_GEN) │   gen │  non-billable
  ├────────────────┼────────┼───────┤
  │ lib total      │ $(printf '%6d' $LOC_LIB) │       │
  │ grand total    │ $(printf '%6d' $LOC_TOTAL) │       │
  └────────────────┴────────┴───────┘

  Replacement cost  (effort = weighted-LOC ÷ productivity × $/hr)
  ┌─────────┬────────┬────────┬────────┬─────────────┐
  │         │ $/hr   │ prod   │ days   │ bill        │
  ├─────────┼────────┼────────┼────────┼─────────────┤
  │ Low     │ $(printf '%5d' $RATE_LOW)  │ $(printf '%4d/d' $PROD_LOW)  │ $(printf '%5d' $DAYS_L) │  $(fmt $COST_L) │
  │ Base    │ $(printf '%5d' $RATE_BASE)  │ $(printf '%4d/d' $PROD_BASE)  │ $(printf '%5d' $DAYS_B) │  $(fmt $COST_B) │
  │ High    │ $(printf '%5d' $RATE_HIGH)  │ $(printf '%4d/d' $PROD_HIGH)  │ $(printf '%5d' $DAYS_H) │  $(fmt $COST_H) │
  └─────────┴────────┴────────┴────────┴─────────────┘
  weighted LOC $(printf '%6d' $WB)   (LOC adjusted for complexity)

  Sanity cross-checks
    $(awk "BEGIN{printf \"\$%.2f / weighted-LOC\", $COST_B/$WB}")          (blended rate)
    $(awk "BEGIN{printf \"%.0f shipped LOC/day effective\", $LOC_TOTAL/$DAYS_B}")    (implied throughput)
    $(awk "BEGIN{printf \"%.1f×\", $LOC_LIB/$LOC_TEST}")  lib:test ratio  (industry 1.5–4×)

EOF

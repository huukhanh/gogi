#!/usr/bin/env bash
# watch.sh <RUN_DIR> [MAX_SECONDS=540] [INTERVAL=60]
# Condition wait for the monitor role. Ticks every INTERVAL seconds (refreshes session stats, appends
# a heartbeat.log line) and exits early only when something is actionable, so one Bash call
# (timeout 600000, run_in_background) covers up to MAX_SECONDS of idle time with zero model turns.
#   GOGI_WATCH_MODE = build (default) | freeze | review
#     build:  exit on rotate flag, urgent comms entry (decision / report / status), or MAX_SECONDS
#     freeze: additionally exit when the tree is unchanged across one tick  -> reason=frozen
#     review: additionally exit when the tree changes                       -> reason=tree-moved
# Prints a report to stdout; state between calls lives in $RUN_DIR/.watch-state.
set -euo pipefail

RUN_DIR="${1:?usage: watch.sh <RUN_DIR> [MAX_SECONDS] [INTERVAL]}"
MAX="${2:-540}"; INTERVAL="${3:-60}"
MODE="${GOGI_WATCH_MODE:-build}"
HERE="$(cd "$(dirname "$0")" && pwd)"
STATE="$RUN_DIR/.watch-state"; HB="$RUN_DIR/heartbeat.log"; COMMS="$RUN_DIR/comms.md"
URGENT_RE='^### \[[0-9:]+\] .* \(kind: (decision \[(small|big)\]|report|status)\)'

mkdir -p "$RUN_DIR"; touch "$COMMS" "$HB"
tree_sig() { { git status --short; git diff --stat; } 2>/dev/null | shasum | cut -c1-12; }
comms_lines() { wc -l < "$COMMS" | tr -d ' '; }

TREE="$(tree_sig)"; LINES="$(comms_lines)"; ROTATE=""; TICKS=0
[ -f "$STATE" ] && . "$STATE"
BASE_LINES="$LINES"; BASE_TREE="$TREE"
START_TS="$(date +%s)"; START_HM="$(date +%H:%M)"
reason="timeout"; call_ticks=0

while :; do
  sleep "$INTERVAL"
  "$HERE/session-stats.sh" "$RUN_DIR" >/dev/null 2>&1 || true
  now_tree="$(tree_sig)"; now_lines="$(comms_lines)"
  rotate="$(jq -r '.rotate | join(",")' "$RUN_DIR/session.json" 2>/dev/null || echo "")"
  total="$(jq -r '.totals.total_input_tokens // 0' "$RUN_DIR/session.json" 2>/dev/null || echo 0)"
  TICKS=$((TICKS + 1)); call_ticks=$((call_ticks + 1))
  printf '%s tick=%s mode=%s tokens=%s rotate=%s tree=%s comms=%s\n' \
    "$(date +%H:%M)" "$TICKS" "$MODE" "$total" "${rotate:-none}" "$now_tree" "$now_lines" >> "$HB"

  if [ -n "$rotate" ] && [ "$rotate" != "$ROTATE" ]; then reason="rotate"; break; fi
  if [ "$now_lines" -gt "$LINES" ] && tail -n +"$((LINES + 1))" "$COMMS" | grep -Eq "$URGENT_RE"; then reason="comms"; break; fi
  case "$MODE" in
    freeze) [ "$now_tree" = "$TREE" ] && { reason="frozen"; break; } ;;
    review) [ "$now_tree" != "$TREE" ] && { reason="tree-moved"; break; } ;;
  esac
  TREE="$now_tree"
  if [ $(( $(date +%s) - START_TS + INTERVAL )) -gt "$MAX" ]; then break; fi
done

printf 'TREE=%q\nLINES=%q\nROTATE=%q\nTICKS=%q\n' "$now_tree" "$now_lines" "$rotate" "$TICKS" > "$STATE"

status_lines="$(git status --short 2>/dev/null | wc -l | tr -d ' ')"
out_tokens="$(jq -r '.totals.output_tokens // 0' "$RUN_DIR/session.json" 2>/dev/null || echo 0)"
echo "reason: $reason"
echo "mode: $MODE · window: ${START_HM}–$(date +%H:%M) · ticks this call: $call_ticks · total ticks: $TICKS"
echo "tree: $([ "$now_tree" = "$BASE_TREE" ] && echo unchanged || echo changed) · $status_lines paths in git status"
echo "tokens: total input $total · output $out_tokens"
echo "rotate: ${rotate:-none}"
jq -r '.agents[] | "  \(.agent): \(.turns) turns · ctx \(.context_tokens)\(if .rotate then " ⚠" else "" end)"' "$RUN_DIR/session.json" 2>/dev/null || true
new=$((now_lines - BASE_LINES))
if [ "$new" -gt 0 ]; then
  echo "new comms entries ($new lines, from comms.md:$((BASE_LINES + 1))):"
  tail -n +"$((BASE_LINES + 1))" "$COMMS" | head -n 120
  [ "$new" -gt 120 ] && echo "  … truncated; read comms.md from line $((BASE_LINES + 121))"
else
  echo "new comms entries: none"
fi

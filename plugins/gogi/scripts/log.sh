#!/usr/bin/env bash
# Stamps the current wall clock, never a composition time, so comms.md stays chronological.
#   echo "memo §7 updated: per-stage log line" | log.sh "$RUN" techlead dev,po answer
set -euo pipefail

RUN_DIR="${1:?usage: log.sh <RUN_DIR> <sender> <recipient[,recipient]> <kind> [< body]}"
SENDER="${2:?sender}"; RECIPIENT="${3:?recipient}"; KIND="${4:?kind}"

ROLE_RE='^((coordinator|scout|monitor|dev|techlead|po|investigator)(-[0-9]+)*|user|all)$'
KIND_RE='^(brief|memo|consult|answer|decision \[(small|big)\]|question-relay|review|report|status)$'

[[ "$SENDER" =~ $ROLE_RE ]] || { echo "log.sh: unknown sender '$SENDER' (coordinator|scout|monitor|dev|techlead|po|investigator-N|user, optional -N generation suffix)" >&2; exit 2; }
IFS=',' read -ra RCPTS <<< "$RECIPIENT"
for r in "${RCPTS[@]}"; do
  [[ "$r" =~ $ROLE_RE ]] || { echo "log.sh: unknown recipient '$r'" >&2; exit 2; }
done
[[ "$KIND" =~ $KIND_RE ]] || { echo "log.sh: unknown kind '$KIND' (brief|memo|consult|answer|decision [small]|decision [big]|question-relay|review|report|status)" >&2; exit 2; }

BODY="$(cat)"
[ -n "$BODY" ] || { echo "log.sh: empty body" >&2; exit 2; }

mkdir -p "$RUN_DIR"
{
  printf '\n### [%s] %s → %s (kind: %s)\n' "$(date +%H:%M)" "$SENDER" "$RECIPIENT" "$KIND"
  printf '%s\n' "$BODY"
} >> "$RUN_DIR/comms.md"
